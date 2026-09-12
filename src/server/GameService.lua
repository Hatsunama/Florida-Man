--!strict
--[[ N1 orchestrator: InitPlayer + remote wiring + tick pump. Logic lives in services. ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")

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
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))

local SessionService = require(script.Parent:WaitForChild("SessionService"))
local RuntimeMetrics = require(script.Parent:WaitForChild("RuntimeMetrics"))
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))

local GameService = {}

export type RunState = Types.RunState

local wired = false

-- One bounded ingress budget per command, including settings and interactions.
type Bucket = {tokens: number, last: number}
local combatBuckets: {[Player]: {[string]: Bucket}} = {}
local initialized: {[Player]: boolean} = {}
local clientReady: {[Player]: boolean} = {}
local simulationErrors: {[Player]: number} = {}
local replyBuckets: {[Player]: Bucket} = {}

local function takeToken(player: Player, kind: string): boolean
    if not SessionService.IsOwner(player) then RuntimeMetrics.Command(false); return false end
    local rate = (Constants.COMBAT_REMOTE_RATE :: any)[kind] or 3
    local burst = (Constants.COMBAT_REMOTE_BURST :: any)[kind] or 3
    local bags = combatBuckets[player] or {}
    combatBuckets[player] = bags
    local now = os.clock()
    local bucket = bags[kind] or {tokens = burst, last = now}
    bags[kind] = bucket
    bucket.tokens = math.min(burst, bucket.tokens + (now-bucket.last)*rate)
    bucket.last = now
    if bucket.tokens < 1 then RuntimeMetrics.Command(false); return false end
    bucket.tokens -= 1
    RuntimeMetrics.Command(true)
    return true
end

local function reject(player: Player, command: string, reason: string): boolean
    if not SessionService.IsOwner(player) then return false end
    local now=os.clock()
    local bucket: Bucket=replyBuckets[player] or {tokens=4,last=now}
    replyBuckets[player]=bucket
    bucket.tokens=math.min(4,bucket.tokens+(now-bucket.last)*4); bucket.last=now
    if bucket.tokens<1 then return false end
    bucket.tokens-=1
    Remotes.Get('CommandResult'):FireClient(player, {command=command,accepted=false,reason=reason})
    return true
end

local function face(player: Player, direction: unknown): number?
    local s = RunContext.GetState(player)
    if s and typeof(direction)=='number' and direction == direction and math.abs(direction) < math.huge then
        s.facing = if direction < 0 then -1 else 1
        return s.facing
    end
    return nil
end

local function canInteract(player: Player, action: string): boolean
    local state=RunContext.GetState(player)
    if not state or not state.characterReady then return false end
    local char=player.Character
    local hum=char and char:FindFirstChildOfClass('Humanoid')
    if not hum or hum.Health <= 0 then return false end
    local root=char and char:FindFirstChild('HumanoidRootPart')
    local world=workspace:FindFirstChild('GameWorld')
    if not root or not root:IsA('BasePart') or not world then return false end
    for _, object in world:GetDescendants() do
        if object:IsA('ProximityPrompt') and object.Enabled and object:GetAttribute('FM_Action') == action then
            local parent=object.Parent
            local position: Vector3? = nil
            if parent and parent:IsA('BasePart') then position=parent.Position
            elseif parent and parent:IsA('Attachment') then position=parent.WorldPosition
            elseif parent and parent:IsA('Model') then position=parent:GetPivot().Position end
            if position and (root.Position-position).Magnitude <= object.MaxActivationDistance+2 then return true end
        end
    end
    return false
end

local function spatialAction(player: Player, command: string): boolean
    local state=RunContext.GetState(player)
    if not state or not state.characterReady then
        reject(player,command,'Your character is still loading. Please wait.'); return false
    end
    if not MovementAuthority.Validate(player) then
        reject(player,command,'Position corrected. Please try again.'); return false
    end
    return true
end

local function startRun(player: Player)
    if not spatialAction(player,'RequestStartRun') then return end
    if not canInteract(player,'StartRun') then reject(player,'RequestStartRun','Use Interact beside the bonfire.'); return end
    HubService.StartRun(player)
end

local function talkSteve(player: Player)
    if not spatialAction(player,'TalkCaptainSteve') then return end
    if not canInteract(player,'TalkCaptainSteve') then reject(player,'TalkCaptainSteve','Move closer to Captain Steve.'); return end
    HubService.TalkCaptainSteve(player)
end

local function readySnapshot(player: Player)
    local s = RunContext.GetState(player)
    if not s then return end
    s.clientReady = true
    RunContext.PushState(player)
    Remotes.Get('StageLoaded'):FireClient(player,s.stageId,s.stageId)
    for _, beat in s.pendingDialogue do Remotes.Get('ShowTagline'):FireClient(player,beat) end
    table.clear(s.pendingDialogue)
    if s.pendingOffer then DraftService.ResendOffer(player) end
    if s.pendingNewspaper then Remotes.Get('ShowNewspaper'):FireClient(player,s.pendingNewspaper) end
    if s.pendingCredits then Remotes.Get('ShowCredits'):FireClient(player,s.pendingCredits) end
end

function GameService.GetState(player: Player): RunState?
	return RunContext.GetState(player)
end

function GameService.ApplyDamageToPlayer(player: Player, amount: number)
	CombatFacade.ApplyDamageToPlayer(player, amount)
end

function GameService.InitPlayer(player: Player)
    if initialized[player] then return end
    if not SessionService.Acquire(player) then
        player:Kick('This adventure supports one player per server. Please join a new server.')
        return
    end
    initialized[player] = true
    player:SetAttribute('RunActive',false)
    local profile = MetaService.Load(player)
    if not SessionService.IsOwner(player) then MetaService.Unload(player); return end
    FunnelService.OnJoin(player)
    Settings.EnsureDefaults(player)
    MetaService.ApplySettingsAttrs(player,profile)
    local s = RunContext.NewRunState(profile.deaths)
    s.sunburn = profile.sunburn
    for _, id in profile.unlockedPersonas do s.unlockedPersonas[id] = true end
    s.personaRarity = table.clone(profile.personaRarity)
    s.personas = table.clone(profile.personas)
    s.unlockedWeapons = {}
    for _, id in profile.unlockedWeapons do s.unlockedWeapons[id] = true end
    s.weaponId = profile.weaponId
    s.totalTurtlesRescued = profile.totalTurtlesRescued
    s.clientReady = clientReady[player] == true
    RunContext.SetState(player,s)
    MetaService.RegisterRunCapturer(player,function()
        local state = RunContext.GetState(player)
        if state then RunContext.PersistMeta(player,state) end
    end)
    local boundCharacter: Model? = nil
    local observedCharacter: Model? = nil
    local function bindCharacter(char: Model)
        if observedCharacter == char then return end
        observedCharacter = char
        boundCharacter = nil
        local loadingState=RunContext.GetState(player)
        if loadingState then loadingState.characterReady=false end
        SessionService.SetConnection(player,'characterDied',nil)
        local function tryReady()
            if boundCharacter==char or observedCharacter~=char or not SessionService.IsOwner(player) or player.Character~=char then return end
            -- CharacterAdded can run before Roblox parents the assembled model.
            -- Keep observing until the physics API can operate on its root.
            if not char:IsDescendantOf(workspace) then return end
            local hrp=char:FindFirstChild('HumanoidRootPart')
            local hum=char:FindFirstChildOfClass('Humanoid')
            if not hrp or not hrp:IsA('BasePart') or not hum or hum.Health<=0 or not hrp:IsDescendantOf(workspace) then return end
            local st=RunContext.GetState(player)
            if not st then return end
            local canOwn = hrp:CanSetNetworkOwnership()
            if not canOwn then return end
            local assigned = pcall(function() hrp:SetNetworkOwner(player) end)
            if not assigned then return end
            RunContext.TeleportPlayer(player,WorldBuilder.GetSpawnCFrame(st.stageId))
            RunContext.ApplyCharacterSpeed(player)
            boundCharacter=char
            SessionService.SetConnection(player,'characterParts',nil)
            SessionService.SetConnection(player,'characterAncestry',nil)
            SessionService.SetConnection(player,'characterRetry',nil)
            st.characterReady=true
            SessionService.SetConnection(player,'characterDied',hum.Died:Connect(function()
                if player.Character==char then CombatFacade.KillPlayer(player) end
            end))
            RunContext.PushState(player)
        end
        SessionService.SetConnection(player,'characterParts',char.ChildAdded:Connect(tryReady))
        SessionService.SetConnection(player,'characterAncestry',char.AncestryChanged:Connect(tryReady))
        local retryAt=0
        SessionService.SetConnection(player,'characterRetry',RunService.Heartbeat:Connect(function()
            if os.clock()<retryAt then return end
            retryAt=os.clock()+0.1
            tryReady()
        end))
        tryReady()
        SessionService.Delay(player,8,function()
            if observedCharacter==char and boundCharacter~=char then
                warn('[Florida Man] Character is still assembling; readiness listener retained')
                RunContext.Say(player,'Your character is still loading. Please wait; controls will activate when it is ready.','Loading')
                RunContext.PushState(player)
            end
        end)
        RunContext.PushState(player)
    end
    SessionService.TrackConnection(player,player.CharacterAdded:Connect(bindCharacter))
    SessionService.TrackConnection(player,player.CharacterRemoving:Connect(function()
        observedCharacter=nil; boundCharacter=nil
        SessionService.SetConnection(player,'characterParts',nil)
        SessionService.SetConnection(player,'characterAncestry',nil)
        SessionService.SetConnection(player,'characterRetry',nil)
        SessionService.SetConnection(player,'characterDied',nil)
        local current=RunContext.GetState(player)
        if current then current.characterReady=false end
        RunContext.PushState(player)
    end))
    StageFlowService.LoadHub(player)
    if player.Character then task.spawn(bindCharacter,player.Character) end
    if clientReady[player] then readySnapshot(player) end
    local status = MetaService.GetStatus(player)
    if not status.writable then RunContext.Say(player,'Progress could not be loaded safely. This session cannot save. Rejoin to retry.','Progress') end
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
	MetaService.SetStatusObserver(RunContext.PushState)
	RunContext.SetShopProvider(HubService.GetShopState,HubService.GetCommandSequence)

	-- Remotes.InitServer owned by init.server.lua (N1.6 / N2 single call)
	EnemyService.SetCallbacks(StageFlowService.OnEnemyKilled, StageFlowService.OnTurtleRescued)
	EnemyService.StartAI()

	ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, player: Player)
		if not takeToken(player,'interact') then return end
		local action = prompt:GetAttribute("FM_Action")
		if action == "StartRun" then
			startRun(player)
		elseif action == "TalkCaptainSteve" then
			talkSteve(player)
		elseif action == "RescueTurtle" then
			if not spatialAction(player,'RescueTurtle') then return end
			local model = prompt:FindFirstAncestorOfClass("Model")
			if model and model:GetAttribute("IsAlly") then
				EnemyService.TryRescue(player, model)
			end
		end
	end)

	Remotes.Get("RescueTurtle").OnServerEvent:Connect(function(player)
		if not takeToken(player,"RescueTurtle") then return end
		if not spatialAction(player,'RescueTurtle') then return end
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

	Remotes.Get("RequestStartRun").OnServerEvent:Connect(function(player)
		if not takeToken(player,"RequestStartRun") then return end
		startRun(player)
	end)
	Remotes.Get("RequestAttack").OnServerEvent:Connect(function(player, direction)
		if not takeToken(player, "attack") then
			return
		end
		if not spatialAction(player,'RequestAttack') then return end
		CombatFacade.DoAttack(player,face(player,direction))
	end)
	Remotes.Get("RequestSkill").OnServerEvent:Connect(function(player, direction)
		if not takeToken(player, "skill") then
			return
		end
		if not spatialAction(player,'RequestSkill') then return end
		CombatFacade.DoSkill(player,face(player,direction))
	end)
	Remotes.Get("RequestDodge").OnServerEvent:Connect(function(player, facingArg)
		if not takeToken(player, "dodge") then
			if reject(player,'RequestDodge','Dodge is not ready.') then RunContext.PushState(player) end
			return
		end
		local state=RunContext.GetState(player)
		-- Displacement starts only after acceptance; reject pre-existing invalid
		-- motion before issuing a fresh dodge distance allowance.
		if not spatialAction(player,'RequestDodge') then RunContext.PushState(player); return end
		local before=CombatService.GetDodgeReadyAt(player)
		CombatFacade.DoDodge(player, face(player,facingArg))
		local accepted=state ~= nil and CombatService.GetDodgeReadyAt(player) > before
		if accepted and state then TutorialService.OnDodgeAccepted(player, state.tutorial) end
		Remotes.Get('CommandResult'):FireClient(player,{command='RequestDodge',accepted=accepted,reason=if accepted then 'Dodge accepted.' else 'Finish the current action before dodging.'})
		RunContext.PushState(player)
	end)
	Remotes.Get("EquipWeapon").OnServerEvent:Connect(function(player, weaponId)
		if not takeToken(player,"EquipWeapon") then return end
		CombatFacade.EquipWeapon(player, weaponId)
	end)
	Remotes.Get("RequestSwap").OnServerEvent:Connect(function(player, direction)
		if not takeToken(player,"swap") then return end
		if not spatialAction(player,'RequestSwap') then return end
		CombatFacade.DoSwap(player,face(player,direction))
	end)
	Remotes.Get("ContinueFromNewspaper").OnServerEvent:Connect(function(player)
		if not takeToken(player,"ContinueFromNewspaper") then reject(player,'ContinueFromNewspaper','Please wait a moment and retry.'); return end
		local st=RunContext.GetState(player)
		if not st or not st.awaitingNewspaper or st.phase~='Reward' then
			reject(player,'ContinueFromNewspaper','This summary is no longer active.'); RunContext.PushState(player); return
		end
		DraftService.ContinueFromNewspaper(player)
		Remotes.Get('CommandResult'):FireClient(player,{command='ContinueFromNewspaper',accepted=true})
	end)
	Remotes.Get("PickDraftItem").OnServerEvent:Connect(function(player, itemId)
		if not takeToken(player,"PickDraftItem") then return end
		DraftService.PickDraftItem(player, itemId)
	end)
	Remotes.Get("TalkCaptainSteve").OnServerEvent:Connect(function(player)
		if not takeToken(player,"TalkCaptainSteve") then return end
		talkSteve(player)
	end)
	Remotes.Get("SmashPersona").OnServerEvent:Connect(function(player, personaId)
		if not takeToken(player,"SmashPersona") then return end
		HubService.SmashPersona(player, personaId)
	end)
	Remotes.Get("UpgradePersona").OnServerEvent:Connect(function(player, personaId)
		if not takeToken(player,"UpgradePersona") then return end
		HubService.UpgradePersona(player, personaId)
	end)

	Remotes.Get("SyncSettings").OnServerEvent:Connect(function(player, key, value)
		if not takeToken(player,"SyncSettings") then
			if reject(player,'SyncSettings','Please wait a moment before changing another option.') then RunContext.PushState(player) end
			return
		end
		local valid=typeof(key)=='string' and ((Settings.IsBoolKey(key) and typeof(value)=='boolean')
			or (key=='TextSpeed' and typeof(value)=='string' and Settings.IsValidTextSpeed(value)))
		local accepted=false
		if valid then
			accepted=MetaService.UpdateSettings(player,key,value) or Settings.Snapshot(player)[key]==value
		end
		Remotes.Get('CommandResult'):FireClient(player,{command='SyncSettings',accepted=accepted,reason=if accepted then 'Option applied.' else 'Option could not be applied. Please retry.'})
		RunContext.PushState(player)
	end)

    Remotes.Get('ClientReady').OnServerEvent:Connect(function(player,payload)
        clientReady[player] = true
        if not takeToken(player,'ready') then return end
        if type(payload)=='table' and (payload.cohort=='keyboard' or payload.cohort=='touch' or payload.cohort=='gamepad') then
            player:SetAttribute('InputCohort',payload.cohort)
        end
        readySnapshot(player)
    end)
    Remotes.Get('EquipPersona').OnServerEvent:Connect(function(player,payload)
        if takeToken(player,'loadout') then HubService.EquipPersona(player,payload) end
    end)
    Remotes.Get('ReturnToHub').OnServerEvent:Connect(function(player)
        if not takeToken(player,'return') then return end
        local st = RunContext.GetState(player)
        if not st or st.phase == 'Closing' or st.phase == 'Loading' then return end
        if st.runActive then FunnelService.Mark(player,'run_abandon',{stage=st.stageId,reason='return_to_hub'}) end
        st.items = {}; st.runTurtlesRescued = 0; st.hp = Constants.BASE_HP
        RunContext.ComputeStats(st)
        StageFlowService.LoadHub(player)
    end)
    Remotes.Get('DismissCredits').OnServerEvent:Connect(function(player)
        if not takeToken(player,'credits') then reject(player,'DismissCredits','Please wait a moment and retry.'); return end
        local st = RunContext.GetState(player)
        if not st or st.phase~='Ending' or not st.completionCommitted then
            reject(player,'DismissCredits','The ending is no longer active.'); RunContext.PushState(player); return
        end
        StageFlowService.LoadHub(player)
        Remotes.Get('CommandResult'):FireClient(player,{command='DismissCredits',accepted=true})
    end)
    Remotes.Get('ReplayTutorial').OnServerEvent:Connect(function(player)
        if not takeToken(player,'tutorial_replay') then return end
        local st=RunContext.GetState(player)
        if st and st.inHub then st.tutorial=TutorialService.NewFlags(); TutorialService.OnHubLoaded(player,st.tutorial) end
    end)
    task.spawn(function()
        local lastMetrics = 0
        while true do
            task.wait(0.05)
            for _, player in Players:GetPlayers() do
                local stH = RunContext.GetState(player)
                if not stH or not SessionService.IsOwner(player) or stH.phase == 'Closing' or stH.phase == 'Recovering' then continue end
                local started = os.clock()
                local ok, err = pcall(function()
                    local current = RunContext.GetState(player)
                    if current ~= stH then return false end
                    local ctx = {runActive=stH.runActive,stageId=stH.stageId,stageIndex=stH.stageIndex,checkpointX=stH.checkpointX,moveSpeed=stH.moveSpeed}
                    HazardService.Tick(player,ctx,CombatFacade.ApplyDamageToPlayer,RunContext.Toast)
                    if RunContext.GetState(player) == stH and stH.characterReady and (stH.inHub or stH.runActive) then
                        TutorialService.Observe(player,stH.tutorial,stH.inHub)
                    end
                    stH.checkpointX=ctx.checkpointX
                    RunContext.ApplyCharacterSpeed(player)
                    if RunContext.GetState(player) == stH and stH.runActive then
                        StageFlowService.TickWaves(player)
                        StageFlowService.TryColdOnePickup(player)
                    end
                    return true
                end)
                player:SetAttribute('SimulationStepMs',(os.clock()-started)*1000)
                RuntimeMetrics.Step(os.clock()-started)
                if not ok then
                    local now=os.clock()
                    if now-(simulationErrors[player] or -math.huge)>10 then warn('[Florida Man] Simulation failed: '..tostring(err)); simulationErrors[player]=now end
                    stH.runActive=false; stH.phase='Recovering'; player:SetAttribute('RunActive',false)
                    RunContext.Say(player,'This run encountered a problem. Return to the bonfire to recover.','Recovery')
                    RunContext.PushState(player)
                end
                if os.clock()-lastMetrics >= 1 then FunnelService.WatchSoftlocks(player) end
            end
            if os.clock()-lastMetrics >= 1 then lastMetrics=os.clock() end
        end
    end)
end

Players.PlayerRemoving:Connect(function(player)
    clientReady[player]=nil
    combatBuckets[player]=nil
    replyBuckets[player]=nil
    if not initialized[player] then return end
    local state = RunContext.GetState(player)
    if state then
        RunContext.PersistMeta(player,state)
        state.phase='Closing'; state.runActive=false
    end
    player:SetAttribute('RunActive',false)
    -- Snapshot before clearing runtime truth; Unload owns bounded final flush.
    MetaService.Unload(player)
    EnemyService.Clear()
    CombatService.ResetPlayer(player)
    SessionService.Release(player)
    RunContext.ClearState(player)
    combatBuckets[player]=nil; clientReady[player]=nil; initialized[player]=nil; simulationErrors[player]=nil
    FunnelService.Unload(player)
end)

return GameService
