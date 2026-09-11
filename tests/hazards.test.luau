local Rules = require('../src/shared/HazardRules')
local Defs = require('../src/shared/HazardDefinitions')
local expected = {damage=7,impulseY=28,velocityX=1,velocityY=-4,oilSlow=true,environmentSlow=true,water=true}
local entries = {{Defs.slushPuddle,1},{Defs.pipeSpray,1},{Defs.slickRing,1},{Defs.oilSlick,1},{Defs.canalWater,1},{Defs.conveyor,-1},{Defs.windPush,1}}
local orders = 0
local function permutations(prefix, remaining)
	if #remaining == 0 then
		local out = Rules.New()
		for _, entry in prefix do Rules.Add(out, entry[1], false, entry[2]) end
		for key, value in expected do assert(out[key] == value, 'overlap order must not change '..key) end
		orders += 1
		return
	end
	for i, entry in remaining do
		local rest = table.clone(remaining); table.remove(rest,i)
		table.insert(prefix,entry); permutations(prefix,rest); table.remove(prefix)
	end
end
permutations({},entries)
assert(orders==5040)
local resisted=Rules.New()
Rules.Add(resisted,Defs.slickRing,true,1); Rules.Add(resisted,Defs.movingSample,true,1)
assert(resisted.damage==5,'choose strongest AFTER mitigation; oil resistance must not weaken a sample')
assert(Rules.SlowMultiplier(false,true,false,true,.88,.70,.88)==.88,'resist oil')
assert(Rules.SlowMultiplier(false,false,true,true,.88,.70,.88)==.70,'do not resist sand, water, tide or paperwork')
assert(Rules.SlowMultiplier(true,true,true,true,.88,.70,.88)==.70,'mixed slow chooses strongest; never compounds')
assert(Rules.SlowMultiplier(false,false,false,false,.88,.70,.88)==1,'all effects expire')
print('PASS: 5040 overlap permutations, post-mitigation maximum, impulses, typed slows and expiry')
