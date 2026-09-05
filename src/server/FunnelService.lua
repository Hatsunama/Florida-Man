--!strict
--[[ N8 soft-launch funnel / KPI markers.
	Roblox-safe only: AnalyticsService:LogCustomEvent (pcall) + structured Output prints.
	No third-party SDKs, no invented API keys / telemetry secrets.
]]

local AnalyticsService = game:GetService("AnalyticsService")

local FunnelService = {}

export type FunnelEvent =
	"session_join"
	| "hub_start"
	| "cold_one"
	| "stage3_clear"
	| "death"
	| "midgate_lock"
	| "midgate_clear"
	| "draft_open"
	| "draft_pick"
	| "ftue_60s"
	| "softlock_suspect"
	| "run_credits"

type Session = {
	joinedAt: number,
	runStartedAt: number?,
	hubStart: boolean,
	coldOne: boolean,
	stage3Clear: boolean,
	ftue60: boolean,
	midgateLockedAt: number?,
	draftOpenedAt: number?,
	seen: { [string]: boolean },
}

local sessions: { [Player]: Session } = {}

local function ensure(player: Player): Session
	local s = sessions[player]
	if not s then
		s = {
			joinedAt = os.clock(),
			runStartedAt = nil,
			hubStart = false,
			coldOne = false,
			stage3Clear = false,
			ftue60 = false,
			midgateLockedAt = nil,
			draftOpenedAt = nil,
			seen = {},
		}
		sessions[player] = s
	end
	return s
end

local function emit(player: Player, event: string, fields: { [string]: any }?)
	local payload = fields or {}
	local parts = { "[FM_FUNNEL]", event, "uid=" .. tostring(player.UserId) }
	for k, v in payload do
		table.insert(parts, tostring(k) .. "=" .. tostring(v))
	end
	print(table.concat(parts, " "))

	pcall(function()
		-- Official Roblox custom event — no external secrets.
		(AnalyticsService :: any):LogCustomEvent(player, event, payload.value)
	end)
end

function FunnelService.OnJoin(player: Player)
	local s = ensure(player)
	s.joinedAt = os.clock()
	emit(player, "session_join", { t = 0 })
end

function FunnelService.Mark(player: Player, event: FunnelEvent, fields: { [string]: any }?)
	local s = ensure(player)
	-- Lifetime-once funnel steps (FTUE). hub_start / death / midgate / draft may repeat.
	local onceKeys: { [string]: boolean } = {
		cold_one = true,
		stage3_clear = true,
		ftue_60s = true,
	}
	if onceKeys[event] and s.seen[event] then
		return
	end
	if onceKeys[event] then
		s.seen[event] = true
	end

	local elapsedJoin = math.floor(os.clock() - s.joinedAt)
	local elapsedRun = if s.runStartedAt then math.floor(os.clock() - s.runStartedAt) else -1
	local payload: { [string]: any } = {
		t_join = elapsedJoin,
		t_run = elapsedRun,
	}
	if fields then
		for k, v in fields do
			payload[k] = v
		end
	end

	if event == "hub_start" then
		s.hubStart = true
		s.runStartedAt = os.clock()
		s.midgateLockedAt = nil
		s.draftOpenedAt = nil
		s.seen["softlock_midgate"] = nil
		s.seen["softlock_draft"] = nil
	elseif event == "cold_one" then
		s.coldOne = true
		if not s.ftue60 and s.runStartedAt and (os.clock() - s.runStartedAt) <= 60 then
			s.ftue60 = true
			emit(player, "ftue_60s", { ok = 1, t_run = math.floor(os.clock() - s.runStartedAt) })
			s.seen["ftue_60s"] = true
		elseif not s.ftue60 and s.runStartedAt then
			emit(player, "ftue_60s", { ok = 0, t_run = math.floor(os.clock() - s.runStartedAt) })
			s.seen["ftue_60s"] = true
			s.ftue60 = true -- mark emitted; late FTUE still once
		end
	elseif event == "stage3_clear" then
		s.stage3Clear = true
	elseif event == "midgate_lock" then
		s.midgateLockedAt = os.clock()
	elseif event == "midgate_clear" then
		s.midgateLockedAt = nil
	elseif event == "draft_open" then
		s.draftOpenedAt = os.clock()
	elseif event == "draft_pick" then
		s.draftOpenedAt = nil
	end

	emit(player, event, payload)
end

--- Call from tick pump (~1 Hz is fine) to flag MidGate / draft softlock suspects.
function FunnelService.WatchSoftlocks(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	local now = os.clock()
	if s.midgateLockedAt and (now - s.midgateLockedAt) >= 90 then
		local key = "softlock_midgate"
		if not s.seen[key] then
			s.seen[key] = true
			emit(player, "softlock_suspect", {
				where = "midgate",
				held = math.floor(now - s.midgateLockedAt),
			})
		end
	end
	if s.draftOpenedAt and (now - s.draftOpenedAt) >= 120 then
		local key = "softlock_draft"
		if not s.seen[key] then
			s.seen[key] = true
			emit(player, "softlock_suspect", {
				where = "draft",
				held = math.floor(now - s.draftOpenedAt),
			})
		end
	end
end

function FunnelService.Unload(player: Player)
	sessions[player] = nil
end

return FunnelService
