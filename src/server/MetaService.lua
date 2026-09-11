--!strict
-- Runtime profile owner. Public mutation/Save methods never yield; only Load and
-- the bounded provider worker touch storage. Failed reads never gain write access.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Settings = require(Shared:WaitForChild("Settings"))
local Personas = require(Shared:WaitForChild("Personas"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Types = require(Shared:WaitForChild("Types"))
local Rules = require(script.Parent:WaitForChild("ProfileRules"))
local Adapter = require(script.Parent:WaitForChild("ProfileAdapter"))
local Queue = require(script.Parent:WaitForChild("ProfileQueue"))
local MetaService = {}
export type MetaProfile = Types.MetaProfile

local config = {personas = Personas.AllIds(), weapons = Weapons.AllIds(), settings = {}}
for key, value in Settings.DEFAULTS do
	if string.sub(key, 1, 4) ~= "Mute" then config.settings[key] = value end
end
local records: {[Player]: any} = {}
local capturers: {[Player]: () -> ()} = {}
local adapter: any = nil
local providerError = false
local workers = 0
local stopped = false
local statusObserver: ((Player) -> ())? = nil
local AUTOSAVE_SECONDS = 30
local MIN_WRITE_GAP = 6
local MAX_WORKERS = 2
local CLOSE_SECONDS = 20

local function ensureAdapter(): any
	if adapter then return adapter end
	local ok, result = pcall(function()
		local primary = DataStoreService:GetDataStore("FloridaMan_Meta_v2")
		local legacy = DataStoreService:GetDataStore("FloridaMan_Meta_v1")
		return Adapter.New({
			now = os.time,
			read = function(key) return primary:GetAsync(key) end,
			legacyRead = function(key) return legacy:GetAsync(key) end,
			update = function(key, transform) return primary:UpdateAsync(key, transform) end,
		}, Rules, config)
	end)
	if ok then adapter = result; providerError = false else providerError = true end
	return adapter
end

local function publish(player: Player, record: any)
	player:SetAttribute("ProfileStatus", record.state)
	player:SetAttribute("ProfileWritable", record.writable)
	player:SetAttribute("ProfileSaveReason", record.reason or "")
	if statusObserver then task.defer(statusObserver, player) end
end

function MetaService.SetStatusObserver(observer: (Player) -> ()) statusObserver = observer end

local function capture(player: Player)
	local fn = capturers[player]
	if fn then
		local ok, err = pcall(function(): any fn(); return nil end)
		if not ok then warn("[MetaService] Profile capture failed:", err) end
	end
end

function MetaService.GetStatus(player: Player): any
	local r = records[player]
	if not r then return {state = "loading", writable = false, reason = "profile-not-ready", revision = 0, savedRevision = 0} end
	return {state = r.state, writable = r.writable, reason = r.reason, revision = r.revision, savedRevision = r.savedRevision}
end

function MetaService.IsWritable(player: Player): boolean
	local r = records[player]
	if not r or not r.writable or r.closing or not r.loaded then return false end
	if os.time() >= r.expiresAt then
		r.writable = false; r.state = "session-conflict"; r.reason = "lease-expired"; publish(player, r)
		return false
	end
	return true
end

function MetaService.IsUsingDataStore(): boolean
	return adapter ~= nil and not providerError
end

function MetaService.IsDirty(player: Player): boolean
	local r = records[player]
	return r ~= nil and r.revision > r.savedRevision
end

function MetaService.GetMetrics(): any
	local totals={profiles=0,dirty=0,queued=0,closing=0,workers=workers}
	for _,record in records do
		totals.profiles+=1
		if record.revision>record.savedRevision then totals.dirty+=1 end
		if record.queued then totals.queued+=1 end
		if record.closing then totals.closing+=1 end
	end
	return totals
end

function MetaService.Get(player: Player): MetaProfile
	local r = records[player]
	return Rules.Clone(if r then r.profile else Rules.Default(config))
end

function MetaService.ApplySettingsAttrs(player: Player, profile: MetaProfile)
	for _, key in Settings.BOOL_KEYS do Settings.SetBool(player, key, profile.settings[key] == true) end
	Settings.SetTextSpeed(player, profile.settings.TextSpeed)
end

function MetaService.Load(player: Player): (MetaProfile, any)
	local existing = records[player]
	if existing then return MetaService.Get(player), MetaService.GetStatus(player) end
	local r = {
		profile = Rules.Default(config), state = "loading", reason = nil, writable = false,
		loaded = false, revision = 0, savedRevision = 0, providerRevision = 0,
		owner = game.JobId .. ":" .. HttpService:GenerateGUID(false), key = "u_" .. tostring(player.UserId),
		busy = false, queued = false, closing = false, closeDeadline = 0, expiresAt = 0,
		nextAttempt = 0, nextAutosave = os.clock() + AUTOSAVE_SECONDS, retries = 0,
		lastWrite = -MIN_WRITE_GAP, settingsTokens = 6, settingsAt = os.clock(),
	}
	records[player] = r
	publish(player, r)
	local storage = ensureAdapter()
	local result = if storage then storage.Acquire(r.key, r.owner, os.time()) else {ok = false, state = "failed-load", reason = "provider-unavailable"}
	r.loaded = true
	if result.ok then
		r.profile = result.profile; r.revision = result.revision; r.savedRevision = result.revision
		r.providerRevision = result.revision; r.expiresAt = result.expiresAt; r.writable = true
		r.state = result.state
	else
		r.state = result.state; r.reason = result.reason
	end
	if r.closing or not player.Parent then
		r.closing = true; r.state = "closing"; r.closeDeadline = os.clock() + CLOSE_SECONDS; r.queued = true
	else
		MetaService.ApplySettingsAttrs(player, r.profile)
	end
	publish(player, r)
	return MetaService.Get(player), MetaService.GetStatus(player)
end

function MetaService.RegisterRunCapturer(player: Player, fn: () -> ()) capturers[player] = fn end
function MetaService.ClearRunCapturer(player: Player) capturers[player] = nil end

local function acceptProfile(player: Player, nextProfile: any): boolean
	local r = records[player]
	if not r or not r.loaded or r.closing or Rules.Equal(r.profile, nextProfile) then return false end
	r.profile = nextProfile; r.revision += 1
	return true
end

function MetaService.MarkDirty(player: Player)
	local r = records[player]
	if r and r.loaded and not r.closing then r.revision += 1 end
end

function MetaService.CaptureFromRun(player: Player, deaths: number, sunburn: number, unlockedMap: any, stageIndex: number?, extras: any?): boolean
	local r = records[player]
	if not r or not r.loaded or r.closing then return false end
	local nextProfile = Rules.Clone(r.profile)
	nextProfile.deaths = deaths; nextProfile.sunburn = sunburn; nextProfile.unlockedPersonas = unlockedMap
	if type(stageIndex) == "number" then nextProfile.bestStageIndex = math.max(nextProfile.bestStageIndex, stageIndex) end
	if type(extras) == "table" then
		for _, key in {"personaRarity", "personas", "unlockedWeapons", "weaponId", "totalTurtlesRescued"} do
			if extras[key] ~= nil then nextProfile[key] = extras[key] end
		end
	end
	local clean = Rules.Normalize(nextProfile, config)
	return clean ~= nil and acceptProfile(player, clean)
end

function MetaService.UpdateSettings(player: Player, key: string, value: any): boolean
	local r = records[player]
	if not r or not r.loaded or r.closing then return false end
	if not ((Settings.IsBoolKey(key) and type(value) == "boolean") or (key == "TextSpeed" and type(value) == "string" and Settings.IsValidTextSpeed(value))) then return false end
	if r.profile.settings[key] == value then return false end
	local now = os.clock()
	r.settingsTokens = math.min(6, r.settingsTokens + (now - r.settingsAt) * 2); r.settingsAt = now
	if r.settingsTokens < 1 then return false end
	r.settingsTokens -= 1
	local nextProfile = Rules.Clone(r.profile); nextProfile.settings[key] = value
	if not acceptProfile(player, nextProfile) then return false end
	if key == "TextSpeed" and type(value) == "string" then
		Settings.SetTextSpeed(player, value)
	elseif type(value) == "boolean" then
		Settings.SetBool(player, key, value)
	end
	MetaService.Save(player)
	return true
end

function MetaService.Save(player: Player, force: boolean?): boolean
	local r = records[player]
	if not r then return false end
	return Queue.Request(r, force == true, os.clock(), MIN_WRITE_GAP)
end

local function discard(player: Player, r: any)
	r.state = "closed"; r.writable = false; publish(player, r)
	if records[player] == r then records[player] = nil end
	capturers[player] = nil
end

local function flush(player: Player, r: any)
	if r.busy or not r.writable or not r.loaded then return end
	r.busy = true; workers += 1
	local written = Queue.Snapshot(r, Rules)
	local revision, snapshot, release = written.revision, written.payload, written.release
	r.state = if release then "closing" else "saving"; publish(player, r)
	local result = adapter.Write(r.key, r.owner, written.expectedRevision, revision, snapshot, os.time(), release)
	r.busy = false; workers -= 1; r.lastWrite = os.clock()
	if result.ok then
		Queue.Succeeded(r, written, result.expiresAt, r.lastWrite, MIN_WRITE_GAP)
		if release then discard(player, r); return end
		r.state = if r.closing then "closing" else "loaded-existing"
	else
		r.reason = result.reason; r.queued = true; r.retries += 1
		if not result.retry then
			r.writable = false; r.state = "session-conflict"
		else
			r.state = if r.closing then "closing" else "save-failed"
			r.nextAttempt = r.lastWrite + math.max(MIN_WRITE_GAP, math.min(30, 2 ^ math.min(r.retries, 5)))
		end
	end
	publish(player, r)
end

function MetaService.Unload(player: Player)
	local r = records[player]
	if not r or r.closing then return end
	capture(player) -- final synchronous copy, before RunContext is discarded
	capturers[player] = nil
	r.closing = true; r.state = "closing"; r.closeDeadline = os.clock() + CLOSE_SECONDS; r.queued = true
	r.nextAttempt = os.clock()
	publish(player, r)
end

task.spawn(function()
	while not stopped do
		task.wait(0.5)
		local now = os.clock()
		for player, r in records do
			if not r.loaded or r.busy then continue end
			if r.closing and (not r.writable or now >= r.closeDeadline) then
				if r.writable then warn("[MetaService] Final save deadline expired for", player.UserId) end
				discard(player, r); continue
			end
			if not r.closing and now >= r.nextAutosave then
				capture(player); r.nextAutosave = now + AUTOSAVE_SECONDS
				if r.writable then r.queued = true end
			end
			if r.queued and r.writable and now >= r.nextAttempt and workers < MAX_WORKERS then
				r.queued = false
				task.spawn(flush, player, r)
			end
		end
	end
end)

-- GameService owns PlayerRemoving ordering and calls Unload before clearing run state.
game:BindToClose(function()
	for player in records do MetaService.Unload(player) end
	local deadline = os.clock() + CLOSE_SECONDS + 2
	while next(records) ~= nil and os.clock() < deadline do task.wait(0.1) end
	stopped = true
end)

return MetaService
