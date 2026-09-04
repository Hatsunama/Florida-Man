--!strict

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Settings"))
local Types = require(Shared:WaitForChild("Types"))
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local MetaService = {}

export type MetaProfile = Types.MetaProfile

local STORE_NAME = "FloridaMan_Meta_v2"
local LEGACY_STORE_NAME = "FloridaMan_Meta_v1"
local SCHEMA = Constants.META_SCHEMA_VERSION
local memory: { [number]: MetaProfile } = {}
local profiles: { [Player]: MetaProfile } = {}
local dirty: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local loadWarned: { [number]: boolean } = {}
local runCapturers: { [Player]: () -> () } = {}
local store: any = nil
local legacyStore: any = nil
local storeOk = false
local storeChecked = false

local function defaultSettings()
	return {
		ShakeEnabled = true,
		ColorblindTelegraphs = false,
		MuteMaster = false,
		MuteSFX = false,
		MuteAmbience = false,
		ReduceMotion = false,
		TextSpeed = "normal",
	}
end

local function defaultProfile(): MetaProfile
	return {
		schemaVersion = SCHEMA,
		deaths = 0,
		sunburn = 0,
		unlockedPersonas = { "BeachBurnout" },
		bestStageIndex = 0,
		settings = defaultSettings(),
	}
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

local function sanitizeSettings(raw: any): typeof(defaultSettings())
	local s = defaultSettings()
	if typeof(raw) ~= "table" then
		return s
	end
	for _, key in Settings.BOOL_KEYS do
		if typeof(raw[key]) == "boolean" then
			(s :: any)[key] = raw[key]
		end
	end
	if typeof(raw.TextSpeed) == "string" and Settings.IsValidTextSpeed(raw.TextSpeed) then
		s.TextSpeed = raw.TextSpeed
	end
	return s
end

local function sanitize(raw: any): MetaProfile
	local p = defaultProfile()
	if typeof(raw) ~= "table" then
		return p
	end
	if typeof(raw.schemaVersion) == "number" then
		p.schemaVersion = math.max(1, math.floor(raw.schemaVersion))
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
	p.settings = sanitizeSettings(raw.settings)
	-- migrate forward to current schema
	p.schemaVersion = SCHEMA
	return p
end

local function ensureStore()
	if storeChecked then
		return
	end
	storeChecked = true
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
	local okL, leg = pcall(function()
		return DataStoreService:GetDataStore(LEGACY_STORE_NAME)
	end)
	if okL and leg then
		legacyStore = leg
	end
end

local function toastCloudOffline(player: Player)
	local uid = player.UserId
	if loadWarned[uid] then
		return
	end
	loadWarned[uid] = true
	task.defer(function()
		if player.Parent then
			pcall(function()
				Remotes.Get("Toast"):FireClient(player, "Cloud save offline — progress kept for this session.")
			end)
		end
	end)
end

local function readCloud(uid: number): (boolean, any)
	ensureStore()
	if not (storeOk and store) then
		return false, nil
	end
	local ok, data = pcall(function()
		return store:GetAsync(keyFor(uid))
	end)
	if ok and data ~= nil then
		return true, data
	end
	-- Schema v2 migrate: pull v1 payload when v2 empty
	if legacyStore then
		local okL, legacy = pcall(function()
			return legacyStore:GetAsync(keyFor(uid))
		end)
		if okL and legacy ~= nil then
			return true, legacy
		end
	end
	if ok then
		return true, nil
	end
	return false, data
end

function MetaService.IsUsingDataStore(): boolean
	ensureStore()
	return storeOk and store ~= nil
end

function MetaService.IsDirty(player: Player): boolean
	return dirty[player] == true
end

function MetaService.MarkDirty(player: Player)
	if profiles[player] then
		dirty[player] = true
	end
end

function MetaService.RegisterRunCapturer(player: Player, fn: () -> ())
	runCapturers[player] = fn
end

function MetaService.ClearRunCapturer(player: Player)
	runCapturers[player] = nil
end

function MetaService.Get(player: Player): MetaProfile
	local p = profiles[player]
	if p then
		return p
	end
	return defaultProfile()
end

function MetaService.ApplySettingsAttrs(player: Player, profile: MetaProfile)
	local s = profile.settings
	for _, key in Settings.BOOL_KEYS do
		Settings.SetBool(player, key, (s :: any)[key] == true)
	end
	Settings.SetTextSpeed(player, s.TextSpeed or "normal")
end

function MetaService.Load(player: Player): MetaProfile
	ensureStore()
	local uid = player.UserId
	local existing = profiles[player]
	local profile = defaultProfile()

	if storeOk and store then
		local ok, data = readCloud(uid)
		if ok then
			if data ~= nil then
				profile = sanitize(data)
			end
		else
			warn("[MetaService] GetAsync failed — memory for", player.Name, data)
			toastCloudOffline(player)
			if existing then
				profile = existing
			elseif memory[uid] then
				profile = sanitize(memory[uid])
			end
		end
	else
		toastCloudOffline(player)
		if existing then
			profile = existing
		elseif memory[uid] then
			profile = sanitize(memory[uid])
		end
	end

	if memory[uid] then
		local mem = sanitize(memory[uid])
		if mem.bestStageIndex > profile.bestStageIndex
			or mem.sunburn > profile.sunburn
			or mem.deaths > profile.deaths
		then
			profile = mem
		end
	end

	profiles[player] = profile
	dirty[player] = false
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
	p.schemaVersion = SCHEMA
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

	p.settings = Settings.Snapshot(player)
	profiles[player] = p
	dirty[player] = true
	memory[player.UserId] = p
end

function MetaService.UpdateSettings(player: Player, key: string, value: boolean | string)
	local p = profiles[player] or defaultProfile()
	if Settings.IsBoolKey(key) and typeof(value) == "boolean" then
		(p.settings :: any)[key] = value
		Settings.SetBool(player, key, value)
		profiles[player] = p
		dirty[player] = true
	elseif key == "TextSpeed" and typeof(value) == "string" and Settings.IsValidTextSpeed(value) then
		p.settings.TextSpeed = value
		Settings.SetTextSpeed(player, value)
		profiles[player] = p
		dirty[player] = true
	end
end

local function settingsPayload(s: any): any
	return {
		ShakeEnabled = s.ShakeEnabled == true,
		ColorblindTelegraphs = s.ColorblindTelegraphs == true,
		MuteMaster = s.MuteMaster == true,
		MuteSFX = s.MuteSFX == true,
		MuteAmbience = s.MuteAmbience == true,
		ReduceMotion = s.ReduceMotion == true,
		TextSpeed = if typeof(s.TextSpeed) == "string" and Settings.IsValidTextSpeed(s.TextSpeed)
			then s.TextSpeed
			else "normal",
	}
end

function MetaService.Save(player: Player, force: boolean?): boolean
	local p = profiles[player]
	if not p then
		return false
	end
	if saving[player] then
		return false
	end
	if not force and not dirty[player] then
		return true
	end

	saving[player] = true
	p.schemaVersion = SCHEMA
	p.settings = Settings.Snapshot(player)
	local uid = player.UserId
	memory[uid] = p
	ensureStore()
	if not (storeOk and store) then
		dirty[player] = false
		saving[player] = false
		return true
	end
	local payload = {
		schemaVersion = p.schemaVersion,
		deaths = p.deaths,
		sunburn = p.sunburn,
		unlockedPersonas = p.unlockedPersonas,
		bestStageIndex = p.bestStageIndex,
		settings = settingsPayload(p.settings),
	}
	local ok, err = pcall(function()
		store:SetAsync(keyFor(uid), payload)
	end)
	saving[player] = false
	if not ok then
		warn("[MetaService] SetAsync failed:", err)
		toastCloudOffline(player)
		return false
	end
	dirty[player] = false
	return true
end

function MetaService.Unload(player: Player)
	local cap = runCapturers[player]
	if cap then
		pcall(cap)
	end
	if profiles[player] then
		MetaService.Save(player, true)
	end
	profiles[player] = nil
	dirty[player] = nil
	saving[player] = nil
	runCapturers[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
	MetaService.Unload(player)
end)

return MetaService
