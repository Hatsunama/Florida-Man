--!strict
-- Pure acceptance bookkeeping. Replication tolerance is a finite shared credit,
-- never a fresh per-frame distance grant. Adapters supply trusted action grants.
local Envelope = {}
local CREDIT = 4
local REPLICATION_GRACE = 0.22
export type Sample = {x: number, y: number, z: number, at: number, grounded: boolean}
export type State = {
	x: number, y: number, z: number, at: number, credit: number,
	burst: number, burstUntil: number, airAt: number?, airY: number, launchSpeed: number, impulseUntil: number,
}
local function finite(value: number): boolean return value == value and math.abs(value) < math.huge end

function Envelope.New(x: number, y: number, z: number, now: number, grounded: boolean): State
	return {x=x,y=y,z=z,at=now,credit=CREDIT,burst=0,burstUntil=0,
		airAt=if grounded then nil else now,airY=y,launchSpeed=54,impulseUntil=0}
end

function Envelope.AllowDodge(state: State, now: number, distance: number, duration: number, speed: number)
	-- Only the excess over normal movement needs a separate grant. Unused distance
	-- expires after a short replication grace; repeated checks cannot renew it.
	state.burst=math.max(0,distance-math.max(0,speed)*duration)
	state.burstUntil=now+duration+REPLICATION_GRACE
end

function Envelope.AllowImpulse(state: State, now: number, speedY: number)
	state.airAt=now; state.airY=state.y; state.launchSpeed=math.max(54,math.min(speedY,80))
	state.impulseUntil=now+REPLICATION_GRACE
end

function Envelope.Check(state: State, sample: Sample, speed: number, gravity: number): (boolean,string)
	if not finite(sample.x) or not finite(sample.y) or not finite(sample.z) or not finite(sample.at) then return false,'non-finite' end
	local elapsed=math.max(0,sample.at-state.at)
	local dt=math.min(elapsed,0.5)
	local dx,dy,dz=sample.x-state.x,sample.y-state.y,sample.z-state.z
	local available=state.credit+math.max(0,speed)*dt
	local burst=if sample.at<=state.burstUntil then state.burst else 0
	-- Account for elapsed time once even when a rejected command is followed by a
	-- simulation check in the same frame. A correction must not mint new credit.
	state.at=sample.at
	if math.abs(dz)>2.5 or dy>80*dt+3 or dy<-(220*dt+5) then
		state.credit=math.min(CREDIT,available); return false,'vertical-or-lane-step'
	end
	local excess=math.max(0,math.abs(dx)-available)
	if excess>burst+0.00001 then state.credit=math.min(CREDIT,available); return false,'horizontal-budget' end
	local airAt=state.airAt
	local airY=state.airY
	local launch=state.launchSpeed
	if not airAt and (not sample.grounded or dy>1.5) then airAt=sample.at-dt; airY=state.y; launch=54 end
	if airAt then
		-- Upper envelope of a jump whose launch may trail the last ground sample.
		-- Short jumps/falls are below this curve. Ground contact may end the flight,
		-- but cannot first bypass its height bound by claiming a distant platform.
		local flight=math.max(0,sample.at-airAt)
		local g=math.max(1,gravity)
		local peak=launch/g
		local t=math.clamp(peak,math.max(0,flight-REPLICATION_GRACE),flight)
		local upper=airY+launch*t-0.5*g*t*t+3
		if sample.y>upper then state.credit=math.min(CREDIT,available); return false,'airborne-envelope' end
	end
	state.credit=math.min(CREDIT,math.max(0,available-math.abs(dx)))
	state.burst=math.max(0,burst-excess)
	state.x=sample.x; state.y=sample.y; state.z=sample.z
	local landed=sample.grounded and sample.at>=state.impulseUntil
	state.airAt=if landed then nil else airAt
	state.airY=if landed then sample.y else airY
	state.launchSpeed=if landed then 54 else launch
	return true,'accepted'
end

return Envelope
