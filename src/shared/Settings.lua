--!strict
--[[ Phase 5 accessibility / player settings (client-local + player attributes).
	ShakeEnabled — screen shake on/off (CameraController reads player attr)
	ColorblindTelegraphs — stripe/pattern on telegraph Parts (EnemyService reads)
]]

local Settings = {}

Settings.DEFAULTS = {
	ShakeEnabled = true,
	ColorblindTelegraphs = false,
}

function Settings.GetBool(player: Player, key: string): boolean
	local v = player:GetAttribute(key)
	if typeof(v) == "boolean" then
		return v
	end
	local def = Settings.DEFAULTS[key]
	if typeof(def) == "boolean" then
		return def
	end
	return true
end

function Settings.SetBool(player: Player, key: string, value: boolean)
	player:SetAttribute(key, value)
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

return Settings
