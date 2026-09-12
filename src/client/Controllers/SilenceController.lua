--!strict
-- Immutable policy includes Roblox default character sounds on every respawn.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AudioPolicy = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AudioPolicy"))
local SilenceController = {}
local started = false
local tracked: { [Instance]: { RBXScriptConnection } } = {}

local function muteSound(sound: Sound)
	sound.PlayOnRemove = false
	sound.Volume = 0
	if sound.IsPlaying then sound:Stop() end
end

local function suppress(object: Instance)
	local mode = AudioPolicy.GetSuppression(object.ClassName)
	if tracked[object] or mode == "none" then return end
	local connections: { RBXScriptConnection } = {}
	tracked[object] = connections
	local function cleanup()
		for _, connection in connections do connection:Disconnect() end
		tracked[object] = nil
	end
	table.insert(connections, object.Destroying:Connect(cleanup))
	if mode == "remove" then
		-- Defer hierarchy changes until Roblox finishes parenting the new instance.
		-- Pre-mute nested legacy sounds so destruction cannot trigger PlayOnRemove.
		task.defer(function()
			local removed, reason = pcall(function()
				for _, child in object:GetDescendants() do
					if child:IsA("Sound") then muteSound(child) end
				end
				object:Destroy()
			end)
			cleanup()
			if not removed then warn("Unable to suppress audio instance " .. object.ClassName .. ": " .. tostring(reason)) end
		end)
		return
	end
	local function stop()
		if object:IsA("Sound") then
			muteSound(object)
		elseif object:IsA("AudioPlayer") then
			object.Volume = 0
			object.AutoPlay = false
			if object.IsPlaying then object:Stop() end
		elseif object:IsA("SoundGroup") then
			object.Volume = 0
		elseif object:IsA("VideoFrame") then
			object.Volume = 0
		elseif object:IsA("VideoPlayer") then
			object.Volume = 0
		elseif object:IsA("SoundEffect") then
			object.Enabled = false
		end
	end
	local properties: { string } = if mode == "sound" then { "Volume", "Playing", "PlayOnRemove" }
		elseif mode == "player" then { "Volume", "IsPlaying", "AutoPlay" }
		elseif mode == "effect" then { "Enabled" }
		else { "Volume" }
	for _, property in properties do
		table.insert(connections, object:GetPropertyChangedSignal(property):Connect(stop))
	end
	stop()
end
function SilenceController.Start()
	if started then return end
	started = true
	game.DescendantAdded:Connect(suppress)
	for _, object in game:GetDescendants() do suppress(object) end
end
return SilenceController
