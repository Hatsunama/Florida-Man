--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Items = require(Shared:WaitForChild("Items"))
local Stages = require(Shared:WaitForChild("Stages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))

local RunContext = require(script.Parent:WaitForChild("RunContext"))

local DraftService = {}

local deps: any = nil

function DraftService.Init(d: any)
	deps = d
end

local function advanceAfterDraft(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	local stage = Stages.Get(s.stageId)
	local nextStage = stage and Stages.NextAfter(stage.id)
	RunContext.PushState(player)
	if nextStage then
		deps.StageFlow.LoadStage(player, nextStage.id)
	else
		deps.StageFlow.FinishRun(player)
	end
end

-- N0.2: when itemSlots saturated, skip draft UI and continue
local function beginDraftOrSkip(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	if #s.items >= s.itemSlots then
		RunContext.Toast(player, "Item slots full — draft skipped")
		s.awaitingDraft = false
		advanceAfterDraft(player)
		return
	end
	s.awaitingDraft = true
	local dailyLuck = Balance.DailyLuckBonus()
	local picks = Items.RollDraft(RunContext.GetRng(), s.luck + dailyLuck, Constants.DRAFT_CHOICES)
	if math.abs(dailyLuck) >= 0.01 then
		local pct = math.floor(dailyLuck * 100 + (if dailyLuck >= 0 then 0.5 else -0.5))
		RunContext.Toast(player, string.format("Florida Forecast: %+d%% draft luck today", pct))
	end
	local payload = {}
	for _, it in picks do
		table.insert(payload, {
			id = it.id,
			name = it.name,
			description = it.description,
			rarity = it.rarity,
			inscription = it.inscription,
			statText = it.statText,
		})
	end
	Remotes.Get("ShowDraft"):FireClient(player, payload)
	RunContext.PushState(player)
end

function DraftService.ContinueFromNewspaper(player: Player)
	local s = RunContext.GetState(player)
	if not s or not s.awaitingNewspaper then
		return
	end
	s.awaitingNewspaper = false
	local stage = Stages.Get(s.stageId)
	local nextStage = stage and Stages.NextAfter(stage.id)
	if not nextStage then
		deps.StageFlow.FinishRun(player)
		return
	end
	beginDraftOrSkip(player)
end

function DraftService.PickDraftItem(player: Player, itemId: unknown)
	local s = RunContext.GetState(player)
	if not s or not s.awaitingDraft or typeof(itemId) ~= "string" then
		return
	end
	if not Items.Get(itemId) then
		return
	end
	if #s.items >= s.itemSlots then
		RunContext.Toast(player, "Item slots full — draft skipped")
	else
		table.insert(s.items, itemId)
		local it = Items.Get(itemId)
		if it and it.healOnPickup > 0 then
			s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
		end
		RunContext.ComputeStats(s)
	end
	s.awaitingDraft = false
	advanceAfterDraft(player)
end

return DraftService
