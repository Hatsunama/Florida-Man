--!strict
-- Pure schema rules. No provider, Player, clock, presentation, or game dependency.
local Rules = {}
Rules.SCHEMA = 3

function Rules.Clone(value: any): any
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, child in value do copy[key] = Rules.Clone(child) end
	return copy
end

function Rules.Freeze(value: any): any
	if type(value) ~= "table" then return value end
	for _, child in value do Rules.Freeze(child) end
	return table.freeze(value)
end

function Rules.Equal(a: any, b: any): boolean
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for key, value in a do if not Rules.Equal(value, b[key]) then return false end end
	for key in b do if a[key] == nil then return false end end
	return true
end

function Rules.Number(value: any, default: number, maximum: number): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then return default end
	return math.clamp(math.floor(value), 0, maximum)
end

local function ids(raw: any, allowed: any, starters: {string}): {string}
	local out, seen = {}, {}
	for _, id in starters do seen[id] = true; table.insert(out, id) end
	if type(raw) == "table" then
		-- Known catalogs bound the result; both legacy arrays and runtime sets migrate.
		for _, id in allowed do
			local found = raw[id] == true
			for i = 1, #allowed do if raw[i] == id then found = true; break end end
			if found and not seen[id] then seen[id] = true; table.insert(out, id) end
		end
	end
	return out
end

function Rules.Default(config: any): any
	return {
		schemaVersion = Rules.SCHEMA, deaths = 0, sunburn = 0, bestStageIndex = 0,
		totalTurtlesRescued = 0, unlockedPersonas = {"BeachBurnout"},
		personaRarity = {BeachBurnout = "Common"}, personas = {"BeachBurnout"},
		unlockedWeapons = {"BareHands", "FlipFlopSlap"}, weaponId = "BareHands",
		settings = Rules.Clone(config.settings),
	}
end

function Rules.Normalize(raw: any, config: any): (any?, string?)
	if type(raw) ~= "table" then return nil, "invalid-data" end
	local version = raw.schemaVersion
	if version ~= nil then
		if type(version) ~= "number" or version ~= version or version < 1 or version % 1 ~= 0 then
			return nil, "invalid-version"
		end
		if version > Rules.SCHEMA then return nil, "incompatible-version" end
	end
	local p = Rules.Default(config)
	p.deaths = Rules.Number(raw.deaths, 0, 10000000)
	p.sunburn = Rules.Number(raw.sunburn, 0, 1000000000)
	p.bestStageIndex = Rules.Number(raw.bestStageIndex, 0, 20)
	p.totalTurtlesRescued = Rules.Number(raw.totalTurtlesRescued, 0, 1000000000)
	p.unlockedPersonas = ids(raw.unlockedPersonas, config.personas, {"BeachBurnout"})
	p.personaRarity = {}
	for _, id in p.unlockedPersonas do
		local rarity = if type(raw.personaRarity) == "table" then raw.personaRarity[id] else nil
		p.personaRarity[id] = if table.find({"Common", "Rare", "Unique", "Legendary"}, rarity) then rarity else "Common"
	end
	p.personas = {}
	if type(raw.personas) == "table" then
		for slot = 1, 2 do
			local id = raw.personas[slot]
			if type(id) == "string" and table.find(p.unlockedPersonas, id) and not table.find(p.personas, id) then
				table.insert(p.personas, id)
			end
		end
	end
	if #p.personas == 0 then p.personas = {"BeachBurnout"} end
	p.unlockedWeapons = ids(raw.unlockedWeapons, config.weapons, {"BareHands", "FlipFlopSlap"})
	p.weaponId = if type(raw.weaponId) == "string" and table.find(p.unlockedWeapons, raw.weaponId) then raw.weaponId else "BareHands"
	if type(raw.settings) == "table" then
		for key, default in config.settings do
			if type(default) == "boolean" and type(raw.settings[key]) == "boolean" then p.settings[key] = raw.settings[key] end
		end
		if table.find({"slow", "normal", "instant"}, raw.settings.TextSpeed) then p.settings.TextSpeed = raw.settings.TextSpeed end
	end
	-- Unknown fields (including retired audio preferences) are deliberately omitted.
	return p, nil
end

return Rules
