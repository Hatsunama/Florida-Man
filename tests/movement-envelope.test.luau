local E = require('../src/shared/MovementEnvelope')
local assertions=0
local function expect(value,message) assertions+=1; assert(value,message) end
local function fresh(x,y) return E.New(x or 18,y or 3,0,0,true) end
local function check(s,x,at,speed,y,grounded,z)
	return E.Check(s,{x=x,y=y or 3,z=z or 0,at=at,grounded=grounded~=false},speed,196.2)
end

-- Exercise sustained accepted trajectories, including a fast legal build.
for _,speed in {12.6,15.84,18,36,68} do
	local s=fresh()
	for step=1,200 do expect(check(s,18+speed*step*0.05,step*0.05,speed),'normal/slow/fast sustained movement') end
end
local slowed=fresh()
local rejected=false
for step=1,40 do
	if not check(slowed,18+18*step*0.05,step*0.05,12.6) then rejected=true; break end
end
expect(rejected,'oil slowdown must constrain persistent travel')

for _,speed in {18,36,68} do
	local s=fresh()
	E.AllowDodge(s,0,18,0.18,speed)
	for step=1,7 do
		local t=step*0.05
		local x=18+100*math.min(t,0.18)+speed*math.max(0,t-0.18)
		expect(check(s,x,t,speed),'full dodge plus ordinary travel across old 0.35 second window')
	end
	for step=8,30 do expect(check(s,36+speed*(step*0.05-0.18),step*0.05,speed),'normal travel after dodge') end
end
local cheating=fresh()
E.AllowDodge(cheating,0,18,0.18,18)
rejected=false
for step=1,30 do
	if not check(cheating,18+100*step*0.05,step*0.05,18) then rejected=true; break end
end
expect(rejected,'an accepted dodge cannot become permanent dodge speed')
local unused=fresh()
E.AllowDodge(unused,0,18,0.18,18)
expect(check(unused,18,0.5,18),'idle after dodge')
expect(not check(unused,36,0.51,18),'unused dodge allowance expires')
local noDodge=fresh()
rejected=false
for step=1,40 do
	if not check(noDodge,18+48*step*0.05,step*0.05,18) then rejected=true; break end
end
expect(rejected,'former permanent 48 speed exploit is rejected')

-- Horizontal forces are granted only by the adapter's accepted hazard overlap.
local wind=fresh()
for step=1,20 do expect(check(wind,18+27*step*0.05,step*0.05,18+9),'authorized horizontal hazard force') end
rejected=false
for step=21,50 do
	if not check(wind,18+27*step*0.05,step*0.05,18) then rejected=true; break end
end
expect(rejected,'expired hazard force cannot sustain excess movement')

local burst=fresh()
expect(check(burst,21.6,0.2,18),'batched replication within earned distance')
expect(check(burst,21.6,0.21,18),'duplicate sample before action')
local before=burst.credit
expect(not check(burst,100,0.21,18),'pre-action forged coordinate is rejected synchronously')
expect(burst.x==21.6 and burst.credit==before,'rejected command keeps accepted origin and does not refill credit')
expect(not check(burst,100,0.21,18),'same-frame tick cannot reauthorize rejected displacement')
local teleported=E.New(120,5,0,1,true)
expect(check(teleported,120,1,18,5),'exact server teleport destination is the accepted baseline')
expect(not check(teleported,220,1.01,18,5),'teleport does not authorize the next arbitrary coordinate')
expect(not check(fresh(),18,0.05,18,40),'altitude teleport')
expect(not check(fresh(),18,0.05,18,3,true,10),'lane departure')
expect(not check(fresh(),0/0,0.05,18),'non-finite input')

local jump=fresh()
for step=1,12 do
	local t=step*0.05
	local y=math.max(3,3+54*t-98.1*t*t)
	expect(check(jump,18+18*t,t,18,y,y==3),'normal jump arc and landing')
end
local pad=fresh()
E.AllowImpulse(pad,0,62)
expect(check(pad,18,0.1,18),'pending pad impulse survives replication delay on ground')
for step=1,14 do
	local flight=step*0.05
	local y=math.max(3,3+62*flight-98.1*flight*flight)
	expect(check(pad,18,0.1+flight,18,y,y==3),'approved pad arc and landing')
end
local falling=E.New(18,30,0,0,false)
for step=1,11 do
	local t=step*0.05
	local y=math.max(3,30-98.1*t*t)
	expect(check(falling,18,t,18,y,y==3),'fall from an elevated supported platform')
end
local floating=fresh()
rejected=false
for step=1,30 do
	if not check(floating,18,step*0.05,18,8,false) then rejected=true; break end
end
expect(rejected,'stationary airborne client cannot remain above the gravity envelope')
print('PASS: '..assertions..' stateful movement policy assertions')
