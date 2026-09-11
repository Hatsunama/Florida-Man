local Rules = require('../src/shared/ProgressionRules')
local stage = {index=20,isHub=false,boss='Spillfather',rescueTurtles=3,waves={{}},miniboss=nil}
local state = {bossDefeated=false,turtlesRescued=0,waveFlags={[1]=true},minibossSpawned=false,midRoomState='cleared'}
assert(not Rules.CanComplete(stage,state,0))
state.bossDefeated=true -- boss-first cannot bypass rescues
assert(not Rules.CanComplete(stage,state,0))
state.turtlesRescued=3
assert(Rules.CanComplete(stage,state,0))
state.midRoomState='idle'
assert(not Rules.CanComplete(stage,state,0)) -- bypassing the trigger cannot grant completion
state.midRoomState='locked'
assert(not Rules.CanComplete(stage,state,0))
state.midRoomState='cleared'
assert(not Rules.RequiresMidRoom({index=1,isHub=false,waves={{}}}))
assert(not Rules.RequiresMidRoom({index=3,isHub=false,waves={}}))
assert(Rules.RequiresMidRoom(stage))
state.bossDefeated=false -- turtles-first cannot bypass boss
assert(not Rules.CanComplete(stage,state,0))
state.bossDefeated=true
assert(not Rules.CanComplete(stage,state,1)) -- pending enemy counts too
state.waveFlags={}
assert(not Rules.CanComplete(stage,state,0))
local ledger={}
assert(Rules.Claim(ledger,'finale'))
assert(not Rules.Claim(ledger,'finale')) -- simultaneous completion / duplicate callbacks
assert(Rules.ItemCapacity(1)==3 and Rules.ItemCapacity(6)==4)
assert(Rules.ItemCapacity(11)==5 and Rules.ItemCapacity(16)==6)
assert(Rules.ItemCapacity(20)==6 and Rules.ItemCapacity(0)==3)
assert(not Rules.CanUnlockPersona('FireworksEnthusiast',false)) -- boss-first and turtle-first cannot grant early
assert(Rules.CanUnlockPersona('FireworksEnthusiast',true))
assert(Rules.CanUnlockPersona('TurtlePaladin',false))
local daytona={index=1,isHub=false,boss=nil,rescueTurtles=0,waves={{}},miniboss='CrabKingBoss',coldOnePickup=true}
local firstState={bossDefeated=false,turtlesRescued=0,waveFlags={[1]=true},minibossSpawned=true,midRoomState='idle',coldOneTaken=false}
assert(not Rules.CanComplete(daytona,firstState,0),'jumping past the can cannot skip the central first-stage objective')
firstState.coldOneTaken=true
assert(Rules.CanComplete(daytona,firstState,0),'collected can and cleared threats permit exit')
assert(not Rules.CanComplete(daytona,firstState,1),'can pickup never bypasses a remaining enemy')
print('progression: completion ordering, required Cold One, pending threats, idempotence, capacities passed')
