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

local STORE_NAME = "FloridaMan_Meta_v1"
local SCHEMA = Constants.META_SCHEMA_VERSION
local memory: { [number]: MetaProfile } = {}
local profiles: { [Player]: MetaProfile } = {}
local dirty: { [Player]: boolean } = {}
local saving: { [Player]: boolean } = {}
local loadWarned: { [number]: boolean } = {}
local runCapturers: { [Player]: () -> () } = {}
local store: any = nil
local storeOk = false
local storeChecked = false

local function defaultProfile(): MetaProfile
	return {
		schemaVersion = SCHEMA,
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
	if typeof(raw.settings) == "table" then
		if typeof(raw.settings.ShakeEnabled) == "boolean" then
			p.settings.ShakeEnabled = raw.settings.ShakeEnabled
		end
		if typeof(raw.settings.ColorblindTelegraphs) == "boolean" then
			p.settings.ColorblindTelegraphs = raw.settings.ColorblindTelegraphs
		end
	end
	-- migrate forward
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
	Settings.SetBool(player, "ShakeEnabled", profile.settings.ShakeEnabled)
	Settings.SetBool(player, "ColorblindTelegraphs", profile.settings.ColorblindTelegraphs)
end

function MetaService.Load(player: Player): MetaProfile
	ensureStore()
	local uid = player.UserId
	local existing = profiles[player]
	local profile = defaultProfile()

	if storeOk and store then
		local ok, data = pcall(function()
			return store:GetAsync(keyFor(uid))
		end)
		if ok then
			profile = sanitize(data)
		else
			warn("[MetaService] GetAsync failed — memory for", player.Name, data)
			toastCloudOffline(player)
			-- Never clobber a fresher in-session / memory profile on cloud read fail
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

	-- Prefer memory session if it looks fresher than cloud (higher stage / sunburn / deaths)
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

	p.settings.ShakeEnabled = Settings.GetBool(player, "ShakeEnabled")
	p.settings.ColorblindTelegraphs = Settings.GetBool(player, "ColorblindTelegraphs")
	profiles[player] = p
	dirty[player] = true
	memory[player.UserId] = p
end

function MetaService.UpdateSettings(player: Player, key: string, value: boolean)
	local p = profiles[player] or defaultProfile()
	if key == "ShakeEnabled" or key == "ColorblindTelegraphs" then
		(p.settings :: any)[key] = value
		Settings.SetBool(player, key, value)
		profiles[player] = p
		dirty[player] = true
	end
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
	p.settings.ShakeEnabled = Settings.GetBool(player, "ShakeEnabled")
	p.settings.ColorblindTelegraphs = Settings.GetBool(player, "ColorblindTelegraphs")
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
		settings = {
			ShakeEnabled = p.settings.ShakeEnabled,
			ColorblindTelegraphs = p.settings.ColorblindTelegraphs,
		},
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

-- MetaService owns PlayerRemoving persistence
Players.PlayerRemoving:Connect(function(player)
	MetaService.Unload(player)
end)

return MetaService
