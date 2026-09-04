--!strict
--[[ Core run loop: hub → stages → draft → finale → credits. Death → beach. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Personas = require(Shared:WaitForChild("Personas"))
local Items = require(Shared:WaitForChild("Items"))
local Stages = require(Shared:WaitForChild("Stages"))
local Enemies = require(Shared:WaitForChild("Enemies"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local Balance = require(Shared:WaitForChild("Balance"))
local Story = require(Shared:WaitForChild("Story"))

local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))

local GameService = {}

export type RunState = {
	stageId: string,
	stageIndex: number,
	hp: number,
	maxHp: number,
	personas: { string }, -- up to 2
	activePersona: number, -- 1 or 2
	unlockedPersonas: { [string]: boolean },
	personaRarity: { [string]: string },
	items: { string },
	itemSlots: number,
	sunburn: number,
	luck: number,
	damageMult: number,
	speedBonus: number,
	dodgeBonus: number,
	deaths: number,
	turtlesRescued: number,
	turtlesNeeded: number,
	hangoverUntil: number,
	coldOneTaken: boolean,
	waveFlags: { [number]: boolean },
	minibossSpawned: boolean,
	bossSpawned: boolean,
	bossDefeated: boolean,
	awaitingDraft: boolean,
	awaitingNewspaper: boolean,
	inHub: boolean,
	runActive: boolean,
	combo: number,
	lastAttackAt: number,
	lastHurtAt: number, -- for swap-within-2s punish bonus
	skillReadyAt: number,
	swapReadyAt: number,
	dodgeReadyAt: number,
	facing: number,
	unlockedFireworks: boolean,
	weaponId: string,
	unlockedWeapons: { [string]: boolean },
	moveSpeed: number,
	checkpointX: number,
	tutorial: any,
	steveEvents: { [string]: boolean },
	pendingSteveEvent: string?,
	midRoomState: string, -- idle | locked | cleared
	lastActShown: number,
}

local states: { [Player]: RunState } = {}
local rng = Random.new()

local function pushState(player: Player)
	local s = states[player]
	if not s then
		return
	end
	Remotes.Get("StateUpdate"):FireClient(player, {
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
		hangoverUntil = s.hangoverUntil,
		inHub = s.inHub,
		runActive = s.runActive,
		skillReadyAt = s.skillReadyAt,
		swapReadyAt = s.swapReadyAt,
		dodgeReadyAt = s.dodgeReadyAt,
		serverNow = os.clock(),
		awaitingDraft = s.awaitingDraft,
		awaitingNewspaper = s.awaitingNewspaper,
		bossDefeated = s.bossDefeated,
		weaponId = s.weaponId,
		moveSpeed = s.moveSpeed,
		hangoverActive = os.clock() < s.hangoverUntil,
		actName = Balance.TierName(s.stageIndex),
		actNumber = Balance.ActNumber(s.stageIndex),
	})
end

local function toast(player: Player, text: string)
	Remotes.Get("Toast"):FireClient(player, text)
end

local function computeStats(s: RunState)
	local maxHp = Constants.BASE_HP
	local dmg = 1
	local speed = 0
	local luck = 0
	local dodge = 0
	for _, id in s.items do
		local it = Items.Get(id)
		if it then
			maxHp += it.hpBonus
			dmg += it.damageBonus / 20
			speed += it.speedBonus
			luck += it.luckBonus
			dodge += it.dodgeBonus
			if it.special == "antiCorp" then
				dmg += 0.08
			end
			if it.special == "badge" then
				maxHp += 5
				dmg += 0.1
			end
		end
	end
	local counts = Items.CountInscriptions(s.items)
	for tag, n in counts do
		if n >= Constants.INSCRIPTION_SET_SIZE then
			local bonus = Items.SetBonuses[tag]
			if bonus then
				maxHp += bonus.hpBonus or 0
				if bonus.damageBonus then
					dmg += bonus.damageBonus
				end
				luck += bonus.luckBonus or 0
				dodge += bonus.dodgeBonus or 0
			end
		end
	end
	s.maxHp = maxHp
	s.damageMult = dmg
	s.speedBonus = speed
	s.luck = luck
	s.dodgeBonus = dodge
	if s.hp > s.maxHp then
		s.hp = s.maxHp
	end
end


local function hasItemSpecial(s: RunState, special: string): boolean
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == special then
			return true
		end
	end
	return false
end

local function hasHeroicLifesteal(s: RunState): boolean
	local counts = Items.CountInscriptions(s.items)
	return (counts.HEROIC or 0) >= Constants.INSCRIPTION_SET_SIZE
end

local function applyOnHitSpecials(player: Player, s: RunState, model: Model, baseDamage: number): number
	local dmg = baseDamage
	-- paperCut: crit-ish bonus
	if hasItemSpecial(s, "paperCut") and rng:NextNumber() < (0.18 + s.luck * 0.25) then
		dmg *= 1.45
		toast(player, "Paper cut crit!")
	end
	-- radio: vs Oil Gators
	if hasItemSpecial(s, "radio") and model:GetAttribute("EnemyId") == "OilGator" then
		dmg *= 1.35
	end
	-- antiCorp already in computeStats; badge too
	-- lifesteal from HEROIC set (3 inscriptions)
	if hasHeroicLifesteal(s) then
		local heal = math.max(2, math.floor(dmg * 0.06))
		s.hp = math.min(s.maxHp, s.hp + heal)
	end
	return dmg
end

local function hitEnemy(player: Player, s: RunState, model: Model, amount: number, knock: number, heavy: boolean): boolean
	local dmg = applyOnHitSpecials(player, s, model, amount)
	return EnemyService.ApplyDamage(model, dmg, player, knock, heavy)
end

local function newRunState(deaths: number): RunState
	return {
		stageId = "Hub",
		stageIndex = 0,
		hp = Constants.BASE_HP,
		maxHp = Constants.BASE_HP,
		personas = { "BeachBurnout" },
		activePersona = 1,
		unlockedPersonas = { BeachBurnout = true },
		personaRarity = { BeachBurnout = "Common" },
		items = {},
		itemSlots = if deaths > 0 then Constants.ITEM_SLOTS_AFTER_FIRST_DEATH else Constants.STARTING_ITEM_SLOTS,
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

local function teleportPlayer(player: Player, cf: CFrame)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = cf
	end
end


local function applyPersonaLook(player: Player)
	local s = states[player]
	local char = player.Character
	if not s or not char then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	if not persona then
		return
	end
	char:SetAttribute("PersonaId", persona.id)
	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	if weapon then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponId", weapon.id)
		char:SetAttribute("WeaponKind", weapon.kind)
	end
	-- BodyColors tint (R6/R15)
	local bc = char:FindFirstChildOfClass("BodyColors")
	if not bc then
		bc = Instance.new("BodyColors")
		bc.Parent = char
	end
	local skin = persona.color:Lerp(Color3.fromRGB(255, 220, 180), 0.35)
	local accent = persona.accent
	bc.HeadColor3 = skin
	bc.TorsoColor3 = persona.color:Lerp(Color3.fromRGB(40, 40, 50), 0.25)
	bc.LeftArmColor3 = skin
	bc.RightArmColor3 = skin
	bc.LeftLegColor3 = accent:Lerp(skin, 0.5)
	bc.RightLegColor3 = accent:Lerp(skin, 0.5)
	-- Highlight outline for readable persona identity
	local hl = char:FindFirstChild("FM_PersonaHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "FM_PersonaHighlight"
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = char
	end
	if hl:IsA("Highlight") then
		hl.FillColor = persona.color
		hl.OutlineColor = persona.accent
		hl.FillTransparency = 0.82
		hl.OutlineTransparency = 0.15
	end
end

local function applyCharacterSpeed(player: Player)
	local s = states[player]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not s or not hum then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	local base = if persona then persona.moveSpeed else 18
	base += s.speedBonus
	if os.clock() < s.hangoverUntil then
		base *= Constants.HANGOVER_SLOW
	end
	s.moveSpeed = base
	-- Client MovementController drives motion; keep WalkSpeed 0 to avoid fight
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.AutoRotate = false
	if char then
		char:SetAttribute("MoveSpeed", base)
		char:SetAttribute("Hangover", os.clock() < s.hangoverUntil)
		char:SetAttribute("AggroPull", hasItemSpecial(s, "aggro"))
	end
	applyPersonaLook(player)
end

function GameService.LoadHub(player: Player)
	local s = states[player]
	if not s then
		return
	end
	s.inHub = true
	s.runActive = false
	s.stageId = "Hub"
	s.stageIndex = 0
	s.awaitingDraft = false
	s.awaitingNewspaper = false
	EnemyService.Clear()
	WorldBuilder.BuildStage("Hub", s.deaths)
	teleportPlayer(player, WorldBuilder.GetSpawnCFrame("Hub"))
	applyCharacterSpeed(player)
	s.checkpointX = Constants.SPAWN_X
	pushState(player)
	local line = if s.pendingSteveEvent then (Story.SteveEventLine(s.pendingSteveEvent) or Story.SteveLine(1, s.deaths)) else Story.SteveLine(1, s.deaths)
	if s.pendingSteveEvent then
		s.steveEvents[s.pendingSteveEvent] = true
		s.pendingSteveEvent = nil
	end
	toast(player, if s.deaths > 0 then Story.HubHeadline(s.deaths) else "Dawn. Bonfire. Crabs stole your Cold One.")
	task.delay(1.5, function()
		Remotes.Get("ShowTagline"):FireClient(player, line, "Captain Steve")
	end)
	TutorialService.OnHubLoaded(player, s.tutorial)
end

local function spawnStageThreats(player: Player)
	local s = states[player]
	if not s then
		return
	end
	local stage = Stages.Get(s.stageId)
	if not stage or stage.isHub then
		return
	end
	-- turtles
	if stage.rescueTurtles > 0 then
		s.turtlesNeeded = stage.rescueTurtles
		s.turtlesRescued = 0
		for i = 1, stage.rescueTurtles do
			local x = stage.length * (0.2 + 0.12 * i)
			EnemyService.SpawnTurtle(x)
		end
	end
end

function GameService.LoadStage(player: Player, stageId: string)
	local s = states[player]
	if not s then
		return
	end
	local stage = Stages.Get(stageId)
	assert(stage, "bad stage")
	s.stageId = stageId
	s.stageIndex = stage.index
	s.inHub = stage.isHub
	s.runActive = not stage.isHub
	s.waveFlags = {}
	s.minibossSpawned = false
	s.bossSpawned = false
	s.bossDefeated = false
	s.turtlesRescued = 0
	s.turtlesNeeded = 0
	s.coldOneTaken = false
	s.midRoomState = "idle"
	EnemyService.Clear()
	EnemyService.SetStageContext(stage.index)
	WorldBuilder.BuildStage(stageId, s.deaths)
	s.checkpointX = Constants.SPAWN_X
	teleportPlayer(player, WorldBuilder.GetSpawnCFrame(stageId))
	if stage.index == 1 then
		TutorialService.OnStage1Loaded(player, s.tutorial)
	end
	-- Act 1 collar hint on Boardwalk (stage 2)
	if stage.index == 2 and not s.steveEvents["collarHint"] then
		task.delay(3.5, function()
			if not s.steveEvents["collarHint"] then
				s.steveEvents["collarHint"] = true
				local el = Story.SteveEventLine("collarHint")
				if el then
					Remotes.Get("ShowTagline"):FireClient(player, el, "Captain Steve")
					toast(player, "Captain Steve: " .. el)
				end
			end
		end)
	end
	if stage.hangover then
		s.hangoverUntil = os.clock() + Constants.HANGOVER_DURATION
		toast(player, "Status: Hangover — slower until you reclaim The Cold One. (Florida Dew. Not alcohol.)")
	else
		s.hangoverUntil = 0
	end
	applyCharacterSpeed(player)
	spawnStageThreats(player)
	Remotes.Get("StageLoaded"):FireClient(player, stageId, stage.name)
	pushState(player)

	-- Act opener + Steve vignette when crossing into a new act
	local act = Balance.ActNumber(stage.index)
	local actChanged = (act ~= s.lastActShown) and stage.index >= 1
	if actChanged then
		s.lastActShown = act
		task.delay(0.35, function()
			toast(player, Story.ActOpener(act))
			Remotes.Get("ShowTagline"):FireClient(player, Story.SteveLine(act, s.deaths), "Captain Steve")
		end)
	end
	local beat = stage.storyBeat
	if beat and beat ~= "" then
		task.delay(1.2, function()
			toast(player, beat)
		end)
	end
	if stage.showMutantTagline then
		task.delay(2.5, function()
			Remotes.Get("ShowTagline"):FireClient(player, Constants.TAGLINE_MUTANTS, "Captain Steve")
		end)
	elseif (not actChanged) and stage.steveAct and stage.steveAct >= 2 then
		-- Non-transition stages still get a Steve line (avoid double with act vignette)
		task.delay(3.0, function()
			Remotes.Get("ShowTagline"):FireClient(player, Story.SteveLine(stage.steveAct, s.deaths), "Captain Steve")
		end)
	end
end

local function unlockPersona(player: Player, personaId: string)
	local s = states[player]
	if not s then
		return
	end
	if s.unlockedPersonas[personaId] then
		return
	end
	s.unlockedPersonas[personaId] = true
	s.personaRarity[personaId] = s.personaRarity[personaId] or "Common"
	local def = Personas.Get(personaId)
	toast(player, "Persona unlocked: " .. (if def then def.name else personaId))
	-- auto-equip if second slot empty
	if #s.personas < 2 then
		table.insert(s.personas, personaId)
		toast(player, "Equipped to persona slot 2!")
	end
	pushState(player)
end

local function onEnemyKilled(player: Player, enemyId: string, _model: Model)
	local s = states[player]
	if not s then
		return
	end
	-- sunburnFind item special: bonus meta currency on kills
	if hasItemSpecial(s, "sunburnFind") then
		local gain = 1 + (if rng:NextNumber() < (0.12 + s.luck) then 2 else 0)
		s.sunburn += gain
	end
	local def = Enemies.Get(enemyId)
	if def and def.dropsPersona then
		unlockPersona(player, def.dropsPersona)
	end
	if def and def.dropsItem and rng:NextNumber() < 0.35 + s.luck then
		-- grant if space else convert hint
		if #s.items < math.max(s.itemSlots, 8) then
			table.insert(s.items, def.dropsItem)
			local it = Items.Get(def.dropsItem)
			toast(player, "Found: " .. (if it then it.name else def.dropsItem))
			computeStats(s)
		end
	end
	if enemyId == "Spillfather" then
		s.bossDefeated = true
		toast(player, "The Spillfather poofs into recycled headlines!")
		pushState(player)
		task.delay(1.2, function()
			GameService.FinishRun(player)
		end)
		return
	end
	-- stage unlock personas from stage def when miniboss dies
	local stage = Stages.Get(s.stageId)
	if stage and stage.miniboss == enemyId and stage.unlockPersona then
		unlockPersona(player, stage.unlockPersona)
	end
	if enemyId == "FireLizard" then
		unlockPersona(player, "LizardBreath")
	end
	if enemyId == "Cottonmouth" then
		unlockPersona(player, "SnakeCharmer")
	end
	pushState(player)
end

local function onTurtleRescued(player: Player, model: Model)
	local s = states[player]
	if not s then
		return
	end
	s.turtlesRescued += 1
	s.hp = math.min(s.maxHp, s.hp + 8)
	toast(player, string.format("Turtle rescued! (%d/%d) — Press E near turtles.", s.turtlesRescued, s.turtlesNeeded))
	local root = model and model.PrimaryPart
	local pos = if root then root.Position else Vector3.new(0, 4, Constants.LANE_Z)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "focus",
		pos = pos,
		duration = 0.4,
		amount = 0.35,
	})
	if s.turtlesRescued >= s.turtlesNeeded and s.turtlesNeeded > 0 then
		unlockPersona(player, "TurtlePaladin")
		local stage = Stages.Get(s.stageId)
		if stage and stage.unlockPersona then
			unlockPersona(player, stage.unlockPersona)
		end
		toast(player, "Nest secure — turtles first. Gate unlocks when you clear the beach.")
		Remotes.Get("ShowTagline"):FireClient(player, "Rescue is the mission. GulfGulp's 'cleanup' was the cover.", "Captain Steve")
	end
	pushState(player)
end

function GameService.FinishStage(player: Player)
	local s = states[player]
	if not s or s.awaitingNewspaper or s.awaitingDraft then
		return
	end
	local stage = Stages.Get(s.stageId)
	if not stage or stage.isHub then
		return
	end
	-- turtle gate
	if stage.rescueTurtles > 0 and s.turtlesRescued < s.turtlesNeeded then
		toast(player, "Rescue all turtles before leaving! (Never harm them.)")
		return
	end
	if stage.boss and not s.bossDefeated then
		toast(player, "The Spillfather still blocks the exit.")
		return
	end
	-- heal from Novelty Mug
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == "stageHeal" then
			s.hp = math.min(s.maxHp, s.hp + 20)
		end
	end
	-- Gas station unlock golf cart
	if stage.id == "GasStationLegends" then
		unlockPersona(player, "GolfCartBandit")
	end
	-- Weapon unlocks along the arc
	local weaponDrops = {
		DaytonaHangover = "FlipFlopSlap",
		BoardwalkChaos = "PoolNoodle",
		GasStationLegends = "GolfClub",
		StripMallShowdown = "HOAClipboard",
		DriveThruDisaster = "GatorWrestleGloves",
		CanalRun = "KayakPaddle",
		SwampShift = "SnakeLasso",
		CypressCathedral = "TikiTorch",
		SludgeBayou = "SpillSkimmer",
		TurtleBeach = "NetGun",
		GulfGulpGate = "FireExtinguisher",
		LabWing = "BugZapper",
		PipeGauntlet = "OilBarrelLid",
		BargeCrossing = "BoogieBoard",
		OilPlatformApproach = "SludgeHose",
		HelipadHysteria = "RomanCandle",
		GulfGulpRig = "FinaleRocket",
	}
	local wid = weaponDrops[stage.id]
	if wid and not s.unlockedWeapons[wid] then
		s.unlockedWeapons[wid] = true
		s.weaponId = wid
		local wdef = Weapons.Get(wid)
		toast(player, "Weapon unlocked: " .. (if wdef then wdef.name else wid))
	end

	local nextStage = Stages.NextAfter(stage.id)
	s.awaitingNewspaper = true
	s.runActive = false
	EnemyService.Clear()
	pushState(player)
	local actNum = Balance.ActNumber(stage.index)
	Remotes.Get("ShowNewspaper"):FireClient(player, {
		headline = stage.headline,
		blurb = stage.blurb,
		storyBeat = stage.storyBeat,
		actName = Balance.TierName(stage.index),
		actNumber = actNum,
		panels = Story.NewspaperPanels(actNum),
		steveLine = Story.SteveLine(actNum, s.deaths),
		stageName = stage.name,
		nextName = if nextStage then nextStage.name else "Sunrise Credits",
		isFinale = nextStage == nil,
	})
end

function GameService.FinishRun(player: Player)
	local s = states[player]
	if not s then
		return
	end
	s.runActive = false
	unlockPersona(player, "FireworksEnthusiast")
	local creditLines = {}
	for _, line in Story.CREDITS do
		table.insert(creditLines, line)
	end
	table.insert(creditLines, "")
	table.insert(creditLines, "Deaths this legend: " .. tostring(s.deaths))
	table.insert(creditLines, "Turtles rescued forever: " .. tostring(s.turtlesRescued))
	Remotes.Get("ShowCredits"):FireClient(player, {
		title = "FLORIDA MAN",
		subtitle = "Sunrise over a swamp that gets to stay wild",
		lines = creditLines,
	})
	task.delay(2, function()
		GameService.LoadHub(player)
	end)
end

function GameService.StartRun(player: Player)
	local s = states[player]
	if not s then
		return
	end
	-- Only from hub (ProximityPrompt / E). Ignore duplicate triggers mid-run.
	if not s.inHub or s.runActive then
		return
	end
	s.inHub = false
	s.runActive = true -- claim immediately so double E/prompt cannot re-enter
	-- fresh run keeping meta deaths / unlocked? For roguelite: keep unlocks + sunburn + deaths, reset items/hp/stage
	local deaths = s.deaths
	local unlocked = s.unlockedPersonas
	local rarities = s.personaRarity
	local sunburn = s.sunburn
	local unlockedW = s.unlockedWeapons
	local itemSlots = if deaths > 0 then Constants.ITEM_SLOTS_AFTER_FIRST_DEATH else Constants.STARTING_ITEM_SLOTS
	states[player] = newRunState(deaths)
	s = states[player]
	s.unlockedPersonas = unlocked
	s.personaRarity = rarities
	s.sunburn = sunburn
	s.unlockedWeapons = unlockedW or { BareHands = true, FlipFlopSlap = true }
	s.weaponId = Constants.STARTING_WEAPON
	s.itemSlots = itemSlots
	s.unlockedPersonas.BeachBurnout = true
	s.personas = { "BeachBurnout" }
	-- if player has another unlocked, offer second slot filled with CrabKing if owned else first unlocked non-starter
	for id in unlocked do
		if id ~= "BeachBurnout" and #s.personas < 2 then
			table.insert(s.personas, id)
			break
		end
	end
	computeStats(s)
	s.hp = s.maxHp
	GameService.LoadStage(player, "DaytonaHangover")
	toast(player, "You wake after the last honest night of your life. The crabs stole your Cold One.")
end

function GameService.KillPlayer(player: Player)
	local s = states[player]
	if not s then
		return
	end
	CombatService.ClearIFrames(player)
	CombatService.ClearShieldAbsorb(player)
	s.deaths += 1
	s.hp = 0
	s.runActive = false
	toast(player, Story.DeathLine(s.deaths) .. " (+1 item slot after first death)")
	local deaths = s.deaths
	local unlocked = s.unlockedPersonas
	local rarities = s.personaRarity
	local sunburn = s.sunburn
	local unlockedW = s.unlockedWeapons
	states[player] = newRunState(deaths)
	s = states[player]
	s.unlockedPersonas = unlocked
	s.personaRarity = rarities
	s.sunburn = sunburn
	s.unlockedWeapons = unlockedW or { BareHands = true, FlipFlopSlap = true }
	s.itemSlots = Constants.ITEM_SLOTS_AFTER_FIRST_DEATH
	computeStats(s)
	s.hp = s.maxHp
	GameService.LoadHub(player)
end

function GameService.ApplyDamageToPlayer(player: Player, amount: number)
	local s = states[player]
	if not s or not s.runActive then
		return
	end
	if CombatService.HasIFrames(player) then
		return
	end
	-- Turtle shield absorb counter (server-owned)
	amount = CombatService.ConsumeShieldAbsorb(player, amount)
	if amount <= 0 then
		toast(player, "Shell absorbed the hit!")
		pushState(player)
		return
	end
	-- absorb item (oil/sludge resist)
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == "absorb" then
			amount = math.floor(amount * 0.75)
		end
	end
	s.lastHurtAt = os.clock()
	s.hp = math.max(0, s.hp - amount)
	pushState(player)
	if s.hp <= 0 then
		GameService.KillPlayer(player)
	end
end

local function activePersonaDef(s: RunState)
	return Personas.Get(s.personas[s.activePersona])
end

function GameService.DoAttack(player: Player)
	local s = states[player]
	if not s or not s.runActive or s.awaitingDraft then
		return
	end
	if not CombatService.CanAttack(player) then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local now = os.clock()
	local persona = activePersonaDef(s)
	if not persona then
		return
	end
	if now - s.lastAttackAt > Constants.COMBO_WINDOW then
		s.combo = 0
	end
	s.combo = (s.combo % 3) + 1
	s.lastAttackAt = now
	s.facing = if hrp.CFrame.LookVector.X >= 0 then 1 else -1
	local move = hrp.AssemblyLinearVelocity
	if math.abs(move.X) > 1 then
		s.facing = if move.X >= 0 then 1 else -1
	end

	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	local moveHit = CombatService.GetMovesetHit(persona.id, s.combo)
	CombatService.MarkAttack(player, moveHit.recovery / math.max(0.55, persona.attackSpeed * (weapon.speed or 1)))

	local base = (persona.attackDamage + (weapon.damage - 10) * 0.65) * s.damageMult * moveHit.dmgMul
	local rarity = s.personaRarity[persona.id] or "Common"
	base *= Balance.RarityMult(rarity)

	local range = (weapon.range or Constants.ATTACK_RANGE) * moveHit.rangeMul
	local knock = (weapon.knockback or Constants.KNOCKBACK_BASE) * moveHit.knockMul
	local origin = hrp.Position
	local hits = 0
	local heavy = s.combo == 3
	local wkind = weapon.kind or "melee"

	local function applyHit(model: Model, dmg: number, kb: number, hv: boolean)
		if hitEnemy(player, s, model, dmg, kb, hv) then
			-- killed
		end
		hits += 1
	end

	-- Ally rescue pass (all weapon kinds)
	for _, model in EnemyService.GetAlive() do
		if model:GetAttribute("IsAlly") then
			local root = model.PrimaryPart
			if root and (root.Position - origin).Magnitude < 10 then
				EnemyService.TryRescue(player, model)
			end
		end
	end

	if wkind == "ranged" then
		-- Fast lane projectile — distinct from melee InLaneMelee
		CombatService.SpawnProjectile({
			origin = origin,
			facing = s.facing,
			range = range,
			damage = base,
			knockback = knock * 0.35,
			heavy = heavy,
			kind = "ranged",
			vfx = weapon.vfx,
			attacker = player,
			onHit = function(model, dmg, kb, hv)
				applyHit(model, dmg, kb, hv)
			end,
		})
		-- real connects fire hitConnect from EnemyService
	elseif wkind == "thrown" then
		-- Arcing gravity-ish projectile
		CombatService.SpawnProjectile({
			origin = origin,
			facing = s.facing,
			range = range,
			damage = base * 1.05,
			knockback = knock * 0.4,
			heavy = heavy,
			kind = "thrown",
			vfx = weapon.vfx,
			attacker = player,
			onHit = function(model, dmg, kb, hv)
				applyHit(model, dmg, kb, hv)
			end,
		})
	else
		-- melee = lane InLaneMelee (current)
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			if CombatService.InLaneMelee(origin.X, s.facing, root.Position.X, range) then
				if math.abs(root.Position.Z - Constants.LANE_Z) < 6 then
					applyHit(model, base, knock * 0.45, heavy)
				end
			end
		end
	end

	if char then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponKind", wkind)
	end
	pushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "attack",
		combo = s.combo,
		facing = s.facing,
		weapon = s.weaponId,
		weaponKind = wkind,
		weaponVfx = weapon.vfx,
		hit = hits > 0,
		heavy = heavy,
		moveLabel = moveHit.label,
	})
	local sfx = if (wkind == "melee" and hits > 0) then "SFX_Hit" else "SFX_Swing"
	Remotes.Get("PlaySound"):FireClient(player, sfx)
	if s.stageIndex == 1 then
		TutorialService.OnAttack(player, s.tutorial)
	end
end

function GameService.DoSkill(player: Player)
	local s = states[player]
	if not s or not s.runActive then
		return
	end
	local now = os.clock()
	if now < s.skillReadyAt or not CombatService.CanSkill(player) then
		return
	end
	local persona = activePersonaDef(s)
	if not persona then
		return
	end
	local rarity = s.personaRarity[persona.id] or "Common"
	local cd = persona.skillCooldown * Balance.SkillCooldownMult(rarity)
	s.skillReadyAt = now + cd
	CombatService.MarkSkill(player, cd)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local dmg = persona.skillDamage * s.damageMult * Balance.RarityMult(rarity)
	local facing = s.facing
	local origin = hrp.Position

	if persona.skillKind == "shield" then
		-- Turtle: temporary damage absorb counter (not VFX-only / not only i-frames)
		s.hp = math.min(s.maxHp, s.hp + 18)
		CombatService.SetShieldAbsorb(player, Constants.SHIELD_ABSORB_AMOUNT)
		if char then
			char:SetAttribute("ShieldAbsorbVFX", true)
			task.delay(3.5, function()
				if char then
					char:SetAttribute("ShieldAbsorbVFX", nil)
				end
				-- absorb may already be spent; clear remainder after window
				if CombatService.GetShieldAbsorb(player) > 0 then
					CombatService.ClearShieldAbsorb(player)
				end
			end)
		end
		toast(player, persona.skillName .. "! Shell sanctuary — absorb ready.")
	elseif persona.skillKind == "summon" then
		-- Snake: lingering hitbox ~2s (distinct from instant AOE)
		CombatService.SpawnLingeringHitbox({
			origin = origin,
			facing = facing,
			duration = Constants.SUMMON_LINGER,
			radius = 7,
			damage = dmg * 0.45,
			knockback = Constants.KNOCKBACK_BASE * 0.35,
			tick = Constants.SUMMON_TICK,
			attacker = player,
			onHit = function(model, amount, knock, heavy)
				hitEnemy(player, s, model, amount, knock, heavy)
			end,
			color = Color3.fromRGB(120, 255, 140),
		})
		toast(player, persona.skillName .. "! Coil lingers.")
	elseif persona.skillKind == "beam" or persona.skillKind == "wave" then
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			local dx = root.Position.X - origin.X
			if dx * facing >= 0 and math.abs(dx) < 28 then
				local mult = if persona.id == "LizardBreath" and (model:GetAttribute("EnemyId") == "OilGator") then 1.4 else 1
				hitEnemy(player, s, model, dmg * mult, Constants.KNOCKBACK_BASE * 0.6, true)
			end
		end
	elseif persona.skillKind == "aoe" then
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and (root.Position - origin).Magnitude < 18 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.5, true)
			end
		end
	elseif persona.skillKind == "dash" then
		-- Cart Bandit: armor frames via SetIFrames; CrabKing/others dash without full armor
		local isCart = persona.id == "GolfCartBandit"
		if isCart then
			CombatService.SetIFrames(player, Constants.CART_DASH_IFRAME)
			if char then
				char:SetAttribute("IFrameVFX", true)
				task.delay(Constants.CART_DASH_IFRAME, function()
					if char then
						char:SetAttribute("IFrameVFX", nil)
					end
				end)
			end
			toast(player, persona.skillName .. "! Armor frames — full send.")
		end
		hrp.CFrame = hrp.CFrame + Vector3.new(facing * (if isCart then 16 else 14), 0, 0)
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and math.abs(root.Position.X - hrp.Position.X) < 12 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.55, true)
			end
		end
	end
	pushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "skill",
		skill = persona.skillName,
		skillKind = persona.skillKind,
		facing = facing,
	})
end

function GameService.DoDodge(player: Player, facingArg: number?)
	local s = states[player]
	if not s or not s.runActive then
		return
	end
	local now = os.clock()
	local cd = Constants.DODGE_COOLDOWN * (1 - math.clamp(s.dodgeBonus, 0, 0.5))
	if now < s.dodgeReadyAt then
		return
	end
	s.dodgeReadyAt = now + cd
	if typeof(facingArg) == "number" then
		s.facing = if facingArg >= 0 then 1 else -1
	end
	local char = player.Character
	-- Client MovementController performs the dash + trail; server grants i-frames only
	CombatService.SetIFrames(player, Constants.DODGE_IFRAME)
	if char then
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.DODGE_IFRAME, function()
			if char then
				char:SetAttribute("IFrameVFX", nil)
			end
		end)
	end
	Remotes.Get("CombatEvent"):FireClient(player, { kind = "dodge" })
	Remotes.Get("PlaySound"):FireClient(player, "SFX_Swing")
	pushState(player)
end

function GameService.DoSwap(player: Player)
	local s = states[player]
	if not s or not s.runActive then
		return
	end
	if #s.personas < 2 then
		toast(player, "Need 2 personas to swap. Unlock more!")
		return
	end
	local now = os.clock()
	if now < s.swapReadyAt or not CombatService.CanSwap(player) then
		return
	end
	s.swapReadyAt = now + Constants.SWAP_COOLDOWN
	CombatService.MarkSwap(player, Constants.SWAP_COOLDOWN)
	s.activePersona = if s.activePersona == 1 then 2 else 1
	applyCharacterSpeed(player)
	-- swap-attack combo route: damage + brief i-frame + readable toast/VFX
	local persona = activePersonaDef(s)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if char then
		CombatService.SetIFrames(player, Constants.SWAP_IFRAME)
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.SWAP_IFRAME, function()
			if char then
				char:SetAttribute("IFrameVFX", nil)
			end
		end)
	end
	local punish = (s.lastHurtAt > 0) and ((now - s.lastHurtAt) <= Constants.SWAP_PUNISH_WINDOW)
	if persona and hrp then
		local rarity = s.personaRarity[persona.id] or "Common"
		local mult = Constants.SWAP_ATTACK_DAMAGE_MULT * (if punish then Constants.SWAP_PUNISH_BONUS else 1)
		local dmg = persona.attackDamage * s.damageMult * mult * Balance.RarityMult(rarity)
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and (root.Position - hrp.Position).Magnitude < 14 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.75, true)
			end
		end
		if punish then
			toast(player, "SWAP PUNISH! " .. persona.name .. " — hit back harder!")
		else
			toast(player, "Swap attack! " .. persona.name .. " — risk the CD, reap the tempo!")
		end
	end
	pushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "swap",
		active = s.activePersona,
		personaId = if persona then persona.id else nil,
		color = if persona then { persona.color.R, persona.color.G, persona.color.B } else nil,
		punish = punish,
	})
end

function GameService.TickWaves(player: Player)
	local s = states[player]
	if not s or not s.runActive or s.inHub then
		return
	end
	local stage = Stages.Get(s.stageId)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not stage or not hrp then
		return
	end
	local progress = Util.Clamp(hrp.Position.X / stage.length, 0, 1)
	for i, wave in stage.waves do
		if not s.waveFlags[i] and progress >= wave.atProgress then
			s.waveFlags[i] = true
			local maxH = Balance.MaxHostiles(stage.index)
			local room = math.max(0, maxH - EnemyService.CountHostile())
			local toSpawn = Balance.WaveSpawnCap(stage.index, math.min(wave.count, math.max(1, room)))
			for i = 1, toSpawn do
				-- Phase 1: slightly wider spacing on teach stages so telegraphs read
				local gap = if stage.index <= 3 then 10 + i * 6 else 0
				local x = hrp.Position.X + 18 + gap + rng:NextNumber(0, if stage.index <= 3 then 8 else 12)
				EnemyService.Spawn(wave.enemyId, x)
			end
		end
	end
	if stage.miniboss and not s.minibossSpawned and progress >= 0.72 then
		s.minibossSpawned = true
		local mx = math.min(stage.length - 20, hrp.Position.X + 22)
		EnemyService.Spawn(stage.miniboss, mx)
		toast(player, "Miniboss incoming!")
		Remotes.Get("CombatEvent"):FireClient(player, {
			kind = "focus",
			pos = Vector3.new(mx, 4, Constants.LANE_Z),
			duration = 0.38,
			amount = 0.35,
		})
		if stage.miniboss == "CrabKingBoss" then
			TutorialService.OnCrabKingIntro(player, s.tutorial)
		end
	end
	if stage.boss and not s.bossSpawned and progress >= 0.55 then
		s.bossSpawned = true
		EnemyService.Spawn(stage.boss, math.min(stage.length - 25, hrp.Position.X + 28))
		-- adds
		EnemyService.Spawn("MutantAdd", hrp.Position.X + 20)
		EnemyService.Spawn("MutantAdd", hrp.Position.X + 32)
		EnemyService.Spawn("OilGator", hrp.Position.X + 36)
		toast(player, "THE SPILLFATHER — GulfGulp's final headline!")
		Remotes.Get("ShowTagline"):FireClient(player, Constants.TAGLINE_MUTANTS, "Captain Steve")
	end
	-- Phase 4 MidGate room system: enter zone → lock arena → spawn wave → clear → fanfare unlock
	do
		local world = Workspace:FindFirstChild("GameWorld")
		local mid = world and world:FindFirstChild("MidGate")
		local zone = world and world:FindFirstChild("MidRoomZone")
		local barrier = world and world:FindFirstChild("MidRoomBarrier")
		if mid and mid:IsA("BasePart") and zone and zone:IsA("BasePart") and hrp then
			local inZone = (hrp.Position - zone.Position).Magnitude < 10
			if s.midRoomState == "idle" and inZone and mid:GetAttribute("Locked") then
				s.midRoomState = "locked"
				if barrier and barrier:IsA("BasePart") then
					barrier.CanCollide = true
					barrier.Transparency = 0.4
				end
				toast(player, "ROOM LOCKED — clear the wave!")
				Remotes.Get("CombatEvent"):FireClient(player, {
					kind = "arenaLock",
					pos = mid.Position,
					duration = 0.4,
					amount = 0.4,
				})
				local roomWave = {
					{ id = "BeachCrab", n = 2 },
					{ id = "AngryTourist", n = 2 },
					{ id = "Cottonmouth", n = 2 },
					{ id = "GulfGulpGrunt", n = 2 },
					{ id = "OilGator", n = 1 },
				}
				local pick = roomWave[math.clamp(math.ceil(stage.index / 4), 1, #roomWave)]
				local maxH = Balance.MaxHostiles(stage.index)
				local room = math.max(0, maxH - EnemyService.CountHostile())
				local toSpawn = math.max(1, math.min(pick.n, math.max(1, room)))
				for i = 1, toSpawn do
					EnemyService.Spawn(pick.id, mid.Position.X - 6 - i * 5)
				end
			elseif s.midRoomState == "locked" and EnemyService.CountHostile() == 0 then
				s.midRoomState = "cleared"
				mid:SetAttribute("Locked", false)
				mid.CanCollide = false
				mid.Transparency = 0.85
				if barrier and barrier:IsA("BasePart") then
					barrier.CanCollide = false
					barrier.Transparency = 1
				end
				toast(player, "★ ROOM CLEAR — path open! ★")
				Remotes.Get("CombatEvent"):FireClient(player, {
					kind = "arenaUnlock",
					pos = mid.Position,
					duration = 0.42,
					amount = 0.45,
				})
				Remotes.Get("PlaySound"):FireClient(player, "SFX_DraftSting")
			end
		end
	end
	-- reach gate
	if progress >= 0.92 and EnemyService.CountHostile() == 0 then
		if stage.boss and not s.bossDefeated then
			return
		end
		GameService.FinishStage(player)
	elseif progress >= 0.95 and EnemyService.CountHostile() <= 1 and not stage.boss then
		-- allow clear with stragglers almost done — wait until 0 hostiles mostly
	end
	-- soft clear: if past 0.88 and killed miniboss requirement
	if progress >= 0.88 and not stage.boss and EnemyService.CountHostile() == 0 then
		GameService.FinishStage(player)
	end
	-- force-clear assist: if miniboss required and spawned and dead, allow exit near gate
	if stage.miniboss and s.minibossSpawned and progress >= 0.9 and EnemyService.CountHostile() == 0 then
		GameService.FinishStage(player)
	end
	if stage.rescueTurtles > 0 and s.turtlesRescued >= s.turtlesNeeded and progress >= 0.9 and EnemyService.CountHostile() == 0 then
		GameService.FinishStage(player)
	end
end

function GameService.InitPlayer(player: Player)
	states[player] = newRunState(0)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?
		-- Client-authoritative 2.5D mover: ownership must be on the player or server overwrites velocity → rubber-band
		if hrp then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		task.wait(0.3)
		-- Re-assert after teleport / physics settle
		if hrp and hrp.Parent then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		local s = states[player]
		if s then
			teleportPlayer(player, WorldBuilder.GetSpawnCFrame(s.stageId))
			if hrp and hrp.Parent then
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
			applyCharacterSpeed(player)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Died:Connect(function()
					-- use our HP system primarily; if humanoid dies, treat as kill
					GameService.KillPlayer(player)
				end)
			end
		end
	end)
	task.defer(function()
		GameService.LoadHub(player)
	end)
end

function GameService.GetState(player: Player): RunState?
	return states[player]
end



local function talkCaptainSteve(player: Player)
	local s = states[player]
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
	-- Phase 1: prefer event-tied Act 1 lines when pending / recently earned
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
	toast(player, "Captain Steve: " .. line)
	Remotes.Get("ShowTagline"):FireClient(player, line, "Captain Steve")
	pushState(player)
end

local function tryColdOnePickup(player: Player)
	local s = states[player]
	if not s or s.coldOneTaken or not s.runActive then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local world = Workspace:FindFirstChild("GameWorld")
	if not hrp or not world then
		return
	end
	local cold = world:FindFirstChild("ColdOne")
	if cold and cold:IsA("BasePart") and (cold.Position - hrp.Position).Magnitude < 6 then
		s.coldOneTaken = true
		s.hangoverUntil = 0
		s.hp = math.min(s.maxHp, s.hp + Constants.COLD_ONE_HEAL)
		cold:Destroy()
		applyCharacterSpeed(player)
		toast(player, "Walked into The Cold One (Florida Dew)! Hangover cleared. +" .. Constants.COLD_ONE_HEAL .. " HP")
		TutorialService.OnColdOne(player, s.tutorial)
		if not s.steveEvents["coldOne"] then
			s.steveEvents["coldOne"] = true
			s.pendingSteveEvent = "afterColdOneHub"
			local el = Story.SteveEventLine("coldOne")
			if el then
				task.delay(1.0, function()
					Remotes.Get("ShowTagline"):FireClient(player, el, "Captain Steve")
				end)
			end
		end
		pushState(player)
	end
end

function GameService.SetupRemotes()
	Remotes.InitServer()
	EnemyService.SetCallbacks(onEnemyKilled, onTurtleRescued)
	EnemyService.StartAI()

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local action = prompt:GetAttribute("FM_Action")
		if action == "StartRun" then
			GameService.StartRun(player)
		elseif action == "TalkCaptainSteve" then
			talkCaptainSteve(player)
		elseif action == "RescueTurtle" then
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("IsAlly") then
				EnemyService.TryRescue(player, model)
			end
		end
	end)

	Remotes.Get("RescueTurtle").OnServerEvent:Connect(function(player)
		-- Client assist: rescue nearest ally turtle within range
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") and not model:GetAttribute("Rescued") then
				local root = model.PrimaryPart
				if root and (root.Position - hrp.Position).Magnitude < 12 then
					EnemyService.TryRescue(player, model)
					break
				end
			end
		end
	end)

	Remotes.Get("TutorialBeat").OnServerEvent:Connect(function(player, beat)
		local s = states[player]
		if not s or typeof(beat) ~= "string" then
			return
		end
		local f = s.tutorial
		if beat == "move" then
			TutorialService.OnMoved(player, f)
		elseif beat == "jump" then
			TutorialService.OnJumped(player, f)
		elseif beat == "attack" then
			TutorialService.OnAttack(player, f)
		elseif beat == "dodge" then
			-- only credit dodge teach if they already heard attack tip
			if f.attack then
				TutorialService.OnDodgeDuringTele(player, f)
			end
		elseif beat == "nearColdOne" then
			if f.dodgeTele and not f.coldOne then
				-- gentle nudge once via existing coldOne path toast only if not taken
				if not s.coldOneTaken then
					-- OnDodge already tips Cold One; no extra spam
				end
			end
		end
	end)

	Remotes.Get("RequestStartRun").OnServerEvent:Connect(function(player)
		GameService.StartRun(player)
	end)
	Remotes.Get("RequestAttack").OnServerEvent:Connect(function(player)
		GameService.DoAttack(player)
	end)
	Remotes.Get("RequestSkill").OnServerEvent:Connect(function(player)
		GameService.DoSkill(player)
	end)
	Remotes.Get("RequestDodge").OnServerEvent:Connect(function(player, facingArg)
		GameService.DoDodge(player, facingArg)
	end)
	Remotes.Get("EquipWeapon").OnServerEvent:Connect(function(player, weaponId)
		local st = states[player]
		if not st or typeof(weaponId) ~= "string" then
			return
		end
		if not st.unlockedWeapons[weaponId] or not Weapons.Get(weaponId) then
			return
		end
		st.weaponId = weaponId
		local wdef = Weapons.Get(weaponId)
		toast(player, "Equipped: " .. (if wdef then wdef.name else weaponId))
		applyPersonaLook(player)
		pushState(player)
	end)
	Remotes.Get("RequestSwap").OnServerEvent:Connect(function(player)
		GameService.DoSwap(player)
	end)
	Remotes.Get("ContinueFromNewspaper").OnServerEvent:Connect(function(player)
		local s = states[player]
		if not s or not s.awaitingNewspaper then
			return
		end
		s.awaitingNewspaper = false
		local stage = Stages.Get(s.stageId)
		local nextStage = stage and Stages.NextAfter(stage.id)
		if not nextStage then
			GameService.FinishRun(player)
			return
		end
		-- draft
		s.awaitingDraft = true
		local picks = Items.RollDraft(rng, s.luck, Constants.DRAFT_CHOICES)
		local payload = {}
		for _, it in picks do
			table.insert(payload, { id = it.id, name = it.name, description = it.description, rarity = it.rarity, inscription = it.inscription, statText = it.statText })
		end
		Remotes.Get("ShowDraft"):FireClient(player, payload)
		pushState(player)
	end)
	Remotes.Get("PickDraftItem").OnServerEvent:Connect(function(player, itemId)
		local s = states[player]
		if not s or not s.awaitingDraft or typeof(itemId) ~= "string" then
			return
		end
		if not Items.Get(itemId) then
			return
		end
		table.insert(s.items, itemId)
		local it = Items.Get(itemId)
		if it and it.healOnPickup > 0 then
			s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
		end
		computeStats(s)
		s.awaitingDraft = false
		local stage = Stages.Get(s.stageId)
		local nextStage = stage and Stages.NextAfter(stage.id)
		pushState(player)
		if nextStage then
			GameService.LoadStage(player, nextStage.id)
		else
			GameService.FinishRun(player)
		end
	end)
	Remotes.Get("TalkCaptainSteve").OnServerEvent:Connect(function(player)
		talkCaptainSteve(player)
	end)
	Remotes.Get("SmashPersona").OnServerEvent:Connect(function(player, personaId)
		local s = states[player]
		if not s or typeof(personaId) ~= "string" then
			return
		end
		if personaId == "BeachBurnout" then
			toast(player, "Can't smash your starter Beach Burnout.")
			return
		end
		if not s.unlockedPersonas[personaId] then
			return
		end
		-- can't smash if currently only equipped copy and needed — allow smash of unlocked non-equipped
		local equipped = false
		for _, id in s.personas do
			if id == personaId then
				equipped = true
			end
		end
		if equipped then
			toast(player, "Unequip/swap off that persona first (keep it off active slots).")
			-- simplify: allow smash anyway but remove from slots
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
		toast(player, "Smashed for " .. gain .. " Sunburn ☀️")
		pushState(player)
	end)
	Remotes.Get("UpgradePersona").OnServerEvent:Connect(function(player, personaId)
		local s = states[player]
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
			toast(player, "Already Legendary!")
			return
		end
		local costs = { Common = 20, Rare = 45, Unique = 90 }
		local cost = costs[rarity] or 20
		if s.sunburn < cost then
			toast(player, "Need " .. cost .. " Sunburn (have " .. s.sunburn .. ")")
			return
		end
		s.sunburn -= cost
		s.personaRarity[personaId] = order[idx + 1]
		local pdef = Personas.Get(personaId)
		toast(player, (if pdef then pdef.name else personaId) .. " → " .. s.personaRarity[personaId])
		pushState(player)
	end)

	-- pending damage from enemy AI
	task.spawn(function()
		while true do
			task.wait(0.05)
			for _, player in Players:GetPlayers() do
				local pending = player:GetAttribute("PendingDamage")
				local at = player:GetAttribute("PendingDamageAt")
				if typeof(pending) == "number" and typeof(at) == "number" then
					if os.clock() - at < 0.2 then
						player:SetAttribute("PendingDamage", nil)
						GameService.ApplyDamageToPlayer(player, pending)
					end
				end
				GameService.TickWaves(player)
				tryColdOnePickup(player)
				-- hub interact proximity
				local st = states[player]
				if st and st.inHub then
					local char = player.Character
					local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
					local world = Workspace:FindFirstChild("GameWorld")
					if hrp and world then
						local flame = world:FindFirstChild("Flame")
						if flame and flame:IsA("BasePart") and (flame.Position - hrp.Position).Magnitude < 8 then
							-- client prompts start; server also accepts RequestStartRun
						end
					end
				end

				-- Hazard contact (set-piece verbs: timed fryer, water slow, conveyor, pipe)
				local worldH = Workspace:FindFirstChild("GameWorld")
				local charH = player.Character
				local hrpH = charH and charH:FindFirstChild("HumanoidRootPart") :: BasePart?
				local stH = states[player]
				if worldH and hrpH and stH and stH.runActive then
					local function tickTimedHazard(part: BasePart): boolean
						local period = part:GetAttribute("HazardPeriod")
						if typeof(period) ~= "number" or period <= 0 then
							return true -- always active
						end
						local duty = (part:GetAttribute("HazardDuty") :: number?) or 0.5
						local phase = (os.clock() % period) / period
						local active = phase < duty
						part:SetAttribute("HazardActive", active)
						if active then
							part.Transparency = math.min(part.Transparency, 0.25)
						else
							part.Transparency = math.max(part.Transparency, 0.65)
						end
						return active
					end
					local function scanHazards(container: Instance)
						for _, child in container:GetChildren() do
							if child:IsA("Folder") then
								scanHazards(child)
								continue
							end
							if not child:IsA("BasePart") then
								continue
							end
							-- Moving lab samples
							if child:GetAttribute("ConveyorMove") then
								local ox = (child:GetAttribute("ConveyorOriginX") :: number?) or child.Position.X
								local amp = (child:GetAttribute("ConveyorAmp") :: number?) or 6
								local spd = (child:GetAttribute("ConveyorSpeed") :: number?) or 1.2
								local nx = ox + math.sin(os.clock() * spd) * amp
								child.CFrame = CFrame.new(nx, child.Position.Y, Constants.LANE_Z)
							end
							if child:GetAttribute("Checkpoint") == true then
								if math.abs(child.Position.X - hrpH.Position.X) < 4 then
									stH.checkpointX = math.max(stH.checkpointX, child.Position.X)
								end
							end
							local hk = child:GetAttribute("Hazard")
							if typeof(hk) == "string" then
								local active = tickTimedHazard(child)
								local reach = if hk == "conveyor" then 6 elseif hk == "pipeSpray" then 4.5 else 5
								if (child.Position - hrpH.Position).Magnitude < reach then
									if hk == "canalWater" or child:GetAttribute("WaterSlow") then
										local slow = (child:GetAttribute("SlowAmount") :: number?) or 7
										stH.moveSpeed = math.min(stH.moveSpeed, slow)
										charH:SetAttribute("MoveSpeed", stH.moveSpeed)
										charH:SetAttribute("OilSlow", true)
										task.delay(0.9, function()
											if charH then
												charH:SetAttribute("OilSlow", nil)
											end
										end)
									elseif hk == "oilSlick" or hk == "sandSlow" or hk == "redTide" then
										stH.moveSpeed = math.min(stH.moveSpeed, 12)
										charH:SetAttribute("MoveSpeed", stH.moveSpeed)
										charH:SetAttribute("OilSlow", true)
										task.delay(1.2, function()
											if charH then
												charH:SetAttribute("OilSlow", nil)
											end
										end)
									elseif (hk == "fryerOil" or hk == "slushPuddle" or hk == "pipeSpray" or hk == "slickRing" or hk == "movingSample") and active then
										-- Timed / phase hazards: damage when HOT (jump rhythm)
										if not CombatService.HasIFrames(player) and hrpH.Position.Y < child.Position.Y + 3.5 then
											local last = charH:GetAttribute("LastHazardAt")
											local dmg = (child:GetAttribute("HazardDamage") :: number?) or 5
											if typeof(last) ~= "number" or os.clock() - last > 0.75 then
												charH:SetAttribute("LastHazardAt", os.clock())
												GameService.ApplyDamageToPlayer(player, dmg)
												local dy = child:GetAttribute("DisplaceY")
												if typeof(dy) == "number" then
													hrpH.AssemblyLinearVelocity = Vector3.new(hrpH.AssemblyLinearVelocity.X, dy, 0)
												end
											end
										end
									elseif hk == "conveyor" then
										local push = (child:GetAttribute("ConveyorPush") :: number?) or 18
										local v = hrpH.AssemblyLinearVelocity
										hrpH.AssemblyLinearVelocity = Vector3.new(v.X + push * 0.08, v.Y, 0)
										if not CombatService.HasIFrames(player) then
											local last = charH:GetAttribute("LastHazardAt")
											local dmg = (child:GetAttribute("HazardDamage") :: number?) or 4
											if typeof(last) ~= "number" or os.clock() - last > 0.9 then
												charH:SetAttribute("LastHazardAt", os.clock())
												GameService.ApplyDamageToPlayer(player, dmg)
											end
										end
									elseif hk == "fireCone" and not CombatService.HasIFrames(player) then
										local last = charH:GetAttribute("LastHazardAt")
										if typeof(last) ~= "number" or os.clock() - last > 0.8 then
											charH:SetAttribute("LastHazardAt", os.clock())
											GameService.ApplyDamageToPlayer(player, 4)
										end
									elseif hk == "windPush" then
										local dir = (child:GetAttribute("WindDir") :: number?) or -1
										hrpH.AssemblyLinearVelocity = Vector3.new(dir * 18, hrpH.AssemblyLinearVelocity.Y, 0)
									end
								end
							elseif child:GetAttribute("JumpPad") then
								if math.abs(child.Position.X - hrpH.Position.X) < 3 and hrpH.Position.Y < child.Position.Y + 3 then
									local v = hrpH.AssemblyLinearVelocity
									local boost = (child:GetAttribute("PadBoost") :: number?) or 52
									if v.Y < 10 then
										hrpH.AssemblyLinearVelocity = Vector3.new(v.X, boost, 0)
									end
								end
							end
						end
					end
					scanHazards(worldH)
				end

				-- Phase 4: soft checkpoint respawn for ALL combat stages (SafetyFloor removed)
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				local st2 = states[player]
				if hrp and st2 then
					local p = hrp.Position
					if math.abs(p.Z - Constants.LANE_Z) > 2.5 then
						hrp.CFrame = CFrame.new(p.X, p.Y, Constants.LANE_Z)
					end
					if st2.runActive and st2.stageIndex >= 1 then
						local stg = Stages.Get(st2.stageId)
						if stg and p.X > st2.checkpointX + 8 then
							st2.checkpointX = math.max(st2.checkpointX, math.min(p.X, stg.length - 15))
						end
						if p.Y < -6 then
							local lastFall = char:GetAttribute("LastSoftFallAt")
							if typeof(lastFall) ~= "number" or os.clock() - lastFall > 1.2 then
								char:SetAttribute("LastSoftFallAt", os.clock())
								local cx = st2.checkpointX or Constants.SPAWN_X
								hrp.CFrame = CFrame.new(cx, 5, Constants.LANE_Z)
								hrp.AssemblyLinearVelocity = Vector3.zero
								toast(player, "Soft checkpoint — back on the lane.")
								Remotes.Get("CombatEvent"):FireClient(player, { kind = "shake", amount = 0.4 })
								Remotes.Get("PlaySound"):FireClient(player, "SFX_Splash")
							end
						end
					end
					applyCharacterSpeed(player)
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

return GameService
