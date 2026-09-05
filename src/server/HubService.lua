--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Personas = require(Shared:WaitForChild("Personas"))
local Stages = require(Shared:WaitForChild("Stages"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Story = require(Shared:WaitForChild("Story"))

local RunContext = require(script.Parent:WaitForChild("RunContext"))
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))

local HubService = {}

local deps: any = nil

function HubService.Init(d: any)
	deps = d
end

function HubService.StartRun(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	if not s.inHub or s.runActive then
		return
	end
	s.inHub = false
	s.runActive = true

	local deaths = s.deaths
	local unlocked = s.unlockedPersonas
	local rarities = s.personaRarity
	local sunburn = s.sunburn
	local unlockedW = s.unlockedWeapons
	local itemSlots = if deaths > 0 then Constants.ITEM_SLOTS_AFTER_FIRST_DEATH else Constants.STARTING_ITEM_SLOTS
	RunContext.SetState(player, RunContext.NewRunState(deaths))
	s = RunContext.GetState(player) :: RunContext.RunState
	s.unlockedPersonas = unlocked
	s.personaRarity = rarities
	s.sunburn = sunburn
	s.unlockedWeapons = unlockedW or { BareHands = true, FlipFlopSlap = true }
	s.weaponId = Constants.STARTING_WEAPON
	s.itemSlots = itemSlots
	s.unlockedPersonas.BeachBurnout = true
	s.personas = { "BeachBurnout" }

	for id in unlocked do
		if id ~= "BeachBurnout" and #s.personas < 2 then
			table.insert(s.personas, id)
			break
		end
	end
	RunContext.ComputeStats(s)
	s.hp = s.maxHp
	FunnelService.Mark(player, "hub_start", { stage = "DaytonaHangover" })
	deps.StageFlow.LoadStage(player, "DaytonaHangover")
	RunContext.Toast(player, "You wake after the last honest night of your life. The crabs stole your Cold One.")
end

function HubService.TalkCaptainSteve(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	local act = 1
	local st = Stages.Get(s.stageId)
	if st and st.steveAct then
		act = st.steveAct
	elseif s.deaths > 0 then
		act = math.clamp(Balance.ActNumber(s.stageIndex), 1, 5)
	end

	local line: string
	if s.pendingSteveEvent then
		line = Story.SteveEventLine(s.pendingSteveEvent) or Story.SteveLine(act, s.deaths)
		s.steveEvents[s.pendingSteveEvent] = true
		s.pendingSteveEvent = nil
	elseif act == 1 and s.steveEvents["coldOne"] and not s.steveEvents["afterColdOneHubSaid"] then
		line = Story.SteveEventLine("afterColdOneHub") or Story.SteveLine(act, s.deaths)
		s.steveEvents["afterColdOneHubSaid"] = true
	elseif act == 1 and s.steveEvents["collarHint"] and not s.steveEvents["collarHintSaid"] then
		line = Story.SteveEventLine("collarHint") or Story.SteveLine(act, s.deaths)
		s.steveEvents["collarHintSaid"] = true
	else
		line = Story.SteveLine(act, s.deaths)
	end
	RunContext.Toast(player, "Captain Steve: " .. line)
	Remotes.Get("ShowTagline"):FireClient(player, line, "Captain Steve")
	RunContext.PushState(player)
end

function HubService.SmashPersona(player: Player, personaId: unknown)
	local s = RunContext.GetState(player)
	if not s or typeof(personaId) ~= "string" then
		return
	end
	if personaId == "BeachBurnout" then
		RunContext.Toast(player, "Can't smash your starter Beach Burnout.")
		return
	end
	if not s.unlockedPersonas[personaId] then
		return
	end

	local equipped = false
	for _, id in s.personas do
		if id == personaId then
			equipped = true
		end
	end
	if equipped then
		RunContext.Toast(player, "Unequip/swap off that persona first (keep it off active slots).")
		local newSlots = {}
		for _, id in s.personas do
			if id ~= personaId then
				table.insert(newSlots, id)
			end
		end
		if #newSlots == 0 then
			newSlots = { "BeachBurnout" }
		end
		s.personas = newSlots
		s.activePersona = 1
	end
	local rarity = s.personaRarity[personaId] or "Common"
	local gain = Constants.SUNBURN_PER_COMMON
	if rarity == "Rare" then
		gain = Constants.SUNBURN_PER_RARE
	elseif rarity == "Unique" then
		gain = Constants.SUNBURN_PER_UNIQUE
	elseif rarity == "Legendary" then
		gain = Constants.SUNBURN_PER_LEGENDARY
	end
	s.sunburn += gain
	s.unlockedPersonas[personaId] = nil
	s.personaRarity[personaId] = nil
	RunContext.Toast(player, "Smashed for " .. gain .. " Sunburn ☀️")
	RunContext.PushState(player)
end

function HubService.UpgradePersona(player: Player, personaId: unknown)
	local s = RunContext.GetState(player)
	if not s or typeof(personaId) ~= "string" then
		return
	end
	if not s.unlockedPersonas[personaId] then
		return
	end
	local order = { "Common", "Rare", "Unique", "Legendary" }
	local rarity = s.personaRarity[personaId] or "Common"
	local idx = table.find(order, rarity) or 1
	if idx >= #order then
		RunContext.Toast(player, "Already Legendary!")
		return
	end
	local costs = { Common = 20, Rare = 45, Unique = 90 }
	local cost = costs[rarity] or 20
	if s.sunburn < cost then
		RunContext.Toast(player, "Need " .. cost .. " Sunburn (have " .. s.sunburn .. ")")
		return
	end
	s.sunburn -= cost
	s.personaRarity[personaId] = order[idx + 1]
	local pdef = Personas.Get(personaId)
	RunContext.Toast(player, (if pdef then pdef.name else personaId) .. " → " .. s.personaRarity[personaId])
	RunContext.PushState(player)
end

return HubService
