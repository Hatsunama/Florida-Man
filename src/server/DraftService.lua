--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Items = require(Shared:WaitForChild("Items"))
local Stages = require(Shared:WaitForChild("Stages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))
local Rules = require(script.Parent:WaitForChild("ItemGrantRules"))
local DraftService = {}
local deps: any = nil
local completed: {[Player]: any} = {}
function DraftService.Init(d: any) deps = d end

local function display(id: string): any
	local item = Items.Get(id)
	if not item then return nil end
	return {id = item.id, name = item.name, description = item.description, rarity = item.rarity,
		inscription = item.inscription, statText = item.statText}
end

function DraftService.GetOffer(player: Player): any
	local s = RunContext.GetState(player)
	if not s or not s.pendingOffer or s.pendingOffer.consumed then return nil end
	local offer = s.pendingOffer
	local owned = {}
	for _, id in s.items do table.insert(owned, display(id)) end
	return {offerId = offer.offerId, generation = offer.generation, picks = offer.picks,
		items = owned, itemSlots = s.itemSlots, full = #s.items >= s.itemSlots}
end

function DraftService.ResendOffer(player: Player)
	local payload = DraftService.GetOffer(player)
	if payload then Remotes.Get("ShowDraft"):FireClient(player, payload) end
end

local function respond(player: Player, accepted: boolean, reason: string, offerId: any)
	Remotes.Get("CommandResult"):FireClient(player, {command = "PickDraftItem", accepted = accepted, reason = reason, offerId = offerId})
end

local function advance(player: Player)
	local s = RunContext.GetState(player)
	if not s then return end
	local stage = Stages.Get(s.stageId)
	local nextStage = stage and Stages.NextAfter(stage.id)
	if nextStage then deps.StageFlow.LoadStage(player, nextStage.id) else deps.StageFlow.FinishRun(player) end
end

function DraftService.BeginOffer(player: Player)
	local s = RunContext.GetState(player)
	if not s or s.runActive or s.phase ~= "Reward" then return end
	if s.pendingOffer then DraftService.ResendOffer(player); return end
	s.offerSequence = (s.offerSequence or 0) + 1
	local picks = Items.RollDraft(RunContext.GetRng(), s.luck + Balance.DailyLuckBonus(), Constants.DRAFT_CHOICES, s.items)
	local shown, allowed, owned = {}, {}, {}
	for _, item in picks do table.insert(shown, display(item.id)); allowed[item.id] = true end
	for _, id in s.items do table.insert(owned, display(id)) end
	s.pendingOffer = {
		offerId = tostring(s.sessionId) .. ":" .. tostring(s.generation) .. ":" .. tostring(s.offerSequence),
		generation = s.generation, allowed = allowed, picks = shown, consumed = false,
		items = owned, itemSlots = s.itemSlots, full = #s.items >= s.itemSlots,
	}
	s.awaitingDraft = true
	FunnelService.Mark(player, "draft_open", {stage = s.stageId})
	DraftService.ResendOffer(player)
	RunContext.PushState(player)
end

function DraftService.ContinueFromNewspaper(player: Player)
	local s = RunContext.GetState(player)
	if not s or not s.awaitingNewspaper or s.phase ~= "Reward" then return end
	s.awaitingNewspaper = false
	s.pendingNewspaper = nil
	DraftService.BeginOffer(player)
end

function DraftService.PickDraftItem(player: Player, payload: any)
	local s = RunContext.GetState(player)
	local offerId = if type(payload) == "table" then payload.offerId else nil
	local previous = completed[player]
	if previous and previous.offerId == offerId and type(payload) == "table" and payload.generation == previous.generation then
		respond(player, true, "Reward already resolved.", offerId)
		return
	end
	if not s or not s.awaitingDraft or s.phase ~= "Reward" then
		respond(player, false, "There is no open reward.", offerId); return
	end
	local offer = s.pendingOffer
	if not offer then respond(player, false, "There is no open reward.", offerId); return end
	local valid, reason = Rules.ValidateOffer(offer, s.generation, payload)
	if not valid then respond(player, false, reason, offerId); DraftService.ResendOffer(player); return end
	if payload.skip ~= true then
		local proposed, invalid = Rules.Grant(s.items, s.itemSlots, payload.itemId, payload.replaceIndex, Items.Get)
		if not proposed then respond(player, false, invalid, offerId); return end
	end
	-- Consume before the non-yielding grant and transition; replay never grants again.
	offer.consumed = true
	if payload.skip ~= true then
		local granted, invalid = RunContext.TryGrantItem(player, payload.itemId, payload.replaceIndex)
		if not granted then offer.consumed = false; respond(player, false, invalid or "Reward could not be applied.", offerId); return end
	end
	completed[player] = {offerId = offerId, generation = s.generation}
	s.pendingOffer = nil; s.awaitingDraft = false
	FunnelService.Mark(player, "draft_pick", {item = if payload.skip == true then "skip" else payload.itemId})
	respond(player, true, reason, offerId)
	RunContext.PushState(player)
	advance(player)
end

Players.PlayerRemoving:Connect(function(player) completed[player] = nil end)
return DraftService
