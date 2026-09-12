local Healing = require('../src/server/ItemHealingRules')
local Campaign = require('../src/shared/ProgressionRules')
local Grants = require('../src/server/ItemGrantRules')
local Items = require('../src/shared/Items')

local function close(a, b) assert(math.abs(a - b) < 0.000001, tostring(a) .. ' ~= ' .. tostring(b)) end
local function equipped(inventory, special)
	for _, id in inventory do if Items.Get(id).special == special then return true end end
	return false
end

close(Healing.StageClear(40, 125, true), 43.75) -- percent uses max HP, with no rounding
close(Healing.StageClear(124, 125, true), 125)
assert(Healing.StageClear(40, 125, false) == 40)
assert(Healing.StageClear(0, 125, true) == 0) -- never revives

-- Exercise the same reward claim used by FinishStage, including a repeated
-- final-stage clear and equipping after an already claimed reward.
local ledger, hp = {}, 40
local function clear(stage, hasPlank)
	if Campaign.Claim(ledger, stage) then hp = Healing.StageClear(hp, 125, hasPlank) end
end
clear('Beach', false)
clear('Beach', true)
assert(hp == 40, 'no retroactive clear healing')
clear('Swamp', true)
clear('Swamp', true)
close(hp, 43.75)
clear('GulfGulpRig', true)
clear('GulfGulpRig', true)
close(hp, 47.5)

local progress = 0
hp, progress = Healing.EnemyKill(40, 125, progress, false, true)
assert(hp == 40 and progress == 0, 'unequipped kills earn no credit')
for n = 1, 6 do
	hp, progress = Healing.EnemyKill(hp, 125, progress, true, true)
	assert(hp == 40 + math.floor(n / 3) and progress == n % 3)
end
hp, progress = Healing.EnemyKill(40, 125, 2, true, false)
assert(hp == 40 and progress == 2, 'rescues, allies and invalid kills do not count')
hp, progress = Healing.EnemyKill(0, 125, 2, true, true)
assert(hp == 0 and progress == 2, 'dead players cannot receive kill healing')
hp, progress = Healing.EnemyKill(125, 125, 2, true, true)
assert(hp == 125 and progress == 0, 'full-health trigger is consumed')
hp, progress = Healing.EnemyKill(124.5, 125, 2, true, true)
assert(hp == 125 and progress == 0, 'kill healing caps at max HP')

local inventory = assert(Grants.Grant({'FlipFlops', 'CrackedVisor'}, 3, 'PocketfulOfSunshine', nil, Items.Get))
progress = Healing.EquipmentProgress(0, false, equipped(inventory, 'sunshineHeal'))
assert(progress == 0)
hp, progress = Healing.EnemyKill(40, 125, progress, true, true)
hp, progress = Healing.EnemyKill(hp, 125, progress, true, true)
assert(progress == 2)
assert(Healing.EquipmentProgress(progress, true, true) == 2, 'unrelated grants retain progress')
inventory = assert(Grants.Grant(inventory, 3, 'WoodPlank', 3, Items.Get))
progress = Healing.EquipmentProgress(progress, true, equipped(inventory, 'sunshineHeal'))
assert(progress == 0, 'replacement clears partial progress immediately')
inventory = assert(Grants.Grant(inventory, 3, 'PocketfulOfSunshine', 3, Items.Get))
progress = Healing.EquipmentProgress(progress, false, equipped(inventory, 'sunshineHeal'))
hp, progress = Healing.EnemyKill(hp, 125, progress, true, true)
assert(hp == 40 and progress == 1, 'reacquiring starts a new three-kill sequence')

-- Both additions flow through the real draft pool and duplicate policy.
local all = Items.RollDraft({NextNumber = function() return 0 end}, 0, Items.Count())
local found = {}
for _, item in all do found[item.id] = true end
assert(found.WoodPlank and found.PocketfulOfSunshine)
local owned = {'WoodPlank', 'PocketfulOfSunshine'}
for _, item in Items.RollDraft({NextNumber = function() return 0 end}, 0, Items.Count(), owned) do
	assert(not table.find(owned, item.id))
end
assert(Grants.Grant(owned, 3, 'WoodPlank', nil, Items.Get) == nil)
assert(Grants.Grant(owned, 3, 'PocketfulOfSunshine', nil, Items.Get) == nil)
print('item healing: stage claims, percentage, third-kill cadence, eligibility, caps, replacement and drafts passed')
