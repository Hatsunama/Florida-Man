--!strict
--[[ Phase 6 — persistent meta profile (DataStore + Studio/local memory fallback).

	Persists: deaths, sunburn, unlocked persona ids, settings (ShakeEnabled,
	ColorblindTelegraphs), bestStageIndex.

	Load on join; save on death / hub return / leave / settings sync.
]]

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Settings"))

local MetaService = {}

export type MetaProfile = {
	deaths: number,
	sunburn: number,
	unlockedPersonas: { string },
	bestStageIndex: number,
	settings: {
		ShakeEnabled: boolean,
		ColorblindTelegraphs: boolean,
	},
}

local STORE_NAME = "FloridaMan_Meta_v1"
local memory: { [number]: MetaProfile } = {}
local profiles: { [Player]: MetaProfile } = {}
local store: any = nil
local storeOk = false

local function defaultProfile(): MetaProfile
	return {
		deaths = 0,
		sunburn = 0,
		unlockedPersonas = { "BeachBurnout" },
		bestStageIndex = 0,
		settings = {
			ShakeEnabled = true,
			ColorblindTelegraphs = false,
		},
	}
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function sanitize(raw: any): MetaProfile
	local p = defaultProfile()
	if typeof(raw) ~= "table" then
		return p
	end
	if typeof(raw.deaths) == "number" then
		p.deaths = math.max(0, math.floor(raw.deaths))
	end
	if typeof(raw.sunburn) == "number" then
		p.sunburn = math.max(0, math.floor(raw.sunburn))
	end
	if typeof(raw.bestStageIndex) == "number" then
		p.bestStageIndex = math.clamp(math.floor(raw.bestStageIndex), 0, 20)
	end
	if typeof(raw.unlockedPersonas) == "table" then
		local ids = {}
		local seen = {}
		for _, id in raw.unlockedPersonas do
			if typeof(id) == "string" and not seen[id] then
				seen[id] = true
				table.insert(ids, id)
			end
		end
		if not seen.BeachBurnout then
			table.insert(ids, 1, "BeachBurnout")
		end
		p.unlockedPersonas = ids
	end
	if typeof(raw.settings) == "table" then
		if typeof(raw.settings.ShakeEnabled) == "boolean" then
			p.settings.ShakeEnabled = raw.settings.ShakeEnabled
		end
		if typeof(raw.settings.ColorblindTelegraphs) == "boolean" then
			p.settings.ColorblindTelegraphs = raw.settings.ColorblindTelegraphs
		end
	end
	return p
end

local function ensureStore()
	if store ~= nil or storeOk then
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok and result then
		store = result
		storeOk = true
	else
		store = nil
		storeOk = false
		warn("[MetaService] DataStore unavailable — using memory fallback (", result, ")")
	end
end

function MetaService.IsUsingDataStore(): boolean
	ensureStore()
	return storeOk and store ~= nil
end

function MetaService.Get(player: Player): MetaProfile
	local p = profiles[player]
	if p then
		return p
	end
	return defaultProfile()
end

function MetaService.ApplySettingsAttrs(player: Player, profile: MetaProfile)
	Settings.SetBool(player, "ShakeEnabled", profile.settings.ShakeEnabled)
	Settings.SetBool(player, "ColorblindTelegraphs", profile.settings.ColorblindTelegraphs)
end

function MetaService.Load(player: Player): MetaProfile
	ensureStore()
	local profile = defaultProfile()
	local uid = player.UserId
	if storeOk and store then
		local ok, data = pcall(function()
			return store:GetAsync(keyFor(uid))
		end)
		if ok then
			profile = sanitize(data)
		else
			warn("[MetaService] GetAsync failed — memory for", player.Name, data)
			if memory[uid] then
				profile = sanitize(memory[uid])
			end
		end
	else
		if memory[uid] then
			profile = sanitize(memory[uid])
		end
	end
	profiles[player] = profile
	MetaService.ApplySettingsAttrs(player, profile)
	return profile
end

function MetaService.CaptureFromRun(
	player: Player,
	deaths: number,
	sunburn: number,
	unlockedMap: { [string]: boolean },
	stageIndex: number?
)
	local p = profiles[player] or defaultProfile()
	p.deaths = math.max(0, math.floor(deaths))
	p.sunburn = math.max(0, math.floor(sunburn))
	local ids = { "BeachBurnout" }
	local seen = { BeachBurnout = true }
	for id, on in unlockedMap do
		if on and typeof(id) == "string" and not seen[id] then
			seen[id] = true
			table.insert(ids, id)
		end
	end
	p.unlockedPersonas = ids
	if typeof(stageIndex) == "number" and stageIndex > p.bestStageIndex then
		p.bestStageIndex = math.clamp(math.floor(stageIndex), 0, 20)
	end
	-- pull live settings attrs (server-owned after SyncSettings / Load)
	p.settings.ShakeEnabled = Settings.GetBool(player, "ShakeEnabled")
	p.settings.ColorblindTelegraphs = Settings.GetBool(player, "ColorblindTelegraphs")
	profiles[player] = p
end

function MetaService.UpdateSettings(player: Player, key: string, value: boolean)
	local p = profiles[player] or defaultProfile()
	if key == "ShakeEnabled" or key == "ColorblindTelegraphs" then
		(p.settings :: any)[key] = value
		Settings.SetBool(player, key, value)
		profiles[player] = p
	end
end

function MetaService.Save(player: Player): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	-- refresh settings from attrs before write
	p.settings.ShakeEnabled = Settings.GetBool(player, "ShakeEnabled")
	p.settings.ColorblindTelegraphs = Settings.GetBool(player, "ColorblindTelegraphs")
	local uid = player.UserId
	memory[uid] = p
	ensureStore()
	if not (storeOk and store) then
		return true -- memory OK (Studio / offline)
	end
	local payload = {
		deaths = p.deaths,
		sunburn = p.sunburn,
		unlockedPersonas = p.unlockedPersonas,
		bestStageIndex = p.bestStageIndex,
		settings = {
			ShakeEnabled = p.settings.ShakeEnabled,
			ColorblindTelegraphs = p.settings.ColorblindTelegraphs,
		},
	}
	local ok, err = pcall(function()
		store:SetAsync(keyFor(uid), payload)
	end)
	if not ok then
		warn("[MetaService] SetAsync failed:", err)
		return false
	end
	return true
end

function MetaService.Unload(player: Player)
	MetaService.Save(player)
	profiles[player] = nil
end

-- Studio note: ApiServicesEnabled / published place required for real DataStore.
if RunService:IsStudio() then
	-- keep quiet; fallback is intentional for local Rojo
end

Players.PlayerRemoving:Connect(function(player)
	-- GameService also saves; belt-and-suspenders
	if profiles[player] then
		MetaService.Unload(player)
	end
end)

return MetaService
