--!strict
--[[ N1 orchestrator: InitPlayer + remote wiring + tick pump. Logic lives in services. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Settings = require(Shared:WaitForChild("Settings"))
local Types = require(Shared:WaitForChild("Types"))

local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local MetaService = require(script.Parent:WaitForChild("MetaService"))
local HazardService = require(script.Parent:WaitForChild("HazardService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))
local DraftService = require(script.Parent:WaitForChild("DraftService"))
local HubService = require(script.Parent:WaitForChild("HubService"))
local StageFlowService = require(script.Parent:WaitForChild("StageFlowService"))
local CombatFacade = require(script.Parent:WaitForChild("CombatFacade"))

local GameService = {}

export type RunState = Types.RunState

local wired = false

-- N2 token buckets for combat remotes
type Bucket = { tokens: number, last: number }
local combatBuckets: { [Player]: { attack: Bucket, skill: Bucket, dodge: Bucket } } = {}

local function takeToken(player: Player, kind: string): boolean
	local rates = Constants.COMBAT_REMOTE_RATE
	local bursts = Constants.COMBAT_REMOTE_BURST
	local rate = (rates :: any)[kind] or 5
	local burst = (bursts :: any)[kind] or 2
	local bags = combatBuckets[player]
	if not bags then
		bags = {
			attack = { tokens = burst, last = os.clock() },
			skill = { tokens = burst, last = os.clock() },
			dodge = { tokens = burst, last = os.clock() },
		}
		combatBuckets[player] = bags
	end
	local b = (bags :: any)[kind] :: Bucket
	local now = os.clock()
	local elapsed = now - b.last
	b.last = now
	b.tokens = math.min(burst, b.tokens + elapsed * rate)
	if b.tokens < 1 then
		return false
	end
	b.tokens -= 1
	return true
end

function GameService.GetState(player: Player): RunState?
	return RunContext.GetState(player)
end

function GameService.ApplyDamageToPlayer(player: Player, amount: number)
	CombatFacade.ApplyDamageToPlayer(player, amount)
end

function GameService.InitPlayer(player: Player)
	local profile = MetaService.Load(player)
	Settings.EnsureDefaults(player)
	MetaService.ApplySettingsAttrs(player, profile)
	RunContext.SetState(player, RunContext.NewRunState(profile.deaths))
	MetaService.RegisterRunCapturer(player, function()
		local st = RunContext.GetState(player)
		if st then
			MetaService.CaptureFromRun(player, st.deaths, st.sunburn, st.unlockedPersonas, st.stageIndex)
		end
	end)
	local s0 = RunContext.GetState(player) :: RunState
	s0.sunburn = profile.sunburn
	s0.unlockedPersonas = { BeachBurnout = true }
	for _, id in profile.unlockedPersonas do
		s0.unlockedPersonas[id] = true
	end

	for id in s0.unlockedPersonas do
		if id ~= "BeachBurnout" and #s0.personas < 2 then
			table.insert(s0.personas, id)
			break
		end
	end
	if profile.deaths > 0 then
		s0.itemSlots = Constants.ITEM_SLOTS_AFTER_FIRST_DEATH
	end
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 8) :: BasePart?
		if hrp then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		task.wait(0.3)
		if hrp and hrp.Parent then
			pcall(function()
				hrp:SetNetworkOwner(player)
			end)
		end
		local s = RunContext.GetState(player)
		if s then
			RunContext.TeleportPlayer(player, WorldBuilder.GetSpawnCFrame(s.stageId))
			if hrp and hrp.Parent then
				pcall(function()
					hrp:SetNetworkOwner(player)
				end)
			end
			RunContext.ApplyCharacterSpeed(player)
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.Died:Connect(function()
					CombatFacade.KillPlayer(player)
				end)
			end
		end
	end)
	task.defer(function()
		StageFlowService.LoadHub(player)
	end)
end

function GameService.SetupRemotes()
	if wired then
		return
	end
	wired = true

	local deps = {
		Draft = DraftService,
		Hub = HubService,
		StageFlow = StageFlowService,
		Combat = CombatFacade,
	}
	DraftService.Init(deps)
	HubService.Init(deps)
	StageFlowService.Init(deps)
	CombatFacade.Init(deps)

	-- Remotes.InitServer owned by init.server.lua (N1.6 / N2 single call)
	EnemyService.SetCallbacks(StageFlowService.OnEnemyKilled, StageFlowService.OnTurtleRescued)
	EnemyService.StartAI()

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		local action = prompt:GetAttribute("FM_Action")
		if action == "StartRun" then
			HubService.StartRun(player)
		elseif action == "TalkCaptainSteve" then
			HubService.TalkCaptainSteve(player)
		elseif action == "RescueTurtle" then
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("IsAlly") then
				EnemyService.TryRescue(player, model)
			end
		end
	end)

	Remotes.Get("RescueTurtle").OnServerEvent:Connect(function(player)
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
		local s = RunContext.GetState(player)
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
			if f.attack then
				TutorialService.OnDodgeDuringTele(player, f)
			end
		elseif beat == "nearColdOne" then
			-- reserved; Cold One is walkover
		end
	end)

	Remotes.Get("RequestStartRun").OnServerEvent:Connect(function(player)
		HubService.StartRun(player)
	end)
	Remotes.Get("RequestAttack").OnServerEvent:Connect(function(player)
		if not takeToken(player, "attack") then
			return
		end
		CombatFacade.DoAttack(player)
	end)
	Remotes.Get("RequestSkill").OnServerEvent:Connect(function(player)
		if not takeToken(player, "skill") then
			return
		end
		CombatFacade.DoSkill(player)
	end)
	Remotes.Get("RequestDodge").OnServerEvent:Connect(function(player, facingArg)
		if not takeToken(player, "dodge") then
			return
		end
		CombatFacade.DoDodge(player, facingArg)
	end)
	Remotes.Get("EquipWeapon").OnServerEvent:Connect(function(player, weaponId)
		CombatFacade.EquipWeapon(player, weaponId)
	end)
	Remotes.Get("RequestSwap").OnServerEvent:Connect(function(player)
		CombatFacade.DoSwap(player)
	end)
	Remotes.Get("ContinueFromNewspaper").OnServerEvent:Connect(function(player)
		DraftService.ContinueFromNewspaper(player)
	end)
	Remotes.Get("PickDraftItem").OnServerEvent:Connect(function(player, itemId)
		DraftService.PickDraftItem(player, itemId)
	end)
	Remotes.Get("TalkCaptainSteve").OnServerEvent:Connect(function(player)
		HubService.TalkCaptainSteve(player)
	end)
	Remotes.Get("SmashPersona").OnServerEvent:Connect(function(player, personaId)
		HubService.SmashPersona(player, personaId)
	end)
	Remotes.Get("UpgradePersona").OnServerEvent:Connect(function(player, personaId)
		HubService.UpgradePersona(player, personaId)
	end)

	Remotes.Get("SyncSettings").OnServerEvent:Connect(function(player, key, value)
		if typeof(key) ~= "string" or typeof(value) ~= "boolean" then
			return
		end
		if key ~= "ShakeEnabled" and key ~= "ColorblindTelegraphs" then
			return
		end
		MetaService.UpdateSettings(player, key, value)
		local st = RunContext.GetState(player)
		if st then
			MetaService.CaptureFromRun(player, st.deaths, st.sunburn, st.unlockedPersonas, st.stageIndex)
			MetaService.Save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.05)
			for _, player in Players:GetPlayers() do
				StageFlowService.TickWaves(player)
				StageFlowService.TryColdOnePickup(player)

				local stH = RunContext.GetState(player)
				if stH then
					local ctx = {
						runActive = stH.runActive,
						stageId = stH.stageId,
						stageIndex = stH.stageIndex,
						checkpointX = stH.checkpointX,
						moveSpeed = stH.moveSpeed,
					}
					HazardService.Tick(player, ctx, CombatFacade.ApplyDamageToPlayer, RunContext.Toast)
					stH.checkpointX = ctx.checkpointX
					stH.moveSpeed = ctx.moveSpeed
					RunContext.ApplyCharacterSpeed(player)
				end
			end
		end
	end)
end

Players.PlayerRemoving:Connect(function(player)
	-- N2: MetaService.Unload (registered first) runs capturer+Save; we only clear run memory
	RunContext.ClearState(player)
	combatBuckets[player] = nil
end)

return GameService
