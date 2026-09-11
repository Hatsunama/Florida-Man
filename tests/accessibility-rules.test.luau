local Rules=require('../src/client/Controllers/AccessibilityRules')
local Definitions=require('../src/shared/HazardDefinitions')
local checks=0
for id,definition in Definitions do
	assert(Rules.Cue(definition,false,true,false)==nil,id..' disabled cue')
	local active=Rules.Cue(definition,true,true,false)
	local inactive=Rules.Cue(definition,true,false,false)
	if definition.damage then assert(active=='danger' and inactive==nil,id..' damage phase')
	elseif definition.velocityX or definition.velocityY then assert(active=='flow' and inactive=='flow',id..' directional surface')
	else assert(active=='slow' and inactive=='slow',id..' non-damaging surface') end
	checks+=3
end
assert(Rules.Cue(nil,true,true,true)=='danger','enemy attack windup')
assert(Rules.Cue(nil,true,true,false)==nil,'unknown surface')
print('PASS accessibility cues: '..tostring(checks+2)..' production hazard checks')
