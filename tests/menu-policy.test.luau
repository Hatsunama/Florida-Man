local Policy=require('../src/client/Controllers/MenuPolicy')
local active={generation=1,phase='Active',stageId='beach',runActive=true,inHub=false,hp=100,characterReady=true}
local function updated(fields)
	local value=table.clone(active)
	for key,item in fields do value[key]=item end
	return value
end
assert(not Policy.CloseForState(active,updated({hp=90})), 'ordinary damage preserves menu')
assert(Policy.CloseForState(active,updated({generation=2})), 'new generation closes menu')
assert(Policy.CloseForState(active,updated({stageId='swamp'})), 'stage change closes menu')
assert(Policy.CloseForState(active,updated({phase='Reward'})), 'phase change closes menu')
assert(Policy.CloseForState(active,updated({phase='Hub',inHub=true,runActive=false})), 'hub return closes menu')
for _,phase in {'Dead','Ending','Closing','Loading'} do
	assert(Policy.CloseForState(nil,updated({phase=phase})), phase..' closes even without previous snapshot')
end
assert(Policy.CloseForState(active,updated({hp=0})), 'death before phase update closes menu')
assert(Policy.CloseForState(active,updated({characterReady=false})), 'character teardown closes menu')
assert(not Policy.ControllerUIOwnsMovement(false,true,true), 'combat selection preserves stick and jump')
assert(not Policy.ControllerUIOwnsMovement(false,false,false), 'ordinary gameplay retains movement')
assert(Policy.ControllerUIOwnsMovement(true,true,true), 'modal supersedes combat selection')
assert(Policy.ControllerUIOwnsMovement(false,true,false), 'unrelated UI selection retains navigation')
assert(Policy.ControllerUIOwnsMovement(true,false,false), 'modal without focus still blocks gameplay')
print('PASS 16 menu lifecycle and controller input ownership rules')
