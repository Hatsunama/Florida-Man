--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
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
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))
local MetaService = require(script.Parent:WaitForChild("MetaService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))

local StageFlowService = {}

local deps: any = nil

function StageFlowService.Init(d: any)
	deps = d
end

local function spawnStageThreats(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	local stage = Stages.Get(s.stageId)
	if not stage or stage.isHub then
		return
	end
	if stage.rescueTurtles > 0 then
		s.turtlesNeeded = stage.rescueTurtles
		s.turtlesRescued = 0
		local goalX = stage.length - 14
		for i = 1, stage.rescueTurtles do
			local x = stage.length * (0.2 + 0.12 * i)
			local m = EnemyService.SpawnTurtle(x)
			if m then
				m:SetAttribute("EscortGoalX", goalX)
				m:SetAttribute("EscortEnabled", true)
			end
		end
	end
end

function StageFlowService.LoadHub(player: Player)
	local s = RunContext.GetState(player)
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
	RunContext.TeleportPlayer(player, WorldBuilder.GetSpawnCFrame("Hub"))
	RunContext.ApplyCharacterSpeed(player)
	s.checkpointX = Constants.SPAWN_X
	RunContext.PushState(player)
	local line = if s.pendingSteveEvent then (Story.SteveEventLine(s.pendingSteveEvent) or Story.SteveLine(1, s.deaths)) else Story.SteveLine(1, s.deaths)
	if s.pendingSteveEvent then
		s.steveEvents[s.pendingSteveEvent] = true
		s.pendingSteveEvent = nil
	end
	RunContext.Toast(player, if s.deaths > 0 then Story.HubHeadline(s.deaths) else "Dawn. Bonfire. Crabs stole your Cold One.")
	task.delay(1.5, function()
		Remotes.Get("ShowTagline"):FireClient(player, line, "Captain Steve")
	end)
	TutorialService.OnHubLoaded(player, s.tutorial)
	RunContext.PersistMeta(player, s)
end

function StageFlowService.LoadStage(player: Player, stageId: string)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	local stage = Stages.Get(stageId)
	assert(stage, "bad stage")
	s.stageId = stageId
	s.stageIndex = stage.index
	if stage.index > 0 then
		MetaService.CaptureFromRun(player, s.deaths, s.sunburn, s.unlockedPersonas, stage.index)
	end
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
	RunContext.TeleportPlayer(player, WorldBuilder.GetSpawnCFrame(stageId))
	do
		local char = player.Character
		if char then
			char:SetAttribute("SoftFallToasts", 0)
			char:SetAttribute("LastSolidX", nil)
			char:SetAttribute("LastSolidY", nil)
			char:SetAttribute("OilSlowUntil", nil)
			char:SetAttribute("OilSlow", nil)
			char:SetAttribute("WaterSince", nil)
		end
	end
	if stage.index == 1 then
		TutorialService.OnStage1Loaded(player, s.tutorial)
	end

	if stage.index == 2 and not s.steveEvents["collarHint"] then
		task.delay(3.5, function()
			if not s.steveEvents["collarHint"] then
				s.steveEvents["collarHint"] = true
				local el = Story.SteveEventLine("collarHint")
				if el then
					Remotes.Get("ShowTagline"):FireClient(player, el, "Captain Steve")
					RunContext.Toast(player, "Captain Steve: " .. el)
				end
			end
		end)
	end
	if stage.hangover then
		s.hangoverUntil = os.clock() + Constants.HANGOVER_DURATION
		RunContext.Toast(player, "Status: Hangover — slower until you reclaim The Cold One. (Florida Dew. Not alcohol.)")
	else
		s.hangoverUntil = 0
	end
	RunContext.ApplyCharacterSpeed(player)
	spawnStageThreats(player)
	Remotes.Get("StageLoaded"):FireClient(player, stageId, stage.name)
	RunContext.PushState(player)

	local act = Balance.ActNumber(stage.index)
	local actChanged = (act ~= s.lastActShown) and stage.index >= 1
	if actChanged then
		s.lastActShown = act
		task.delay(0.35, function()
			RunContext.Toast(player, Story.ActOpener(act))
			RunContext.Toast(player, Balance.RestToast(act))
			Remotes.Get("ShowTagline"):FireClient(player, Story.SteveLine(act, s.deaths), "Captain Steve")
		end)
	end
	local beat = stage.storyBeat
	if beat and beat ~= "" then
		task.delay(1.2, function()
			RunContext.Toast(player, beat)
		end)
	end
	-- N5: stage mechanical verb (popup toast; dialogue stays Tagline/Toast only)
	do
		local verb = Stages.LevelVerb(stage)
		local vt = Story.VerbToast(verb)
		if vt then
			task.delay(0.7, function()
				RunContext.Toast(player, vt)
			end)
		end
	end
	if stage.showMutantTagline then
		task.delay(2.5, function()
			Remotes.Get("ShowTagline"):FireClient(player, Constants.TAGLINE_MUTANTS, "Captain Steve")
		end)
	elseif (not actChanged) and stage.steveAct and stage.steveAct >= 2 then
		task.delay(3.0, function()
			Remotes.Get("ShowTagline"):FireClient(player, Story.SteveLine(stage.steveAct, s.deaths), "Captain Steve")
		end)
	end
end

function StageFlowService.OnEnemyKilled(player: Player, enemyId: string, _model: Model)
	local s = RunContext.GetState(player)
	if not s then
		return
	end

	if RunContext.HasItemSpecial(s, "sunburnFind") then
		local gain = 1 + (if RunContext.GetRng():NextNumber() < (0.12 + s.luck) then 2 else 0)
		s.sunburn += gain
	end
	local def = Enemies.Get(enemyId)
	if def and def.dropsPersona then
		RunContext.UnlockPersona(player, def.dropsPersona)
	end
	if def and def.dropsItem and RunContext.GetRng():NextNumber() < 0.35 + s.luck then
		-- N0.1 hard itemSlots cap via CombatFacade grant
		if deps.Combat.GrantEnemyDrop(player, def.dropsItem) then
			local it = Items.Get(def.dropsItem)
			RunContext.Toast(player, "Found: " .. (if it then it.name else def.dropsItem))
		end
	end
	if enemyId == "Spillfather" then
		s.bossDefeated = true
		RunContext.Toast(player, "The Spillfather poofs into recycled headlines!")
		RunContext.PushState(player)
		task.delay(1.2, function()
			StageFlowService.FinishRun(player)
		end)
		return
	end

	local stage = Stages.Get(s.stageId)
	if stage and stage.miniboss == enemyId and stage.unlockPersona then
		RunContext.UnlockPersona(player, stage.unlockPersona)
	end
	if enemyId == "FireLizard" then
		RunContext.UnlockPersona(player, "LizardBreath")
	end
	if enemyId == "Cottonmouth" then
		RunContext.UnlockPersona(player, "SnakeCharmer")
	end
	RunContext.PushState(player)
end

function StageFlowService.OnTurtleRescued(player: Player, model: Model)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	s.turtlesRescued += 1
	s.hp = math.min(s.maxHp, s.hp + 8)
	RunContext.Toast(player, string.format("Turtle rescued! (%d/%d) — Press E near turtles.", s.turtlesRescued, s.turtlesNeeded))
	local root = model and model.PrimaryPart
	local pos = if root then root.Position else Vector3.new(0, 4, Constants.LANE_Z)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "focus",
		pos = pos,
		duration = 0.4,
		amount = 0.35,
	})
	if s.turtlesRescued >= s.turtlesNeeded and s.turtlesNeeded > 0 then
		RunContext.UnlockPersona(player, "TurtlePaladin")
		local stage = Stages.Get(s.stageId)
		if stage and stage.unlockPersona then
			RunContext.UnlockPersona(player, stage.unlockPersona)
		end
		RunContext.Toast(player, "Nest secure — turtles first. Gate unlocks when you clear the beach.")
		Remotes.Get("ShowTagline"):FireClient(player, "Rescue is the mission. GulfGulp's 'cleanup' was the cover.", "Captain Steve")
	end
	RunContext.PushState(player)
end

function StageFlowService.FinishStage(player: Player)
	local s = RunContext.GetState(player)
	if not s or s.awaitingNewspaper or s.awaitingDraft then
		return
	end
	local stage = Stages.Get(s.stageId)
	if not stage or stage.isHub then
		return
	end

	if stage.rescueTurtles > 0 and s.turtlesRescued < s.turtlesNeeded then
		RunContext.Toast(player, "Rescue all turtles before leaving! (Never harm them.)")
		return
	end
	if stage.boss and not s.bossDefeated then
		RunContext.Toast(player, "The Spillfather still blocks the exit.")
		return
	end

	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == "stageHeal" then
			s.hp = math.min(s.maxHp, s.hp + 20)
		end
	end

	if stage.id == "GasStationLegends" then
		RunContext.UnlockPersona(player, "GolfCartBandit")
	end

	-- N3: every Weapons.List id unlocks in-run (BareHands starter; rest stage-gated)
	local weaponDrops: { [string]: { string } } = {
		DaytonaHangover = { "FlipFlopSlap", "CoolerLid" },
		BoardwalkChaos = { "PoolNoodle", "NewspaperRoll" },
		GasStationLegends = { "GolfClub", "TrafficCone" },
		StripMallShowdown = { "HOAClipboard", "BeachUmbrella" },
		DriveThruDisaster = { "GatorWrestleGloves", "ShoppingCart" },
		CanalRun = { "KayakPaddle", "WaterBalloonSling" },
		SwampShift = { "SnakeLasso", "FishSmack" },
		CypressCathedral = { "TikiTorch", "LawnDart" },
		SludgeBayou = { "SpillSkimmer" },
		ConspiracyShack = { "Skateboard", "PelicanBeakReplica" },
		TurtleBeach = { "NetGun" },
		GulfGulpGate = { "FireExtinguisher" },
		LabWing = { "BugZapper" },
		PipeGauntlet = { "OilBarrelLid" },
		BargeCrossing = { "BoogieBoard" },
		OilPlatformApproach = { "SludgeHose" },
		HelipadHysteria = { "RomanCandle" },
		GulfGulpRig = { "FinaleRocket" },
	}
	local drops = weaponDrops[stage.id]
	if drops then
		for _, wid in drops do
			if not s.unlockedWeapons[wid] and Weapons.Get(wid) then
				s.unlockedWeapons[wid] = true
				s.weaponId = wid
				local wdef = Weapons.Get(wid)
				RunContext.Toast(player, "Weapon unlocked: " .. (if wdef then wdef.name else wid))
			end
		end
	end

	local nextStage = Stages.NextAfter(stage.id)
	if stage.index == 3 then
		FunnelService.Mark(player, "stage3_clear", { stage = stage.id })
	end
	s.awaitingNewspaper = true
	s.runActive = false
	EnemyService.Clear()
	RunContext.PushState(player)
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

function StageFlowService.FinishRun(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	s.runActive = false
	RunContext.UnlockPersona(player, "FireworksEnthusiast")
	local creditLines = {}
	for _, line in Story.CREDITS do
		table.insert(creditLines, line)
	end
	table.insert(creditLines, "")
	table.insert(creditLines, "Deaths this legend: " .. tostring(s.deaths))
	table.insert(creditLines, "Turtles rescued forever: " .. tostring(s.turtlesRescued))
	table.insert(creditLines, "")
	table.insert(creditLines, "Soft launch — InEngine_v3 art · dialogue = popup text only")
	table.insert(creditLines, "Florida Dew is soda/heal — not alcohol. SFX = combat (+ optional UI click).")
	FunnelService.Mark(player, "run_credits", { deaths = s.deaths })
	Remotes.Get("ShowCredits"):FireClient(player, {
		title = "FLORIDA MAN",
		subtitle = "Sunrise over a swamp that gets to stay wild",
		lines = creditLines,
	})
	task.delay(2, function()
		StageFlowService.LoadHub(player)
	end)
end

function StageFlowService.TryColdOnePickup(player: Player)
	local s = RunContext.GetState(player)
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
		RunContext.ApplyCharacterSpeed(player)
		RunContext.Toast(player, "Walked into The Cold One (Florida Dew)! Hangover cleared. +" .. Constants.COLD_ONE_HEAL .. " HP")
		TutorialService.OnColdOne(player, s.tutorial)
		FunnelService.Mark(player, "cold_one", { stage = s.stageId })
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
		RunContext.PushState(player)
	end
end

function StageFlowService.TickWaves(player: Player)
	local s = RunContext.GetState(player)
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
	local rng = RunContext.GetRng()
	for i, wave in stage.waves do
		if not s.waveFlags[i] and progress >= wave.atProgress then
			s.waveFlags[i] = true
			local maxH = Balance.MaxHostiles(stage.index)
			local room = math.max(0, maxH - EnemyService.CountHostile())
			local toSpawn = Balance.WaveSpawnCap(stage.index, math.min(wave.count, math.max(1, room)))
			for j = 1, toSpawn do
				local gap = if stage.index <= 3 then 10 + j * 6 else 0
				local x = hrp.Position.X + 18 + gap + rng:NextNumber(0, if stage.index <= 3 then 8 else 12)
				EnemyService.Spawn(wave.enemyId, x)
			end
		end
	end
	if stage.miniboss and not s.minibossSpawned and progress >= 0.72 then
		s.minibossSpawned = true
		local mx = math.min(stage.length - 20, hrp.Position.X + 22)
		EnemyService.Spawn(stage.miniboss, mx)
		RunContext.Toast(player, "Miniboss incoming!")
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
		EnemyService.Spawn("MutantAdd", hrp.Position.X + 20)
		EnemyService.Spawn("MutantAdd", hrp.Position.X + 32)
		EnemyService.Spawn("OilGator", hrp.Position.X + 36)
		RunContext.Toast(player, "THE SPILLFATHER — GulfGulp's final headline!")
		Remotes.Get("ShowTagline"):FireClient(player, Constants.TAGLINE_MUTANTS, "Captain Steve")
	end

	do
		local world = Workspace:FindFirstChild("GameWorld")
		local mid = world and world:FindFirstChild("MidGate")
		local zone = world and world:FindFirstChild("MidRoomZone")
		local barrier = world and world:FindFirstChild("MidRoomBarrier")
		if mid and mid:IsA("BasePart") and zone and zone:IsA("BasePart") and hrp then
			-- N2: MidGate + empty wave table → never lock (0-enemy softlock guard)
			if stage.waves == nil or #stage.waves == 0 then
				if mid:GetAttribute("Locked") then
					mid:SetAttribute("Locked", false)
					mid.CanCollide = false
					mid.Transparency = 0.85
				end
				if s.midRoomState == "idle" or s.midRoomState == "locked" then
					s.midRoomState = "cleared"
				end
			end
			local inZone = (hrp.Position - zone.Position).Magnitude < 10
			if s.midRoomState == "idle" and inZone and mid:GetAttribute("Locked") and stage.waves and #stage.waves > 0 then
				s.midRoomState = "locked"
				FunnelService.Mark(player, "midgate_lock", { stage = s.stageId })
				if barrier and barrier:IsA("BasePart") then
					barrier.CanCollide = true
					barrier.Transparency = 0.4
				end
				RunContext.Toast(player, "ROOM LOCKED — clear the wave!")
				-- N5: one story Tagline on first MidGate lock per act
				do
					local act = Balance.ActNumber(stage.index)
					local key = "midGateAct" .. tostring(act)
					if not s.steveEvents[key] then
						s.steveEvents[key] = true
						Remotes.Get("ShowTagline"):FireClient(player, Story.MidGateLockLine(act), "Captain Steve")
					end
				end
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
				local roomLeft = math.max(0, maxH - EnemyService.CountHostile())
				local toSpawn = math.max(1, math.min(pick.n, math.max(1, roomLeft)))
				for j = 1, toSpawn do
					EnemyService.Spawn(pick.id, mid.Position.X - 6 - j * 5)
				end
			elseif s.midRoomState == "locked" and EnemyService.CountHostile() == 0 then
				s.midRoomState = "cleared"
				FunnelService.Mark(player, "midgate_clear", { stage = s.stageId })
				mid:SetAttribute("Locked", false)
				mid.CanCollide = false
				mid.Transparency = 0.85
				if barrier and barrier:IsA("BasePart") then
					barrier.CanCollide = false
					barrier.Transparency = 1
				end
				RunContext.Toast(player, "★ ROOM CLEAR — path open! ★")
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

	if progress >= 0.92 and EnemyService.CountHostile() == 0 then
		if stage.boss and not s.bossDefeated then
			return
		end
		StageFlowService.FinishStage(player)
	elseif progress >= 0.95 and EnemyService.CountHostile() <= 1 and not stage.boss then
		-- soft clear window (unchanged)
	end

	if progress >= 0.88 and not stage.boss and EnemyService.CountHostile() == 0 then
		StageFlowService.FinishStage(player)
	end

	if stage.miniboss and s.minibossSpawned and progress >= 0.9 and EnemyService.CountHostile() == 0 then
		StageFlowService.FinishStage(player)
	end
	if stage.rescueTurtles > 0 and s.turtlesRescued >= s.turtlesNeeded and progress >= 0.9 and EnemyService.CountHostile() == 0 then
		StageFlowService.FinishStage(player)
	end
end

return StageFlowService
