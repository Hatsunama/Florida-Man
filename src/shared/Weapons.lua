--!strict
--[[ Weapon catalog — Florida nonsense melee/ranged/thrown. Equipped separately from personas. ]]

local Weapons = {}

export type WeaponDef = {
	id: string,
	name: string,
	description: string,
	kind: string, -- melee | ranged | thrown
	damage: number,
	range: number,
	speed: number,
	knockback: number,
	rarity: string,
	flavor: string,
	vfx: string,
	secondaryEffect: string?,
}

local list: { WeaponDef } = {
	{ id="BareHands", name="Bare Hands", description="Default Florida fists.", kind="melee", damage=10, range=8, speed=1.0, knockback=8, rarity="Common", flavor="Technically a weapon.", vfx="punch" },
	{ id="FlipFlopSlap", name="Flip-Flop", description="The classic slapper. One always missing.", kind="melee", damage=12, range=9, speed=1.15, knockback=10, rarity="Common", flavor="Slap-slap justice.", vfx="slap" },
	{ id="LawnDart", name="Lawn Dart", description="Banned in 12 HOAs. Still flies true.", kind="thrown", damage=18, range=22, speed=0.85, knockback=6, rarity="Rare", flavor="Arcs of destiny.", vfx="dart" },
	{ id="GolfClub", name="Golf Club", description="Fore! Also sideways.", kind="melee", damage=16, range=12, speed=0.9, knockback=14, rarity="Common", flavor="HOA driving range.", vfx="swing" },
	{ id="GatorWrestleGloves", name="Gator Wrestle Gloves", description="Borrowed from a science experiment.", kind="melee", damage=20, range=10, speed=0.8, knockback=16, rarity="Unique", flavor="Clamp and slam.", vfx="grab" },
	{ id="RomanCandle", name="Roman Candle", description="Safety third. Sparks first.", kind="ranged", damage=14, range=26, speed=1.0, knockback=4, rarity="Rare", flavor="Cartoon rockets.", vfx="firework" },
	{ id="SnakeLasso", name="Snake Lasso", description="Hisses when it hits. Somehow helpful.", kind="thrown", damage=15, range=20, speed=0.95, knockback=8, rarity="Rare", flavor="Coil control.", vfx="lasso" },
	{ id="SpillSkimmer", name="Spill Skimmer", description="Pads that drink sludge so turtles don't.", kind="melee", damage=13, range=11, speed=1.05, knockback=7, rarity="Unique", flavor="Eco slap.", vfx="splash" },
	{ id="PoolNoodle", name="Pool Noodle", description="Soft. Humiliating. Effective.", kind="melee", damage=9, range=14, speed=1.3, knockback=12, rarity="Common", flavor="Bonk of shame.", vfx="bonk" },
	{ id="CoolerLid", name="Cooler Lid", description="Shield bash with Florida Dew stains.", kind="melee", damage=11, range=8, speed=1.1, knockback=15, rarity="Common", flavor="Bash then sip vibes.", vfx="bash" },
	{ id="BeachUmbrella", name="Beach Umbrella", description="Pointy end optional. Wind optional.", kind="melee", damage=14, range=13, speed=0.88, knockback=11, rarity="Rare", flavor="Sun-blocking spear.", vfx="thrust" },
	{ id="FireExtinguisher", name="Fire Extinguisher", description="Foam cone vs fire lizards.", kind="ranged", damage=12, range=18, speed=1.0, knockback=9, rarity="Rare", flavor="Corporate safety theater.", secondaryEffect="foamFire", vfx="foam" },
	{ id="TrafficCone", name="Traffic Cone", description="Wearable. Throwable. Iconic.", kind="thrown", damage=13, range=16, speed=1.05, knockback=10, rarity="Common", flavor="Cone of silence.", vfx="cone" },
	{ id="KayakPaddle", name="Kayak Paddle", description="Double-sided swamp oar.", kind="melee", damage=15, range=12, speed=1.0, knockback=12, rarity="Common", flavor="Row your beef.", vfx="paddle" },
	{ id="BugZapper", name="Bug Zapper", description="ZZZT. Good on flies and HOA vibes.", kind="melee", damage=17, range=9, speed=0.95, knockback=5, rarity="Rare", flavor="Electric slap.", vfx="zap" },
	{ id="WaterBalloonSling", name="Water Balloon Sling", description="Red tide revenge, cartoon edition.", kind="ranged", damage=11, range=24, speed=1.1, knockback=3, rarity="Common", flavor="Splash damage.", vfx="balloon" },
	{ id="ShoppingCart", name="Shopping Cart Ram", description="One wheel always squeaks.", kind="melee", damage=19, range=11, speed=0.75, knockback=20, rarity="Unique", flavor="Full send aisle 3.", vfx="ram" },
	{ id="PelicanBeakReplica", name="Pelican Beak Replica", description="Captain Steve merch. Sharp opinions.", kind="melee", damage=16, range=10, speed=1.0, knockback=9, rarity="Unique", flavor="Steve-approved.", vfx="peck" },
	{ id="OilBarrelLid", name="Oil Barrel Lid", description="GulfGulp scrap. Heavy frisbee.", kind="thrown", damage=18, range=19, speed=0.8, knockback=14, rarity="Rare", flavor="Corporate frisbee.", vfx="disc" },
	{ id="TikiTorch", name="Tiki Torch", description="Ambient lighting + poke.", kind="melee", damage=14, range=11, speed=0.92, knockback=8, rarity="Common", flavor="Bonfire energy.", vfx="torch" },
	{ id="Skateboard", name="Skateboard", description="Kickflip into combat somehow.", kind="melee", damage=13, range=10, speed=1.2, knockback=13, rarity="Rare", flavor="Grind the lane.", vfx="board" },
	{ id="FishSmack", name="Frozen Fish", description="Thaws mid-combo. Still hits.", kind="melee", damage=15, range=9, speed=1.0, knockback=11, rarity="Common", flavor="Slapstick seafood.", vfx="fish" },
	{ id="NewspaperRoll", name="Rolled Newspaper", description="BREAKING: you got bonked.", kind="melee", damage=10, range=8, speed=1.25, knockback=6, rarity="Common", flavor="Headline swat.", vfx="paper" },
	{ id="NetGun", name="Turtle-Safe Net", description="Roots and interrupts grunts. Safe around turtles.", kind="ranged", damage=8, range=20, speed=0.9, knockback=2, rarity="Unique", flavor="Rescue tech.", secondaryEffect="netRoot", vfx="net" },
	{ id="SludgeHose", name="Sludge Hose", description="Turned GulfGulp's hose against them.", kind="ranged", damage=16, range=22, speed=0.85, knockback=7, rarity="Unique", flavor="Irony stream.", vfx="hose" },
	{ id="FinaleRocket", name="Finale Rocket", description="One big cartoon boom.", kind="thrown", damage=28, range=30, speed=0.65, knockback=18, rarity="Legendary", flavor="Credits tease.", vfx="rocket" },
	{ id="HOAClipboard", name="HOA Clipboard", description="Paper cuts + citations.", kind="melee", damage=12, range=8, speed=1.15, knockback=4, rarity="Rare", flavor="Weaponized paperwork.", vfx="clip" },
	{ id="BoogieBoard", name="Boogie Board", description="Surf the lane, bash sideways.", kind="melee", damage=14, range=11, speed=1.05, knockback=12, rarity="Common", flavor="Hang ten, then ten more.", vfx="board" },
}

Weapons.List = list
Weapons.ById = {} :: { [string]: WeaponDef }
for _, w in list do
	Weapons.ById[w.id] = w
end

function Weapons.Get(id: string): WeaponDef?
	return Weapons.ById[id]
end

function Weapons.GetStarter(): WeaponDef
	return Weapons.ById.BareHands
end

function Weapons.AllIds(): { string }
	local ids = {}
	for _, w in list do
		table.insert(ids, w.id)
	end
	return ids
end

return Weapons
