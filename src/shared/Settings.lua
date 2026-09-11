--!strict
local Settings = {}
Settings.TEXT_SPEEDS = { "slow", "normal", "instant" }
Settings.TEXT_SPEED_DELAY = { slow = 0.055, normal = 0.028, instant = 0 }
Settings.DEFAULTS = { ShakeEnabled = true, ColorblindTelegraphs = false, ReduceMotion = false, ReduceFlashes = true, LargeText = false, TextSpeed = "normal" } :: { [string]: any }
Settings.BOOL_KEYS = { "ShakeEnabled", "ColorblindTelegraphs", "ReduceMotion", "ReduceFlashes", "LargeText" }
function Settings.IsBoolKey(key: string): boolean return table.find(Settings.BOOL_KEYS, key) ~= nil end
function Settings.IsValidTextSpeed(value: string): boolean return table.find(Settings.TEXT_SPEEDS, value) ~= nil end
function Settings.GetBool(player: Player, key: string): boolean
	if not Settings.IsBoolKey(key) then return false end
	local value = player:GetAttribute(key)
	return if typeof(value) == "boolean" then value else Settings.DEFAULTS[key] == true
end
function Settings.SetBool(player: Player, key: string, value: boolean)
	if Settings.IsBoolKey(key) then player:SetAttribute(key, value) end
end
function Settings.GetTextSpeed(player: Player): string
	local value = player:GetAttribute("TextSpeed")
	return if typeof(value) == "string" and Settings.IsValidTextSpeed(value) then value else "normal"
end
function Settings.SetTextSpeed(player: Player, value: string)
	if Settings.IsValidTextSpeed(value) then player:SetAttribute("TextSpeed", value) end
end
function Settings.CycleTextSpeed(player: Player): string
	local index = table.find(Settings.TEXT_SPEEDS, Settings.GetTextSpeed(player)) or 2
	local value = Settings.TEXT_SPEEDS[index % #Settings.TEXT_SPEEDS + 1]
	Settings.SetTextSpeed(player, value)
	return value
end
function Settings.TypewriterDelay(player: Player): number return Settings.TEXT_SPEED_DELAY[Settings.GetTextSpeed(player)] or 0 end
function Settings.IsReduceMotion(player: Player): boolean return Settings.GetBool(player, "ReduceMotion") end
function Settings.EnsureDefaults(player: Player)
	for key, value in Settings.DEFAULTS do
		if player:GetAttribute(key) == nil then player:SetAttribute(key, value) end
	end
end
function Settings.Toggle(player: Player, key: string): boolean
	local value = not Settings.GetBool(player, key)
	Settings.SetBool(player, key, value)
	return value
end
function Settings.Snapshot(player: Player): { [string]: any }
	local result: { [string]: any } = { TextSpeed = Settings.GetTextSpeed(player) }
	for _, key in Settings.BOOL_KEYS do result[key] = Settings.GetBool(player, key) end
	return result
end
return Settings
