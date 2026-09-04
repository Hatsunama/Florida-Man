--!strict
--[[ Player a11y / options (client attrs + Meta persist).
	Bools: ShakeEnabled, ColorblindTelegraphs, MuteMaster, MuteSFX, MuteAmbience, ReduceMotion
	TextSpeed: "slow" | "normal" | "instant" (Tagline typewriter)
]]

local Settings = {}

Settings.TEXT_SPEEDS = { "slow", "normal", "instant" }

Settings.TEXT_SPEED_DELAY = {
	slow = 0.055,
	normal = 0.028,
	instant = 0,
}

Settings.DEFAULTS = {
	ShakeEnabled = true,
	ColorblindTelegraphs = false,
	MuteMaster = false,
	MuteSFX = false,
	MuteAmbience = false,
	ReduceMotion = false,
	TextSpeed = "normal",
}

Settings.BOOL_KEYS = {
	"ShakeEnabled",
	"ColorblindTelegraphs",
	"MuteMaster",
	"MuteSFX",
	"MuteAmbience",
	"ReduceMotion",
}

function Settings.IsBoolKey(key: string): boolean
	for _, k in Settings.BOOL_KEYS do
		if k == key then
			return true
		end
	end
	return false
end

function Settings.IsValidTextSpeed(value: string): boolean
	for _, s in Settings.TEXT_SPEEDS do
		if s == value then
			return true
		end
	end
	return false
end

function Settings.GetBool(player: Player, key: string): boolean
	local v = player:GetAttribute(key)
	if typeof(v) == "boolean" then
		return v
	end
	local def = Settings.DEFAULTS[key]
	if typeof(def) == "boolean" then
		return def
	end
	return false
end

function Settings.SetBool(player: Player, key: string, value: boolean)
	player:SetAttribute(key, value)
end

function Settings.GetTextSpeed(player: Player): string
	local v = player:GetAttribute("TextSpeed")
	if typeof(v) == "string" and Settings.IsValidTextSpeed(v) then
		return v
	end
	return "normal"
end

function Settings.SetTextSpeed(player: Player, value: string)
	if Settings.IsValidTextSpeed(value) then
		player:SetAttribute("TextSpeed", value)
	end
end

function Settings.CycleTextSpeed(player: Player): string
	local cur = Settings.GetTextSpeed(player)
	local idx = 1
	for i, s in Settings.TEXT_SPEEDS do
		if s == cur then
			idx = i
			break
		end
	end
	local nextVal = Settings.TEXT_SPEEDS[(idx % #Settings.TEXT_SPEEDS) + 1]
	Settings.SetTextSpeed(player, nextVal)
	return nextVal
end

function Settings.TypewriterDelay(player: Player): number
	local speed = Settings.GetTextSpeed(player)
	return Settings.TEXT_SPEED_DELAY[speed] or 0.028
end

function Settings.IsReduceMotion(player: Player): boolean
	return Settings.GetBool(player, "ReduceMotion")
end

function Settings.EnsureDefaults(player: Player)
	for key, def in Settings.DEFAULTS do
		if player:GetAttribute(key) == nil then
			player:SetAttribute(key, def)
		end
	end
end

function Settings.Toggle(player: Player, key: string): boolean
	local nextVal = not Settings.GetBool(player, key)
	Settings.SetBool(player, key, nextVal)
	return nextVal
end

function Settings.Snapshot(player: Player): {
	ShakeEnabled: boolean,
	ColorblindTelegraphs: boolean,
	MuteMaster: boolean,
	MuteSFX: boolean,
	MuteAmbience: boolean,
	ReduceMotion: boolean,
	TextSpeed: string,
}
	return {
		ShakeEnabled = Settings.GetBool(player, "ShakeEnabled"),
		ColorblindTelegraphs = Settings.GetBool(player, "ColorblindTelegraphs"),
		MuteMaster = Settings.GetBool(player, "MuteMaster"),
		MuteSFX = Settings.GetBool(player, "MuteSFX"),
		MuteAmbience = Settings.GetBool(player, "MuteAmbience"),
		ReduceMotion = Settings.GetBool(player, "ReduceMotion"),
		TextSpeed = Settings.GetTextSpeed(player),
	}
end

return Settings
