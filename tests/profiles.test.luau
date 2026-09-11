local Rules = require('../src/server/ProfileRules')
local Adapter = require('../src/server/ProfileAdapter')
local Queue = require('../src/server/ProfileQueue')
local config = {
	personas = {'BeachBurnout','CrabKing','TurtlePaladin'}, weapons = {'BareHands','FlipFlopSlap','FinaleRocket'},
	settings = {ShakeEnabled=true, ReduceMotion=false, ReduceFlashes=true, LargeText=false, ColorblindTelegraphs=false, TextSpeed='normal'},
}
local function provider(primary, legacy)
	local state = {data=Rules.Clone(primary), legacy=Rules.Clone(legacy), reads=0, migrations=0, updates=0, failRead=false, failLegacy=false, failWrite=false}
	local io = {
		read=function()
			state.reads+=1
			if state.failRead then error('injected read failure') end
			return Rules.Clone(state.data)
		end,
		legacyRead=function()
			state.migrations+=1
			if state.failLegacy then error('injected migration read failure') end
			return Rules.Clone(state.legacy)
		end,
		update=function(_,transform)
			state.updates+=1
			if state.failWrite then error('injected write failure') end
			if state.beforeUpdate then state.beforeUpdate(); state.beforeUpdate=nil end
			local value=transform(Rules.Clone(state.data))
			if value==nil then return nil end
			state.data=Rules.Clone(value)
			if state.failAfterCommit then state.failAfterCommit=false; error('injected lost commit response') end
			return Rules.Clone(value)
		end,
	}
	return state, Adapter.New(io,Rules,config)
end

local original=Rules.Default(config)
original.sunburn=125
local failed,storage=provider(original,nil)
failed.failRead=true
local result=storage.Acquire('u_1','A',100)
assert(not result.ok and result.reason=='read-failed')
assert(failed.migrations==0 and failed.updates==0 and failed.data.sunburn==125)

local failedMigration,migrationStorage=provider(nil,original)
failedMigration.failLegacy=true
assert(not migrationStorage.Acquire('u_1','A',100).ok)
assert(failedMigration.updates==0 and failedMigration.data==nil)

local future=Rules.Clone(original); future.schemaVersion=999
local futureState,futureStorage=provider(future,nil)
assert(futureStorage.Acquire('u_1','A',100).state=='incompatible-version')
assert(futureState.updates==0 and futureState.data.schemaVersion==999)

local legacy={schemaVersion=2,sunburn=50,deaths=2,unlockedPersonas={'CrabKing','CrabKing','Fake'},personaRarity={CrabKing='Rare'},personas={'CrabKing','CrabKing'},unlockedWeapons={'FinaleRocket'},weaponId='FinaleRocket',settings={MuteMaster=false,ReduceMotion=true}}
local migrated,migrator=provider(nil,legacy)
local claim=migrator.Acquire('u_1','A',100)
assert(claim.ok and claim.state=='loaded-existing' and claim.profile.schemaVersion==3)
assert(claim.profile.personaRarity.CrabKing=='Rare' and #claim.profile.personas==1)
assert(claim.profile.personas[1]=='CrabKing' and claim.profile.weaponId=='FinaleRocket')
assert(#claim.profile.unlockedPersonas==2 and claim.profile.settings.MuteMaster==nil)
assert(claim.profile.settings.ReduceMotion and claim.profile.settings.ReduceFlashes)

local malformed=Rules.Normalize({sunburn=0/0,deaths=math.huge,unlockedPersonas={'Fake'},bestStageIndex=999,settings={TextSpeed='invalid'}},config)
assert(malformed.sunburn==0 and malformed.deaths==0 and malformed.bestStageIndex==20)
assert(malformed.settings.TextSpeed=='normal' and #malformed.unlockedPersonas==1)
assert(Rules.Normalize(false,config)==nil)

assert(not migrator.Acquire('u_1','B',110).ok) -- a second live session cannot steal the lease
local wrong=migrator.Write('u_1','A',999,1,claim.profile,111,false)
assert(not wrong.ok and wrong.reason=='revision-conflict' and migrated.data.sunburn==50)
local latest=Rules.Clone(claim.profile); latest.sunburn=30; latest.personaRarity.CrabKing='Unique'
assert(migrator.Write('u_1','A',claim.revision,1,latest,112,false).ok)
assert(migrated.data.sunburn==30 and migrated.data.personaRarity.CrabKing=='Unique')
local takeover=migrator.Acquire('u_1','B',400)
assert(takeover.ok)
assert(not migrator.Write('u_1','A',1,2,original,401,false).ok)
assert(migrated.data.sunburn==30) -- old writer cannot restore spent currency

local concurrent,concurrentStorage=provider(original,nil)
concurrent.beforeUpdate=function() concurrent.data.sunburn=17 end
local current=concurrentStorage.Acquire('u_1','C',100)
assert(current.ok and current.profile.sunburn==17) -- callback uses fresh cloud value, not stale GetAsync

local record={loaded=true,writable=true,profile=Rules.Clone(current.profile),revision=1,savedRevision=0,providerRevision=0,queued=false,closing=false,nextAttempt=0,lastWrite=0}
assert(Queue.Request(record,false,1,6) and record.queued and record.nextAttempt==6)
local snapshot=Queue.Snapshot(record,Rules)
record.profile.sunburn=7; record.revision=2; record.closing=true
assert(snapshot.payload.sunburn==17 and snapshot.revision==1 and not snapshot.release)
assert(not pcall(function() snapshot.payload.sunburn=500 end))
Queue.Succeeded(record,snapshot,300,10,6)
assert(record.savedRevision==1 and record.revision==2 and record.queued)
local final=Queue.Snapshot(record,Rules)
assert(final.release and final.revision==2 and final.payload.sunburn==7)
assert(concurrentStorage.Write('u_1','C',0,1,snapshot.payload,111,false).ok)
concurrent.failWrite=true
local retry=concurrentStorage.Write('u_1','C',1,2,final.payload,112,true)
assert(not retry.ok and retry.retry and concurrent.data.lease.owner=='C')
concurrent.failWrite=false
assert(concurrentStorage.Write('u_1','C',1,2,final.payload,113,true).ok)
assert(concurrent.data.sunburn==7 and concurrent.data.lease==nil)
Queue.Succeeded(record,final,113,12,6)
assert(record.savedRevision==2 and not record.queued)

local ambiguous,ambiguousStorage=provider(original,nil)
assert(ambiguousStorage.Acquire('u_1','D',100).ok)
ambiguous.failAfterCommit=true
assert(not ambiguousStorage.Write('u_1','D',0,1,latest,110,false).ok)
assert(ambiguous.data.revision==1 and ambiguous.data.sunburn==30)
assert(ambiguousStorage.Write('u_1','D',0,1,latest,111,false).ok)
ambiguous.failAfterCommit=true
assert(not ambiguousStorage.Write('u_1','D',1,1,latest,112,true).ok)
assert(ambiguous.data.lease==nil)
assert(ambiguousStorage.Write('u_1','D',1,1,latest,113,true).ok)

-- A newer mutation/close accepted after a lost response cannot replace the
-- retry snapshot: first acknowledge the exact operation, then flush the newest.
local lost,lostStorage=provider(original,nil)
assert(lostStorage.Acquire('u_1','E',100).ok)
local coalesced={loaded=true,writable=true,profile=Rules.Clone(original),revision=1,savedRevision=0,providerRevision=0,queued=false,closing=false,nextAttempt=0,lastWrite=0}
coalesced.profile.sunburn=100
local first=Queue.Snapshot(coalesced,Rules)
lost.failAfterCommit=true
assert(not lostStorage.Write('u_1','E',first.expectedRevision,first.revision,first.payload,110,first.release).ok)
coalesced.profile.sunburn=80; coalesced.revision=2; coalesced.closing=true
local exact=Queue.Snapshot(coalesced,Rules)
assert(exact==first and exact.payload.sunburn==100 and not exact.release)
assert(lostStorage.Write('u_1','E',exact.expectedRevision,exact.revision,exact.payload,111,exact.release).ok)
Queue.Succeeded(coalesced,exact,291,11,6)
local newest=Queue.Snapshot(coalesced,Rules)
assert(newest.expectedRevision==1 and newest.revision==2 and newest.payload.sunburn==80 and newest.release)
assert(lostStorage.Write('u_1','E',newest.expectedRevision,newest.revision,newest.payload,117,newest.release).ok)
Queue.Succeeded(coalesced,newest,117,17,6)
assert(coalesced.savedRevision==2 and not coalesced.queued and lost.data.sunburn==80 and lost.data.lease==nil)

local noOp={loaded=true,writable=true,revision=4,savedRevision=4,queued=false,nextAttempt=0,lastWrite=0}
assert(Queue.Request(noOp,false,10,6) and not noOp.queued)
noOp.writable=false
assert(not Queue.Request(noOp,true,10,6))
print('profiles: failed-read quarantine, migration, future schema, lease conflict, stale writer, immutable snapshots, final retry, revision coalescing passed')
