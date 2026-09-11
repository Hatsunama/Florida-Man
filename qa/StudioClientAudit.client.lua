--!strict
-- Isolated QA place only. Registers a local command endpoint; no test runs at startup.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or not RunService:IsClient() or game.PlaceId ~= 0 then return end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerScripts = player:WaitForChild("PlayerScripts", 5)
if not playerScripts or playerScripts:FindFirstChild("StudioClientAuditCommand") then return end

local function text(value: string, limit: number): string
	local length = utf8.len(value)
	if not length then return "<invalid UTF-8>" end
	local stop = utf8.offset(value, math.max(0, math.floor(limit)) + 1)
	return if stop then string.sub(value, 1, stop - 1) else value
end

local function scalar(value: any): any
	if typeof(value) == "string" then return text(value, 160) end
	if typeof(value) == "boolean" then return value end
	if typeof(value) == "number" and value == value and math.abs(value) < math.huge then return value end
	return nil
end

local function vector(value: Vector3): any
	return {x = scalar(value.X), y = scalar(value.Y), z = scalar(value.Z)}
end

local function walk(start: Instance, limit: number, visit: (Instance) -> ()): (number, boolean)
	local queue: {Instance} = {start}
	local index, inspected = 1, 0
	local truncated = false
	while index <= #queue and inspected < limit do
		local object = queue[index]
		index += 1
		inspected += 1
		visit(object)
		for _, child in object:GetChildren() do
			if #queue >= limit then truncated = true; break end
			table.insert(queue, child)
		end
	end
	return inspected, truncated or index <= #queue
end

local function liveControllers(): (any, any, any)
	local client = playerScripts:FindFirstChild("Client")
	local controllers = client and client:FindFirstChild("Controllers")
	local shared = ReplicatedStorage:FindFirstChild("Shared")
	assert(controllers and shared, "The live client modules are not available yet.")
	assert(script.Parent == playerScripts, "Client QA must run from the live PlayerScripts.")
	-- This callback was registered by the running LocalScript, not Command Bar require.
	-- Literal paths keep the isolated project's Roblox-aware type analysis intact.
	return require(script.Parent.Client.Controllers.InputController),
		require(script.Parent.Client.Controllers.PresentationState),
		require(ReplicatedStorage.Shared.CharacterGeometry)
end

local function characterSnapshot(): any
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local result: any = {present = char ~= nil}
	if char then
		result.inWorkspace = char:IsDescendantOf(workspace)
		result.name = text(char.Name, 80)
		result.motionResetRevision = scalar(char:GetAttribute("MotionResetRevision"))
		result.sessionGeneration = scalar(char:GetAttribute("SessionGeneration"))
	end
	if root and root:IsA("BasePart") then
		result.position = vector(root.Position)
		result.velocity = vector(root.AssemblyLinearVelocity)
		result.rootSize = vector(root.Size)
		result.rootMotionResetRevision = scalar(root:GetAttribute("MotionResetRevision"))
	end
	if hum then
		result.rig = hum.RigType.Name
		result.health = scalar(hum.Health)
		result.humanoidState = hum:GetState().Name
		result.floorMaterial = hum.FloorMaterial.Name
	end
	return result
end

local function visible(object: GuiObject, playerGui: Instance): boolean
	if object.AbsoluteSize.X <= 0 or object.AbsoluteSize.Y <= 0 then return false end
	local current: Instance? = object
	while current and current ~= playerGui do
		if current:IsA("GuiObject") and not current.Visible then return false end
		if current:IsA("ScreenGui") and not current.Enabled then return false end
		current = current.Parent
	end
	return current == playerGui
end

local function read(): any
	local input, presentation = liveControllers()
	local state = presentation.Get()
	local result: any = {
		ok = true, character = characterSnapshot(), gui = {}, readableText = {},
		state = {}, input = {}, modal = presentation.IsModal(),
		note = "Local snapshot. Visible text candidates are not proof of clipping, occlusion or readability on every device.",
	}
	if typeof(state) == "table" then
		for _, key in {"stageId", "phase", "generation", "stateVersion", "characterReady", "inHub", "runActive", "hp", "weaponId", "activePersona"} do
			result.state[key] = scalar(state[key])
		end
	end
	for _, action in {"move", "jump", "attack", "skill", "dodge"} do
		local ready, cooldown, waiting = input.ActionStatus(action)
		result.input[action] = {available = input.Can(action), ready = ready, cooldown = scalar(cooldown), waiting = waiting}
	end
	local playerGui = player:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		local textOmitted, guiOmitted = 0, 0
		local inspected, truncated = walk(playerGui, 2000, function(object)
			if object:IsA("ScreenGui") then
				if #result.gui < 32 then
					table.insert(result.gui, {name = text(object.Name, 80), enabled = object.Enabled, order = object.DisplayOrder})
				else guiOmitted += 1 end
			end
			if (object:IsA("TextLabel") or object:IsA("TextButton") or object:IsA("TextBox")) and visible(object, playerGui) and object.TextTransparency < 1 then
				if #result.readableText >= 60 then textOmitted += 1; return end
				local value = object.Text
				local ok, content = pcall(function(): any return (object :: any).ContentText end)
				if ok and typeof(content) == "string" then value = content end
				local revealed = object.MaxVisibleGraphemes
				if revealed >= 0 then value = text(value, revealed) end
				if value ~= "" then
					table.insert(result.readableText, {
						name = text(object.Name, 80), content = text(value, 180),
						x = object.AbsolutePosition.X, y = object.AbsolutePosition.Y,
						width = object.AbsoluteSize.X, height = object.AbsoluteSize.Y,
					})
				end
			end
		end)
		result.uiScan = {inspected = inspected, truncated = truncated, textOmitted = textOmitted, guiOmitted = guiOmitted}
	end
	return result
end

local function scanAudio(): any
	local sources: {any} = {}
	local otherClasses: {[string]: number} = {}
	local sourceCount, playing, nonzeroVolume = 0, 0, 0
	local inspected, truncated = walk(game, 8000, function(object)
		if object:IsA("Sound") or object:IsA("AudioPlayer") then
			sourceCount += 1
			local source = object :: any
			if source.IsPlaying then playing += 1 end
			if source.Volume > 0 then nonzeroVolume += 1 end
			if #sources < 32 then
				table.insert(sources, {path = text(object:GetFullName(), 200), className = object.ClassName,
					volume = scalar(source.Volume), isPlaying = source.IsPlaying})
			end
		elseif string.sub(object.ClassName, 1, 5) == "Audio" then
			otherClasses[object.ClassName] = (otherClasses[object.ClassName] or 0) + 1
		end
	end)
	return {ok = true, inspected = inspected, truncated = truncated, sources = sources,
		sourceCount = sourceCount, sourceRecordsOmitted = math.max(0, sourceCount - #sources),
		playing = playing, nonzeroVolume = nonzeroVolume, otherAudioClasses = otherClasses,
		note = "Read-only client instance sample. It does not certify platform voice settings or absence of past/future audio."}
end

local function movementSmoke(): any
	local started = os.clock()
	local deadline = started + 9
	local input: any = nil
	local connections: {RBXScriptConnection} = {}
	local events: {any} = {}
	local dropped = 0
	local currentAction: any = nil
	local watchdog: thread? = nil
	local result: any = {ok = false, completed = false, events = events, actions = {},
		note = "Real Input.Intent smoke only; no native device input, teleport, state patch or reward grant. Server observations match action type/time, not a QA request id; concurrent manual input is indistinguishable. Not full campaign acceptance."}
	local function release()
		if input then
			pcall(function() input.Intent("move", "end", 0, "qa") end)
			pcall(function() input.Intent("jump", "end", nil, "qa") end)
		end
	end
	local ok, failure = pcall(function()
		local presentation: any
		local geometry: any
		input, presentation, geometry = liveControllers()
		local state = presentation.Get()
		assert(typeof(state) == "table" and state.characterReady == true and (state.phase == "Hub" or state.phase == "Active"),
			"Wait for a ready Hub or Active state.")
		assert(input.Can("move") and input.Can("jump"), "Movement/jump are unavailable; close gameplay panels first.")
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		assert(char and root and root:IsA("BasePart") and hum and hum.Health > 0 and root:IsDescendantOf(workspace), "A living ready character is required.")
		local generation, stageId = state.generation, state.stageId
		local function guard()
			assert(os.clock() < deadline, "Client smoke reached its nine-second deadline.")
			assert(RunService:IsStudio() and RunService:IsClient() and game.PlaceId == 0, "Use an unsaved Studio client session.")
			local current = presentation.Get()
			assert(player.Character == char and root:IsDescendantOf(workspace) and hum.Health > 0, "Character changed or died during smoke.")
			assert(current and current.generation == generation and current.stageId == stageId and current.characterReady == true
				and (current.phase == "Hub" or current.phase == "Active") and input.Can("move"), "Live state changed or became unavailable during smoke.")
		end
		local function waitSeconds(seconds: number, observe: (() -> ())?)
			local untilAt = math.min(deadline, os.clock() + seconds)
			while os.clock() < untilAt do
				guard()
				if observe then observe() end
				task.wait(math.min(0.03, untilAt - os.clock()))
			end
			guard()
		end
		local remotes = ReplicatedStorage:FindFirstChild("Remotes")
		local commandResult = remotes and remotes:FindFirstChild("CommandResult")
		local combatEvent = remotes and remotes:FindFirstChild("CombatEvent")
		assert(commandResult and commandResult:IsA("RemoteEvent") and combatEvent and combatEvent:IsA("RemoteEvent"), "Live observation events are unavailable.")
		local function record(entry: any)
			entry.at = math.floor((os.clock() - started) * 1000) / 1000
			entry.during = if currentAction then currentAction.action else "movement/jump"
			if #events < 32 then table.insert(events, entry) else dropped += 1 end
		end
		table.insert(connections, commandResult.OnClientEvent:Connect(function(value)
			if typeof(value) ~= "table" then return end
			local name = value.command
			if name ~= "RequestAttack" and name ~= "RequestSkill" and name ~= "RequestDodge" then return end
			record({channel = "CommandResult", command = name, accepted = scalar(value.accepted), reason = scalar(value.reason)})
			if currentAction and currentAction.command == name then
				currentAction.commandResults += 1
				if value.accepted == true then currentAction.acceptanceObserved = true end
				if value.accepted == false then currentAction.rejectionObserved = true end
			end
		end))
		table.insert(connections, combatEvent.OnClientEvent:Connect(function(value)
			if typeof(value) ~= "table" or (value.kind ~= "attack" and value.kind ~= "skill" and value.kind ~= "dodge") then return end
			record({channel = "CombatEvent", kind = value.kind})
			if currentAction and currentAction.action == value.kind then
				currentAction.combatEvents += 1
				currentAction.acceptanceObserved = true
			end
		end))
		watchdog = task.delay(math.max(0, deadline - os.clock()), release)
		guard()
		result.before = characterSnapshot()
		result.stageId = stageId
		result.generation = generation
		local moveStart = root.Position
		input.Intent("move", "begin", 1, "qa")
		waitSeconds(0.8, nil)
		local moveEnd = root.Position
		input.Intent("move", "end", 0, "qa")
		waitSeconds(0.18, nil)
		result.movement = {start = vector(moveStart), finish = vector(moveEnd), afterRelease = vector(root.Position),
			deltaX = moveEnd.X - moveStart.X, observedRightwardMotion = moveEnd.X - moveStart.X > 0.5}
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {char}
		params.RespectCanCollide = true
		local function grounded(): boolean
			local hit = workspace:Raycast(root.Position, Vector3.new(0, -(geometry.FeetDistance(char, root, hum) + 0.45), 0), params)
			return hit ~= nil and hit.Normal.Y > 0.65 and math.abs(root.AssemblyLinearVelocity.Y) < 4
		end
		assert(grounded(), "Movement ended without stable ground; jump was not attempted.")
		local jumpStart = root.Position.Y
		local apex = jumpStart
		local function observeJump() apex = math.max(apex, root.Position.Y) end
		guard()
		input.Intent("jump", "begin", nil, "qa")
		waitSeconds(0.15, observeJump)
		input.Intent("jump", "end", nil, "qa")
		local landingDeadline = math.min(deadline - 3, os.clock() + 1.8)
		local landed = false
		while os.clock() < landingDeadline do
			guard(); observeJump()
			if apex - jumpStart > 0.5 and grounded() then landed = true; break end
			task.wait(0.03)
		end
		result.jump = {startY = jumpStart, apexY = apex, rise = apex - jumpStart, landed = landed, finish = vector(root.Position)}
		assert(landed, "Jump rise/landing was not observed within the bounded window.")
		local allAttemptedAccepted = true
		local allActionsAccepted = true
		for _, definition in {{action = "attack", command = "RequestAttack"}, {action = "skill", command = "RequestSkill"}, {action = "dodge", command = "RequestDodge"}} do
			guard()
			local action: any = {action = definition.action, command = definition.command, available = input.Can(definition.action),
				intentSubmitted = false, commandResults = 0, combatEvents = 0, acceptanceObserved = false, rejectionObserved = false}
			table.insert(result.actions, action)
			if action.available then
				local ready, cooldown, waiting = input.ActionStatus(definition.action)
				action.locallyReady = ready; action.cooldown = scalar(cooldown); action.waiting = waiting
				currentAction = action
				action.intentSubmitted = true
				input.Intent(definition.action, "begin", nil, "qa")
				waitSeconds(0.7, nil)
				currentAction = nil
				action.outcome = if action.acceptanceObserved and action.rejectionObserved then "mixed-server-observations"
					elseif action.acceptanceObserved then "server-acceptance-observed"
					elseif action.rejectionObserved then "server-rejection-observed" else "intent-only-no-server-confirmation"
				if not action.acceptanceObserved or action.rejectionObserved then allAttemptedAccepted = false end
			else
				action.outcome = "unavailable-no-intent"
			end
			if not action.acceptanceObserved or action.rejectionObserved then allActionsAccepted = false end
		end
		result.after = characterSnapshot()
		result.motionResetStable = result.before.motionResetRevision == result.after.motionResetRevision
		result.allActionsAccepted = allActionsAccepted
		result.completed = true
		result.ok = result.movement.observedRightwardMotion and landed and allAttemptedAccepted and result.motionResetStable
	end)
	release()
	if watchdog then pcall(task.cancel, watchdog) end
	for _, connection in connections do connection:Disconnect() end
	currentAction = nil
	result.eventRecordsDropped = dropped
	result.elapsedSeconds = math.floor((os.clock() - started) * 1000) / 1000
	if not result.after then result.after = characterSnapshot() end
	if not ok then result.ok = false; result.reason = text(tostring(failure), 400) end
	return result
end

local command = Instance.new("BindableFunction")
command.Name = "StudioClientAuditCommand"
local busy = false
command.OnInvoke = function(name: unknown): any
	if not RunService:IsStudio() or not RunService:IsClient() or game.PlaceId ~= 0 then
		return {ok = false, reason = "Use an unsaved Studio client session."}
	end
	if busy then return {ok = false, reason = "A client QA command is already running."} end
	if name ~= "Read" and name ~= "ScanAudio" and name ~= "MovementSmoke" then
		return {ok = false, reason = "Unknown client QA command."}
	end
	busy = true
	local ok, result = pcall(function(): any
		if name == "Read" then return read() end
		if name == "ScanAudio" then return scanAudio() end
		return movementSmoke()
	end)
	busy = false
	return if ok then result else {ok = false, reason = text(tostring(result), 400)}
end
command.Parent = playerScripts
