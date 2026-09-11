--!strict
--[[ N8 soft-launch funnel / KPI markers.
	Roblox-safe only: AnalyticsService:LogCustomEvent (pcall) + structured Output prints.
	No third-party SDKs, no invented API keys / telemetry secrets.
]]

local Adapter=require(script.Parent:WaitForChild('AnalyticsAdapter'))
local Rules=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('TelemetryRules'))

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
	| "run_abandon"

type Session = {
	joinedAt: number,
	runStartedAt: number?,
	hubStart: boolean,
	coldOne: boolean,
	stage3Clear: boolean,
	ftue60: boolean,
	midgateLockedAt: number?,
	draftOpenedAt: number?,
	seen: { [string]: boolean? },
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

local function emit(player: Player,event: string,fields: {[string]: any}?)
    local payload: {[string]: any}=fields or {}
    if payload.value == nil then payload.value=payload.held or payload.t_run or 1 end
    if payload.reason == nil then payload.reason=payload.where or payload.item or 'none' end
    payload.device=player:GetAttribute('InputCohort') or 'unknown'
    Adapter.Enqueue(player,event,payload)
end

local function finishFtue(player: Player,s: Session,ending: boolean)
    if s.ftue60 then return end
    local outcome=Rules.FtueOutcome(s.runStartedAt,os.clock(),s.coldOne,ending)
    if outcome then
        s.ftue60=true
        emit(player,'ftue_60s',{ok=if outcome=='success' then 1 else 0,reason=outcome,value=if outcome=='success' then 1 else 0})
        if s.runStartedAt then emit(player,'ftue_duration',{value=math.floor(os.clock()-s.runStartedAt),reason=outcome}) end
    end
end

function FunnelService.OnTransition(player: Player)
    local s=sessions[player]
    if not s then return end
    s.midgateLockedAt=nil; s.draftOpenedAt=nil
    s.seen.softlock_midgate=nil; s.seen.softlock_draft=nil
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
		cold_one = false,
		stage3_clear = false,
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
		s.ftue60=false; s.coldOne=false; s.stage3Clear=false
		s.midgateLockedAt = nil
		s.draftOpenedAt = nil
		s.seen["softlock_midgate"] = nil
		s.seen["softlock_draft"] = nil
	elseif event == "cold_one" then
		s.coldOne = true
		finishFtue(player,s,false)
	elseif event == "death" or event == "run_abandon" then
		finishFtue(player,s,true)
		FunnelService.OnTransition(player)
		s.runStartedAt=nil
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
	finishFtue(player,s,false)
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
    local s=sessions[player]
    if s then finishFtue(player,s,true) end
    sessions[player] = nil
end

FunnelService.GetMetrics = Adapter.GetMetrics
return FunnelService
