local Rules=require('../src/server/ItemGrantRules')
local Items=require('../src/shared/Items')
local Campaign=require('../src/shared/ProgressionRules')
local Weapons=require('../src/shared/Weapons')
local Drops=require('../src/shared/ProgressionCatalog')

local state={inHub=true,runActive=false,phase='Hub',generation=7,personas={'BeachBurnout','CrabKing'},activePersona=1,unlockedPersonas={BeachBurnout=true,CrabKing=true,TurtlePaladin=true},personaRarity={BeachBurnout='Common',CrabKing='Common',TurtlePaladin='Common'},sunburn=20}
local function lookup(id) return state.unlockedPersonas[id] and {id=id} or nil end
local patch=Rules.HubTransaction(state,'UpgradePersona',{generation=7,personaId='CrabKing'},lookup)
assert(patch and patch.sunburn==0 and patch.personaRarity.CrabKing=='Rare')
assert(Rules.HubTransaction(state,'UpgradePersona',{generation=6,personaId='CrabKing'},lookup)==nil)
assert(state.sunburn==20 and state.personaRarity.CrabKing=='Common') -- decision does not partially mutate live state
assert(Rules.HubTransaction(state,'SmashPersona',{generation=7,personaId='CrabKing'},lookup)==nil)
assert(Rules.HubTransaction(state,'SmashPersona',{generation=7,personaId='BeachBurnout'},lookup)==nil)
state.phase='Active'; state.inHub=false
assert(Rules.HubTransaction(state,'UpgradePersona',{generation=7,personaId='CrabKing'},lookup)==nil)
state.phase='Hub'; state.inHub=true
assert(Rules.HubTransaction(state,'EquipPersona',{generation=7,personaId='BeachBurnout',slot=2},lookup)==nil)
local equipped=Rules.HubTransaction(state,'EquipPersona',{generation=7,personaId='TurtlePaladin',slot=2},lookup)
assert(equipped and equipped.personas[2]=='TurtlePaladin')
state.personas=equipped.personas
local smashed=Rules.HubTransaction(state,'SmashPersona',{generation=7,personaId='CrabKing'},lookup)
assert(smashed and smashed.sunburn==25 and smashed.unlockedPersonas.CrabKing==nil)
local cleared=Rules.HubTransaction(state,'EquipPersona',{generation=7,personaId='',slot=2},lookup)
assert(cleared and #cleared.personas==1)
assert(Rules.HubTransaction(state,'EquipPersona',{generation=7,personaId='',slot=1},lookup)==nil)

local offer={offerId='run:1:1',generation=1,allowed={FlipFlops=true},consumed=false}
assert(not Rules.ValidateOffer(offer,1,{offerId='run:1:1',generation=1,itemId='LabBadge'}))
assert(not Rules.ValidateOffer(offer,2,{offerId='run:1:1',generation=1,itemId='FlipFlops'}))
assert(Rules.ValidateOffer(offer,1,{offerId='run:1:1',generation=1,itemId='FlipFlops'}))
offer.consumed=true
assert(not Rules.ValidateOffer(offer,1,{offerId='run:1:1',generation=1,itemId='FlipFlops'}))
offer.consumed=false
assert(Rules.ValidateOffer(offer,1,{offerId='run:1:1',generation=1,skip=true}))

local inventory={'FlipFlops','CrackedVisor','LiveBait'}
assert(Rules.Grant(inventory,3,'LabBadge',nil,Items.Get)==nil)
assert(Rules.Grant(inventory,3,'LabBadge',0/0,Items.Get)==nil)
assert(Rules.Grant(inventory,3,'FlipFlops',2,Items.Get)==nil)
local replacement=Rules.Grant(inventory,3,'LabBadge',2,Items.Get)
assert(replacement and #replacement==3 and replacement[2]=='LabBadge' and inventory[2]=='CrackedVisor')

-- Every inscription can be assembled with three distinct legal grants.
local tags={}
for _,item in Items.List do tags[item.inscription]=tags[item.inscription] or {}; table.insert(tags[item.inscription],item.id) end
for tag,members in tags do
	assert(#members>=3,'Unreachable inscription: '..tag)
	local build={}
	for i=1,3 do build=assert(Rules.Grant(build,Campaign.ItemCapacity(1),members[i],nil,Items.Get)) end
	assert(Items.CountInscriptions(build)[tag]==3)
end
local awarded={BareHands=true,FlipFlopSlap=true}
for _,ids in Drops do for _,id in ids do assert(Weapons.Get(id)); awarded[id]=true end end
for _,weapon in Weapons.List do assert(awarded[weapon.id],'Missing unlock route: '..weapon.id) end
assert(table.find(Drops.GulfGulpRig,'FinaleRocket'))

local journal=Rules.NewJournal()
local command={requestId='1',sequence=1,personaId='CrabKing'}
assert(Rules.CheckCommand(journal,'UpgradePersona',command))
local response={requestId='1',sequence=1,command='UpgradePersona',accepted=true}
Rules.RememberCommand(journal,response)
local fresh,cached=Rules.CheckCommand(journal,'UpgradePersona',command)
assert(not fresh and cached==response)
for n=2,70 do Rules.RememberCommand(journal,{requestId=tostring(n),sequence=n,command='UpgradePersona',accepted=false}) end
assert(#journal.order==64)
local replay,old=Rules.CheckCommand(journal,'UpgradePersona',command)
assert(not replay and old==nil) -- eviction never makes an old purchase valid again
print('inventory: offered-ID binding, replacement, duplicate policy, all inscription builds, all weapon unlocks, hub transactions and bounded replay passed')

