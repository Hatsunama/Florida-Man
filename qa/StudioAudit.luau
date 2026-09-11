--!strict
-- Manual server-command-bar helpers. This module is absent from the default project.
-- Requiring it does not run an audit, reset a stage, create remotes, or change settings.
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Audit = {}
export type CommandResult = { ok: boolean, reason: string, stageId: string? }

function Audit.ListStages(): { { id: string, index: number, name: string, isHub: boolean } }
	local Stages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stages"))
	local result = {}
	for _, stage in Stages.List do
		table.insert(result, { id = stage.id, index = stage.index, name = stage.name, isHub = stage.isHub })
	end
	table.sort(result, function(a, b) return a.index < b.index end)
	return result
end

local function mutationPlayer(requested: Player?): (Player?, string)
	if not RunService:IsStudio() or not RunService:IsServer() then return nil, "Use the Studio server session." end
	if game.PlaceId ~= 0 then return nil, "Use an unsaved local place with PlaceId 0." end
	local server = ServerScriptService:WaitForChild("Server")
	local Session = require(server:WaitForChild("SessionService"))
	local Meta = require(server:WaitForChild("MetaService"))
	local RunContext = require(server:WaitForChild("RunContext"))
	local player = requested
	if not player then
		for _, candidate in Players:GetPlayers() do
			if Session.IsOwner(candidate) then player = candidate; break end
		end
	end
	if not player or not Session.IsOwner(player) then return nil, "No admitted session owner is ready." end
	local status = Meta.GetStatus(player)
	if status.writable ~= false or status.state == "loading" then return nil, "Profile must be loaded without write access." end
	local state = RunContext.GetState(player)
	if not state or not state.characterReady then return nil, "Wait for the admitted character to become ready." end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return nil, "A living admitted character is required." end
	return player, "Ready."
end

function Audit.ResetToStage(stageId: string, requested: Player?): CommandResult
	local player, reason = mutationPlayer(requested)
	if not player then return { ok = false, reason = reason } end
	local Stages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stages"))
	local stage = Stages.Get(stageId)
	if not stage then return { ok = false, reason = "Unknown stage id." } end
	local server = ServerScriptService:WaitForChild("Server")
	local StageFlow = require(server:WaitForChild("StageFlowService"))
	local Hub = require(server:WaitForChild("HubService"))
	local RunContext = require(server:WaitForChild("RunContext"))
	local ok, failure = pcall(function()
		local previous = RunContext.GetState(player)
		StageFlow.LoadHub(player)
		Hub.StartRun(player)
		local fresh = RunContext.GetState(player)
		assert(fresh and fresh ~= previous and fresh.runActive, "The normal fresh-run transition did not complete.")
		if stage.isHub then
			StageFlow.LoadHub(player)
		elseif fresh.stageId ~= stage.id then
			StageFlow.LoadStage(player, stage.id)
		end
		return true
	end)
	if not ok then return { ok = false, reason = string.sub(tostring(failure), 1, 240) } end
	return { ok = true, reason = "Fresh run loaded: run items and completion ledgers reset; persistent loadout retained.", stageId = stage.id }
end

function Audit.NearCaptainSteve(): any
	local player,reason=mutationPlayer(nil)
	if not player then return {ok=false,reason=reason} end
	local Context=require(ServerScriptService:WaitForChild('Server'):WaitForChild('RunContext'))
	local state=Context.GetState(player)
	if not state or not state.inHub then return {ok=false,reason='Return to the hub first.'} end
	local world=workspace:FindFirstChild('GameWorld')
	local steve=world and world:FindFirstChild('CaptainSteve',true)
	if not steve or not steve:IsA('BasePart') then return {ok=false,reason='Captain Steve is absent.'} end
	Context.TeleportPlayer(player,CFrame.new(steve.Position.X,5,0))
	return {ok=true,note='Explicit QA relocation only; press E normally to test the NPC.'}
end

local trace: any=nil
local traceConnections: {RBXScriptConnection}={}
local function stopTrace()
	for _,connection in traceConnections do connection:Disconnect() end
	table.clear(traceConnections)
end
function Audit.BeginTrace(): any
	local player,reason=mutationPlayer(nil)
	if not player then return {ok=false,reason=reason} end
	stopTrace()
	local char=player.Character :: Model
	local root=char:FindFirstChild('HumanoidRootPart') :: BasePart
	local start=os.clock()
	local revision=(char:GetAttribute('MotionResetRevision') :: number?) or 0
	trace={ok=true,seconds=0,samples=0,x0=root.Position.X,y0=root.Position.Y,x=root.Position.X,y=root.Position.Y,
		minX=root.Position.X,maxX=root.Position.X,maxY=root.Position.Y,resets=0,commands={}}
	local current=trace
	local remotes=ReplicatedStorage:WaitForChild('Remotes')
	for _,name in {'RequestAttack','RequestSkill','RequestSwap','RequestDodge'} do
		local remote=remotes:FindFirstChild(name)
		if remote and remote:IsA('RemoteEvent') then
			table.insert(traceConnections,remote.OnServerEvent:Connect(function(sender: Player)
				if sender==player then current.commands[name]=(current.commands[name] or 0)+1 end
			end))
		end
	end
	table.insert(traceConnections,RunService.Heartbeat:Connect(function()
		if player.Character~=char or not root.Parent or os.clock()-start>30 then stopTrace(); return end
		local p=root.Position
		current.seconds=os.clock()-start; current.samples+=1; current.x=p.X; current.y=p.Y
		current.minX=math.min(current.minX,p.X); current.maxX=math.max(current.maxX,p.X); current.maxY=math.max(current.maxY,p.Y)
		current.resets=((char:GetAttribute('MotionResetRevision') :: number?) or revision)-revision
	end))
	return {ok=true,note='Thirty-second bounded server trace armed. Commands count receipt, not accepted damage.'}
end
function Audit.Trace(): any
	return trace or {ok=false,reason='No trace recorded.'}
end

function Audit.RunLifecycleSmoke(): any
	local player,reason=mutationPlayer(nil)
	if not player then return {ok=false,reason=reason} end
	local server=ServerScriptService:WaitForChild('Server')
	local Context=require(server:WaitForChild('RunContext'))
	local Combat=require(server:WaitForChild('CombatFacade'))
	local results={}
	for index=1,3 do
		local reset=Audit.ResetToStage('DaytonaHangover',player)
		if not reset.ok then return reset end
		local previous=player.Character
		local before=Context.GetState(player)
		assert(before,'Run missing before death')
		local deaths=before.deaths
		if index==2 then
			local hum=previous and previous:FindFirstChildOfClass('Humanoid')
			assert(hum,'Humanoid missing before reset')
			hum.Health=0
		else Combat.ApplyDamageToPlayer(player,100000) end
		local deathDeadline=os.clock()+2
		repeat
			task.wait(0.05)
			local observed=Context.GetState(player)
			if observed and observed.deaths==deaths+1 then break end
		until os.clock()>deathDeadline
		local observed=Context.GetState(player)
		if not observed or observed.deaths~=deaths+1 then
			return {ok=false,cycles=results,cycle=index,reason='Actual damage/death callback did not count the death; duplicate-callback probe was not run.'}
		end
		Combat.KillPlayer(player) -- a repeated callback must not double-count death
		local deadline=os.clock()+12
		repeat
			task.wait(0.1)
			local current=Context.GetState(player)
			if current and current.characterReady and current.inHub and (index~=2 or player.Character~=previous) then break end
		until os.clock()>deadline
		local after=Context.GetState(player)
		local ok=after~=nil and after.characterReady and after.inHub and after.deaths==deaths+1 and (index~=2 or player.Character~=previous)
		table.insert(results,{cycle=index,kind=if index==2 then 'humanoid-reset' else 'combat-death',ok=ok,phase=if after then after.phase else 'missing',deaths=if after then after.deaths else -1})
		if not ok then return {ok=false,cycles=results,reason='Death/recovery did not finish exactly once within twelve seconds.'} end
	end
	return {ok=true,cycles=results,note='Real damage, death and respawn callbacks; not persistence rejoin evidence.'}
end

local function boundedCopy(value: any, depth: number, budget: { left: number }): any
	if type(value) == "number" then
		return if value == value and math.abs(value) < math.huge then value else "non-finite"
	end
	if type(value) == "string" then return string.sub(value, 1, 240) end
	if type(value) == "boolean" or value == nil then return value end
	if type(value) ~= "table" then return "unsupported value" end
	if depth == 0 or budget.left <= 0 then return "truncated" end
	local result: { [string]: any } = {}
	for key, item in value do
		if budget.left <= 0 then result.truncated = true; break end
		budget.left -= 1
		result[string.sub(tostring(key), 1, 80)] = boundedCopy(item, depth - 1, budget)
	end
	return result
end

function Audit.Snapshot(): any
	local RuntimeMetrics = require(ServerScriptService:WaitForChild("Server"):WaitForChild("RuntimeMetrics"))
	local latest = RuntimeMetrics.GetLatest()
	return { available = latest ~= nil, metrics = boundedCopy(latest, 5, { left = 160 }),
		note = "Latest server sample only; no client frame time or playtest success is inferred." }
end

function Audit.ScanAudio(maxNodes: number?): any
	local limit = math.clamp(math.floor(maxNodes or 8000), 100, 20000)
	local queue: { Instance } = { game }
	local findings: { { path: string, className: string } } = {}
	local index, inspected = 1, 0
	local truncated = false
	while index <= #queue and inspected < limit and #findings < 32 do
		local object = queue[index]
		index += 1
		inspected += 1
		if object:IsA("Sound") or string.sub(object.ClassName, 1, 5) == "Audio" then
			table.insert(findings, { path = string.sub(object:GetFullName(), 1, 240), className = object.ClassName })
		end
		for _, child in object:GetChildren() do
			if #queue >= limit then truncated = true; break end
			table.insert(queue, child)
		end
	end
	return { inspected = inspected, findings = findings, truncated = truncated or index <= #queue,
		note = "Read-only server instance scan; client-only audio must be checked on the client." }
end

-- Engine integration evidence only. This does not simulate player skill, input,
-- traversal, or a normal campaign; it exercises the real lifecycle services.
function Audit.RunStageSmoke(): any
	local player, reason = mutationPlayer(nil)
	if not player then return {ok=false,reason=reason} end
	local server=ServerScriptService:WaitForChild('Server')
	local Context=require(server:WaitForChild('RunContext'))
	local Flow=require(server:WaitForChild('StageFlowService'))
	local Enemy=require(server:WaitForChild('EnemyService'))
	local Stages=require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('Stages'))
	local results={}
	local passed=true
	for _, stage in Stages.List do
		if stage.isHub then continue end
		local record: any={stage=stage.id,ok=false}
		local ok, failure=pcall(function()
			local reset=Audit.ResetToStage(stage.id,player)
			assert(reset.ok,reset.reason)
			task.wait(0.15)
			local state=Context.GetState(player)
			assert(state and state.stageId==stage.id and state.phase=='Active' and state.characterReady,'Stage failed to become active and ready')
			local character=player.Character
			local root=character and character:FindFirstChild('HumanoidRootPart')
			assert(root and root:IsA('BasePart') and root:IsDescendantOf(workspace),'Character root missing from world')
			local ray=RaycastParams.new()
			ray.FilterType=Enum.RaycastFilterType.Exclude
			ray.FilterDescendantsInstances={character :: Model}
			ray.RespectCanCollide=true
			local ground=workspace:Raycast(root.Position,Vector3.new(0,-12,0),ray)
			record.spawnRayHit=if ground then ground.Instance:GetFullName() else 'none'
			record.spawnPosition=tostring(root.Position)
			assert(ground and ground.Instance:IsDescendantOf(workspace.GameWorld),'Spawn has no world support')
			record.spawnSupport=ground.Instance.Name
			record.rescuesRequired=state.turtlesNeeded
			assert(state.turtlesNeeded==stage.rescueTurtles,'Rescue demand disagrees with stage')
			if #stage.waves>0 then
				Flow.FinishStage(player)
				assert(state.phase=='Active','Stage completed before its required waves')
			end
			if stage.coldOnePickup then
				local cold=workspace.GameWorld:FindFirstChild('ColdOne')
				assert(cold and cold:IsA('BasePart'),'Required pickup is missing')
				Context.TeleportPlayer(player,CFrame.new(cold.Position.X,5,0))
				Flow.TryColdOnePickup(player)
				assert(state.coldOneTaken,'Required pickup did not register')
			end
			-- Trigger every real wave/room using authorized server relocations, then
			-- exercise real kill and rescue callbacks. No completion flag is forged.
			for _, progress in {0.35,0.6,0.8,0.99} do
				Context.TeleportPlayer(player,CFrame.new(stage.length*progress,5,0))
				Flow.TickWaves(player)
				for _=1,16 do
					for _, model in Enemy.GetAlive() do
						if not model:GetAttribute('IsAlly') then Enemy.ApplyDamage(model,100000,player,0,false) end
					end
					if Enemy.GetOutstandingCount()==0 then break end
					task.wait(0.12)
				end
				Flow.TickWaves(player)
			end
			for _, model in Enemy.GetAlive() do
				if model:GetAttribute('IsAlly') and model.PrimaryPart then
					Context.TeleportPlayer(player,CFrame.new(model.PrimaryPart.Position+Vector3.new(0,3,0)))
					assert(Enemy.TryRescue(player,model),'Real rescue callback rejected nearby living player')
				end
			end
			Flow.FinishStage(player)
			assert(state.rewardLedger[stage.id],'Completed requirements did not commit reward')
			local total=state.totalTurtlesRescued
			Flow.FinishStage(player)
			assert(state.totalTurtlesRescued==total,'Repeated completion changed rescue total')
			local completed=Context.GetState(player)
			assert(completed and (completed.phase=='Reward' or completed.phase=='Ending'),'Completion did not enter summary or ending')
			record.phase=completed.phase
			record.rescues=state.turtlesRescued
			record.ok=true
			return true
		end)
		if not ok then passed=false;record.failure=string.sub(tostring(failure),1,400) end
		table.insert(results,record)
		print('QA_STAGE '..game:GetService('HttpService'):JSONEncode(record))
	end
	local restored=Audit.ResetToStage('Hub',player)
	return {ok=passed and restored.ok,stages=results,restored=restored.ok,
		note='Engine service smoke using explicit test relocations and lethal damage. Not input, combat balance, traversal, or normal campaign acceptance.'}
end

return table.freeze(Audit)
