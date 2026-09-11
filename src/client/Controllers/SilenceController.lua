--!strict
-- Immutable policy includes Roblox default character sounds on every respawn.
local SilenceController = {}
local started = false
local tracked: { [Instance]: { RBXScriptConnection } } = {}
local function suppress(object: Instance)
	if tracked[object] or (not object:IsA("Sound") and not object:IsA("AudioPlayer")) then return end
	local connections: { RBXScriptConnection } = {}
	tracked[object] = connections
	local function stop()
		pcall(function()
			local source = object :: any
			if source.Volume ~= 0 then source.Volume = 0 end
			if source.IsPlaying then source:Stop() end
		end)
	end
	stop()
	table.insert(connections, object:GetPropertyChangedSignal("Volume"):Connect(stop))
	table.insert(connections, object:GetPropertyChangedSignal(if object:IsA("Sound") then "Playing" else "IsPlaying"):Connect(stop))
	table.insert(connections, object.Destroying:Connect(function()
		for _, connection in connections do connection:Disconnect() end
		tracked[object] = nil
	end))
end
function SilenceController.Start()
	if started then return end
	started = true
	game.DescendantAdded:Connect(suppress)
	for _, object in game:GetDescendants() do suppress(object) end
end
return SilenceController
