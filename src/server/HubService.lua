--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Personas = require(Shared:WaitForChild("Personas"))
local Stages = require(Shared:WaitForChild("Stages"))
local Balance = require(Shared:WaitForChild("Balance"))
local Story = require(Shared:WaitForChild("Story"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))
local MetaService = require(script.Parent:WaitForChild("MetaService"))
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))
local Rules = require(script.Parent:WaitForChild("ItemGrantRules"))
local HubService = {}
local deps: any = nil
local journals: {[Player]: any} = {}
function HubService.Init(d: any) deps = d end

function HubService.StartRun(player: Player)
	local old = RunContext.GetState(player)
	if not old or not old.inHub or old.runActive or old.phase ~= "Hub" then return end
	old.inHub = false; old.runActive = true -- consume the transition before replacement
	local s = RunContext.NewRunState(old.deaths)
	local target: any = s
	for _, key in {"unlockedPersonas", "personaRarity", "sunburn", "unlockedWeapons", "weaponId", "personas", "totalTurtlesRescued", "clientReady", "characterReady", "offerSequence"} do
		if (old :: any)[key] ~= nil then
			local value = (old :: any)[key]
			target[key] = if type(value) == "table" then table.clone(value) else value
		end
	end
	s.itemSlots = Constants.STARTING_ITEM_SLOTS
	s.activePersona = 1
	RunContext.SetState(player, s)
	RunContext.ComputeStats(s); s.hp = s.maxHp
	FunnelService.Mark(player, "hub_start", {stage = "DaytonaHangover"})
	deps.StageFlow.LoadStage(player, "DaytonaHangover")
	RunContext.Say(player, "The crabs stole your Cold One. Follow the beach and find out why they are wearing radio collars.", "Captain Steve", "run-start")
end

function HubService.TalkCaptainSteve(player: Player)
	local s = RunContext.GetState(player)
	if not s then return end
	local st = Stages.Get(s.stageId)
	local act = if st and st.steveAct then st.steveAct else math.clamp(Balance.ActNumber(s.stageIndex), 1, 5)
	local line = Story.SteveLine(act, s.deaths)
	if s.pendingSteveEvent then
		line = Story.SteveEventLine(s.pendingSteveEvent) or line
		s.steveEvents[s.pendingSteveEvent] = true; s.pendingSteveEvent = nil
	elseif act == 1 and s.steveEvents.coldOne and not s.steveEvents.afterColdOneHubSaid then
		line = Story.SteveEventLine("afterColdOneHub") or line; s.steveEvents.afterColdOneHubSaid = true
	elseif act == 1 and s.steveEvents.collarHint and not s.steveEvents.collarHintSaid then
		line = Story.SteveEventLine("collarHint") or line; s.steveEvents.collarHintSaid = true
	end
	RunContext.Say(player, line, "Captain Steve", "steve-interact")
	RunContext.PushState(player)
end

function HubService.GetShopState(player: Player): {any}
	local s = RunContext.GetState(player)
	if not s then return {} end
	local out = {}
	local writable = MetaService.IsWritable(player)
	for _, def in Personas.List do
		local rarity = s.personaRarity[def.id] or "Common"
		local slots = {}
		for slot, id in s.personas do if id == def.id then table.insert(slots, slot) end end
		local owned = s.unlockedPersonas[def.id] == true
		local cost = Rules.UPGRADE_COST[rarity]
		local index = table.find(Rules.RARITIES, rarity) or 1
		local nextRarity = Rules.RARITIES[index + 1]
		table.insert(out, {
			id = def.id, name = def.name, description = def.description, unlockHint = def.unlockHint,
			rarity = rarity, owned = owned, slots = slots, upgradeCost = cost,
			refund = Rules.SMASH_REFUND[rarity] or 0,
			canEquip = s.inHub and s.phase == "Hub" and owned,
			nextRarity = nextRarity,
			nextDamageBonusPercent = if nextRarity then math.floor((Balance.RarityMult(nextRarity) - 1) * 100 + 0.5) else nil,
			nextSkillCooldownReductionPercent = if nextRarity then math.floor((1 - Balance.SkillCooldownMult(nextRarity)) * 100 + 0.5) else nil,
			canUpgrade = writable and s.inHub and owned and cost ~= nil and s.sunburn >= cost,
			canSmash = writable and s.inHub and owned and def.id ~= "BeachBurnout" and #slots == 0,
		})
	end
	return out
end

function HubService.GetCommandSequence(player: Player): number
	local journal = journals[player]
	return if journal then journal.lastSequence else 0
end

local function transact(player: Player, action: string, payload: any)
	local journal = journals[player]
	if not journal then journal = Rules.NewJournal(); journals[player] = journal end
	local fresh, cached, errorReason = Rules.CheckCommand(journal, action, payload)
	if not fresh then
		Remotes.Get("CommandResult"):FireClient(player, cached or {
			command = action, accepted = false, reason = errorReason,
			requestId = if type(payload) == "table" then payload.requestId else nil,
		})
		return
	end
	local s = RunContext.GetState(player)
	local patch, reason = nil, "Profile is not ready."
	if s then
		if action ~= "EquipPersona" and not MetaService.IsWritable(player) then
			reason = "Cloud progress is unavailable. Shop purchases are paused for this session."
		else
			patch, reason = Rules.HubTransaction(s, action, payload, Personas.Get)
		end
	end
	local result = {command = action, accepted = patch ~= nil, reason = reason, requestId = payload.requestId, sequence = payload.sequence}
	Rules.RememberCommand(journal, result)
	if patch and s then
		for key, value in patch do (s :: any)[key] = value end
		RunContext.ComputeStats(s)
		RunContext.ApplyCharacterSpeed(player)
		RunContext.PersistMeta(player, s)
	end
	Remotes.Get("CommandResult"):FireClient(player, result)
	RunContext.PushState(player)
end

function HubService.EquipPersona(player: Player, payload: any) transact(player, "EquipPersona", payload) end
function HubService.SmashPersona(player: Player, payload: any) transact(player, "SmashPersona", payload) end
function HubService.UpgradePersona(player: Player, payload: any) transact(player, "UpgradePersona", payload) end
Players.PlayerRemoving:Connect(function(player) journals[player] = nil end)
return HubService
