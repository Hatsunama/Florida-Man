--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Personas = require(Shared:WaitForChild("Personas"))
local Items = require(Shared:WaitForChild("Items"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Types = require(Shared:WaitForChild("Types"))
local Settings = require(Shared:WaitForChild("Settings"))
local Stages = require(Shared:WaitForChild("Stages"))

local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local MetaService = require(script.Parent:WaitForChild("MetaService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local SessionService = require(script.Parent:WaitForChild("SessionService"))
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))

local RunStats = require(script.Parent:WaitForChild('RunStats'))
local CharacterStatePublisher = require(script.Parent:WaitForChild('CharacterStatePublisher'))
local ItemGrantRules = require(script.Parent:WaitForChild('ItemGrantRules'))
local ProgressionRules = require(Shared:WaitForChild('ProgressionRules'))
local RunContext = {}

export type RunState = Types.RunState

local states: { [Player]: RunState } = {}
local rng = Random.new()
local shopProvider: ((Player) -> {any})? = nil
local shopSequenceProvider: ((Player) -> number)? = nil

function RunContext.SetShopProvider(provider: (Player) -> {any}, sequenceProvider: (Player) -> number)
	shopProvider = provider
	shopSequenceProvider = sequenceProvider
end

function RunContext.GetRng(): Random
	return rng
end

function RunContext.GetState(player: Player): RunState?
	return states[player]
end

function RunContext.SetState(player: Player, s: RunState)
	s.sessionId, s.generation = SessionService.GetIdentity(player)
	states[player] = s
end

function RunContext.ClearState(player: Player)
	states[player] = nil
end

function RunContext.PersistMeta(player: Player, s: RunState)
	MetaService.CaptureFromRun(player, s.deaths, s.sunburn, s.unlockedPersonas, s.stageIndex, {
		personaRarity = s.personaRarity, personas = s.personas,
		unlockedWeapons = s.unlockedWeapons, weaponId = s.weaponId,
		totalTurtlesRescued = s.totalTurtlesRescued,
	})
	MetaService.Save(player)
end

function RunContext.BeginPhase(player: Player, phase: string)
	local s = states[player]
	if not s then return end
	s.generation = SessionService.Advance(player)
	player:SetAttribute('SessionGeneration',s.generation)
	s.phase = phase
	s.pendingOffer = nil
	s.pendingNewspaper = nil
	s.pendingCredits = nil
	s.pendingDialogue = {}
	s.awaitingDraft = false
	s.awaitingNewspaper = false
	CombatService.ResetPlayer(player)
	local char = player.Character
	if char then
		char:SetAttribute('ExternalVelocityX', 0)
		char:SetAttribute('ExternalVelocityY', 0)
		char:SetAttribute('ExternalMotionUntil', 0)
		char:SetAttribute('SessionGeneration', s.generation)
	end
end

function RunContext.Say(player: Player, text: string, speaker: string?, id: string?)
	local s = states[player]
	if not s then return end
	local beat = {text = text, speaker = speaker or 'Captain Steve', id = id, generation = s.generation, scope = 'run', essential = true, priority = 10}
	if s.clientReady then
		Remotes.Get('ShowTagline'):FireClient(player, beat)
	else
		if #s.pendingDialogue >= 16 then table.remove(s.pendingDialogue, 1) end
		table.insert(s.pendingDialogue, beat)
	end
end

function RunContext.PushState(player: Player)
	local s = states[player]
	if not s then
		return
	end
	s.stateVersion += 1
	local stage = Stages.Get(s.stageId)
	player:SetAttribute('RunActive', s.runActive and s.phase == 'Active')
	Remotes.Get("StateUpdate"):FireClient(player, {
		sessionId = s.sessionId,
		generation = s.generation,
		stateVersion = s.stateVersion,
		phase = s.phase,
		characterReady = s.characterReady,
		boss = s.bossState,
		profileStatus = MetaService.GetStatus(player),
		settings = Settings.Snapshot(player),
		shop = if s.inHub and shopProvider then shopProvider(player) else {},
		shopSequence = if shopSequenceProvider then shopSequenceProvider(player) else 0,
		pendingOffer = s.pendingOffer,
		allowedActions = {combat = s.runActive and s.hp > 0 and s.phase == 'Active', interact = s.phase == 'Hub' or s.phase == 'Active'},
		stageId = s.stageId,
		stageIndex = s.stageIndex,
		hp = s.hp,
		maxHp = s.maxHp,
		personas = s.personas,
		activePersona = s.activePersona,
		unlockedPersonas = s.unlockedPersonas,
		personaRarity = s.personaRarity,
		items = s.items,
		itemSlots = s.itemSlots,
		sunburn = s.sunburn,
		luck = s.luck,
		deaths = s.deaths,
		turtlesRescued = s.turtlesRescued,
		turtlesNeeded = s.turtlesNeeded,
		coldOneRequired = stage ~= nil and stage.coldOnePickup == true,
		coldOneTaken = s.coldOneTaken,
		runTurtlesRescued = s.runTurtlesRescued,
		totalTurtlesRescued = s.totalTurtlesRescued,
		hangoverUntil = s.hangoverUntil,
		inHub = s.inHub,
		runActive = s.runActive,
		skillReadyAt = s.skillReadyAt,
		swapReadyAt = s.swapReadyAt,
		dodgeReadyAt = s.dodgeReadyAt,
		attackReadyAt = CombatService.GetAttackReadyAt(player),
		cancelOpenAt = CombatService.GetCancelOpenAt(player),
		serverNow = os.clock(),
		awaitingDraft = s.awaitingDraft,
		awaitingNewspaper = s.awaitingNewspaper,
		bossDefeated = s.bossDefeated,
		weaponId = s.weaponId,
		unlockedWeapons = s.unlockedWeapons,
		moveSpeed = s.moveSpeed,
		hangoverActive = os.clock() < s.hangoverUntil,
		actName = Balance.TierName(s.stageIndex),
		actNumber = Balance.ActNumber(s.stageIndex),
	})
end

function RunContext.Toast(player: Player, text: string)
	Remotes.Get("Toast"):FireClient(player, text)
end

RunContext.ComputeStats = RunStats.ComputeStats
RunContext.HasItemSpecial = RunStats.HasItemSpecial
RunContext.HasHeroicLifesteal = RunStats.HasHeroicLifesteal
RunContext.HasGreasyOilResist = RunStats.HasGreasyOilResist

function RunContext.NewRunState(deaths: number): RunState
	return {
		sessionId = '', generation = 0, stateVersion = 0, phase = 'Loading',
		clientReady = false, characterReady = false, deathProcessed = false,
		completionCommitted = false, rewardLedger = {}, pendingOffer = nil,
		offerSequence = 0, pendingNewspaper = nil, pendingCredits = nil,
		pendingDialogue = {}, bossState = nil,
		runTurtlesRescued = 0, totalTurtlesRescued = 0,
		stageId = "Hub",
		stageIndex = 0,
		hp = Constants.BASE_HP,
		maxHp = Constants.BASE_HP,
		personas = { "BeachBurnout" },
		activePersona = 1,
		unlockedPersonas = { BeachBurnout = true },
		personaRarity = { BeachBurnout = "Common" },
		items = {},
		itemSlots = Constants.STARTING_ITEM_SLOTS,
		sunburn = 0,
		luck = 0,
		damageMult = 1,
		speedBonus = 0,
		dodgeBonus = 0,
		deaths = deaths,
		turtlesRescued = 0,
		turtlesNeeded = 0,
		hangoverUntil = 0,
		coldOneTaken = false,
		waveFlags = {},
		minibossSpawned = false,
		bossSpawned = false,
		bossDefeated = false,
		awaitingDraft = false,
		awaitingNewspaper = false,
		inHub = true,
		runActive = false,
		combo = 0,
		lastAttackAt = 0,
		lastHurtAt = 0,
		skillReadyAt = 0,
		swapReadyAt = 0,
		dodgeReadyAt = 0,
		emberUntil = 0,
		facing = 1,
		unlockedFireworks = false,
		weaponId = Constants.STARTING_WEAPON,
		unlockedWeapons = { BareHands = true, FlipFlopSlap = true },
		moveSpeed = 18,
		checkpointX = 18,
		tutorial = TutorialService.NewFlags(),
		steveEvents = {},
		pendingSteveEvent = nil,
		midRoomState = "idle",
		lastActShown = 0,
	}
end

function RunContext.TeleportPlayer(player: Player, cf: CFrame)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		MovementAuthority.Reset(player, cf)
		if char then
			char:SetAttribute('LastSolidX', nil)
			char:SetAttribute('LastSolidY', nil)
		end
	end
end

function RunContext.ApplyPersonaLook(player: Player)
    CharacterStatePublisher.ApplyPersonaLook(player,states[player])
end

function RunContext.ApplyCharacterSpeed(player: Player)
    CharacterStatePublisher.ApplyCharacterSpeed(player,states[player])
end

function RunContext.UnlockPersona(player: Player, personaId: string)
	local s = states[player]
	if not s then
		return
	end
	if not Personas.Get(personaId) or not ProgressionRules.CanUnlockPersona(personaId,s.completionCommitted) then return end
	if s.unlockedPersonas[personaId] then
		return
	end
	s.unlockedPersonas[personaId] = true
	s.personaRarity[personaId] = s.personaRarity[personaId] or "Common"
	local def = Personas.Get(personaId)
	RunContext.Toast(player, "Persona unlocked: " .. (if def then def.name else personaId))

	RunContext.PersistMeta(player, s)
	RunContext.PushState(player)
end

-- Hard slot cap (N0.1): never exceed itemSlots
function RunContext.TryGrantItem(player: Player, itemId: string, replaceIndex: number?): (boolean, string?)
	local s = states[player]
	if not s then
		return false, 'Run is not ready.'
	end
	local result, reason = ItemGrantRules.Grant(s.items,s.itemSlots,itemId,replaceIndex,Items.Get)
	if not result then return false, reason end
	s.items = result
	RunContext.ComputeStats(s)
	local it = Items.Get(itemId)
	if it and it.healOnPickup > 0 then
		s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
	end
	RunContext.ApplyCharacterSpeed(player)
	RunContext.PushState(player)
	return true, reason
end

function RunContext.ActivePersonaDef(s: RunState)
	return Personas.Get(s.personas[s.activePersona])
end

return RunContext
