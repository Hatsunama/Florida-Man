local Rules = require('../src/server/EnemyMovementRules')
assert(Rules.ClampX(310, 300, 3, nil) == 296.5, 'full body stays inside stage end')
assert(Rules.ClampX(-50, 300, 3, nil) == 3.5, 'full body stays inside stage start')
assert(Rules.ClampX(80, 300, 3, nil) == 80, 'ordinary placement is unchanged')
local locked = Rules.ClampX(170, 300, 3, 142.75)
assert(locked == 139.5 and locked + 3 < 142.75, 'a wave beyond the front gate is realized before its face')
assert(Rules.ClampX(170, 300, 3, nil) == 170, 'queued demand uses the current unlocked gate state')
assert(Rules.ClampX(170, 300, 6, 142.75) < locked, 'large bodies need additional gate clearance')
assert(Rules.ClampX(0/0, 300, 3, nil) == 3.5, 'invalid placement cannot poison world coordinates')
for _,shape in {'crab','lizard','slime','humanoid','boss','turtle','drone','pelican','cloud','gator','snake','hopper','cart','barrel'} do
	local axis=Rules.ForwardAxis(shape)
	for _,facing in {-1,1} do
		local yaw=Rules.FacingYaw(facing,axis)
		local x=if axis=='-Z' then -math.sin(yaw) else math.cos(yaw)
		local z=if axis=='-Z' then -math.cos(yaw) else -math.sin(yaw)
		assert(math.abs(x-facing)<1e-6 and math.abs(z)<1e-6,shape..' must face its world movement direction')
	end
end
assert(Rules.ForwardAxis('gator')=='+X' and Rules.ForwardAxis('snake')=='+X','preserve existing longitudinal kits')
assert(Rules.FacingYaw(1,'+X')==0,'imported +X art needs no default rotation')
print('PASS: stage/gate containment plus 14 procedural shapes in both facing directions')
