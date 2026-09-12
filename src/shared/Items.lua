--!strict
--[[ Item catalog — 25+ power-ups. Inscriptions: HUMID FERAL LUCKY GREASY HEROIC CHAOS
	3 of a tag = set bonus. Florida Dew / Cold One is a stage pickup, not an item brand.
]]

local Items = {}

export type ItemDef = {
	id: string,
	name: string,
	description: string,
	rarity: string,
	inscription: string,
	statText: string,
	hpBonus: number,
	damageBonus: number,
	speedBonus: number,
	luckBonus: number,
	dodgeBonus: number,
	healOnPickup: number,
	special: string,
}

local list: { ItemDef } = {
	{ id="FlipFlops", name="Flip-Flops", description="Slap-slap mobility. One is always missing.", rarity="Common", inscription="HUMID",
		statText="+Move Speed", hpBonus=0, damageBonus=0, speedBonus=2, luckBonus=0, dodgeBonus=0.05, healOnPickup=0, special="" },
	{ id="CrackedVisor", name="Cracked Visor", description="Blocks 40% of glare and 0% of bad decisions.", rarity="Common", inscription="HEROIC",
		statText="+HP", hpBonus=15, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="LiveBait", name="Live Bait", description="Fresh bait. Suspiciously effective when you swing first.", rarity="Common", inscription="FERAL",
		statText="+Damage", hpBonus=0, damageBonus=3, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="ExpiredSunscreen", name="Expired Sunscreen", description="Sticky armor. SPF: emotional.", rarity="Common", inscription="HUMID",
		statText="+HP, slight slow", hpBonus=20, damageBonus=0, speedBonus=-1, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="IHeartFLShirt", name="I♥FL Shirt", description="Tourist camouflage. +swagger.", rarity="Rare", inscription="CHAOS",
		statText="+Luck +HP", hpBonus=10, damageBonus=0, speedBonus=0, luckBonus=0.08, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="NoveltyMug", name="Novelty Mug", description="Says WORLD'S OKAYEST FLORIDA MAN. Holds Florida Dew vibes.", rarity="Rare", inscription="HUMID",
		statText="Heal on stage clear", hpBonus=5, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="stageHeal" },
	{ id="TurtleSticker", name="Turtle Sticker", description="Never harm turtles. This sticker agrees.", rarity="Rare", inscription="HEROIC",
		statText="+Damage (corp tax)", hpBonus=0, damageBonus=2, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=5, special="antiCorp" },
	{ id="GasStationTaquito", name="Gas-Station Taquito", description="Rolling since Tuesday. Heal now, regret never (cartoon).", rarity="Common", inscription="GREASY",
		statText="Instant heal", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=25, special="" },
	{ id="LawnDartCharm", name="Lawn Dart Charm", description="Banned in 12 HOAs. Still flies true.", rarity="Rare", inscription="CHAOS",
		statText="+Damage", hpBonus=0, damageBonus=5, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="HOACitation", name="HOA Citation", description="Weaponized paperwork. Paper cut criticals.", rarity="Unique", inscription="CHAOS",
		statText="+Crit-ish damage", hpBonus=0, damageBonus=7, speedBonus=0, luckBonus=0.05, dodgeBonus=0, healOnPickup=0, special="paperCut" },
	{ id="LuckyPenny", name="Lucky Penny", description="Found heads-up next to a pelican.", rarity="Rare", inscription="LUCKY",
		statText="+Luck", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0.15, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="GatorSkinWallet", name="Gator-Skin Wallet", description="Empty. Still intimidating.", rarity="Unique", inscription="FERAL",
		statText="+Damage +Sunburn find", hpBonus=0, damageBonus=4, speedBonus=0, luckBonus=0.05, dodgeBonus=0, healOnPickup=0, special="sunburnFind" },
	{ id="RadioCollar", name="Radio Collar", description="GulfGulp tracking tech. Proof gators are science experiments.", rarity="Unique", inscription="GREASY",
		statText="+Damage vs Oil Gators", hpBonus=5, damageBonus=3, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="radio" },
	{ id="SpillAbsorbent", name="Spill Absorbent", description="Pads that drink sludge so turtles don't have to.", rarity="Unique", inscription="HEROIC",
		statText="+15 HP, 25% less incoming damage, shorter dodge cooldown", hpBonus=15, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0.05, healOnPickup=0, special="absorb" },
	{ id="LabBadge", name="Lab Badge", description="GulfGulp Energy — TEMPORARY. Very temporary.", rarity="Legendary", inscription="GREASY",
		statText="+HP +Damage (badge privilege)", hpBonus=20, damageBonus=6, speedBonus=1, luckBonus=0.1, dodgeBonus=0, healOnPickup=0, special="badge" },
	{ id="SeashellShield", name="Seashell Shield", description="Borrowed from a hermit. Refund denied.", rarity="Common", inscription="HEROIC",
		statText="+18 HP, 3% shorter dodge cooldown", hpBonus=18, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0.03, healOnPickup=0, special="" },
	{ id="MosquitoNet", name="Mosquito Net Cape", description="Fashionable. Buzz-proof-ish.", rarity="Common", inscription="HUMID",
		statText="+5 HP, +speed, 8% shorter dodge cooldown", hpBonus=5, damageBonus=0, speedBonus=1, luckBonus=0, dodgeBonus=0.08, healOnPickup=0, special="" },
	{ id="PelicanWhistle", name="Pelican Whistle", description="Captain Steve merch. Summons confidence.", rarity="Rare", inscription="LUCKY",
		statText="+Luck +Damage", hpBonus=0, damageBonus=2, speedBonus=0, luckBonus=0.12, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="MustardPacket", name="Industrial Mustard", description="From the runaway cart. Greasy power.", rarity="Common", inscription="GREASY",
		statText="+Damage", hpBonus=0, damageBonus=4, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=8, special="" },
	{ id="RedTideFilter", name="Red Tide Filter Mask", description="Looks ridiculous. Works anyway.", rarity="Rare", inscription="HEROIC",
		statText="+22 HP, 25% less incoming damage", hpBonus=22, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="absorb" },
	{ id="CondoPass", name="Stolen Condo Pass", description="Access to nowhere useful. +chaos.", rarity="Unique", inscription="CHAOS",
		statText="+Speed +Luck", hpBonus=0, damageBonus=0, speedBonus=3, luckBonus=0.1, dodgeBonus=0.04, healOnPickup=0, special="" },
	{ id="JetSkiKey", name="Jet Ski Key", description="Ignition for bad decisions.", rarity="Rare", inscription="CHAOS",
		statText="+speed, +damage, 6% shorter dodge cooldown", hpBonus=0, damageBonus=1, speedBonus=4, luckBonus=0, dodgeBonus=0.06, healOnPickup=0, special="" },
	{ id="CypressCharm", name="Cypress Knee Charm", description="Swamp luck carved wrong on purpose.", rarity="Common", inscription="FERAL",
		statText="+Damage +HP", hpBonus=8, damageBonus=2, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="BonfireEmber", name="Bonfire Ember", description="Still warm from the hub. Dodge fans the coals.", rarity="Rare", inscription="FERAL",
		statText="+Damage after dodge", hpBonus=0, damageBonus=5, speedBonus=0, luckBonus=0, dodgeBonus=0.02, healOnPickup=0, special="ember" },
	{ id="TurtleSnack", name="Turtle Snack Pack", description="For turtles. You may have one crumb.", rarity="Common", inscription="LUCKY",
		statText="Heal 20 HP, +luck", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0.05, dodgeBonus=0, healOnPickup=20, special="" },
	{ id="OilProofBoots", name="Oil-Proof Boots", description="Slick floors hate these.", rarity="Unique", inscription="GREASY",
		statText="+Speed +HP, absorb hits", hpBonus=12, damageBonus=0, speedBonus=2, luckBonus=0, dodgeBonus=0.05, healOnPickup=0, special="absorb" },
	{ id="HeadlinePressPass", name="Headline Press Pass", description="BREAKING: you are the story.", rarity="Legendary", inscription="CHAOS",
		statText="+Damage +Luck +swagger", hpBonus=10, damageBonus=8, speedBonus=1, luckBonus=0.15, dodgeBonus=0, healOnPickup=0, special="paperCut" },
	{ id="DewKoozie", name="Florida Dew Koozie", description="Keeps vibes cold. Not a drink brand ad.", rarity="Rare", inscription="HUMID",
		statText="+HP, heal on pickup + stage clear", hpBonus=10, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=12, special="stageHeal" },
	{ id="WoodPlank", name="Wood Plank", description="A little board with a surprisingly supportive attitude.", rarity="Common", inscription="CHAOS",
		statText="Heal 3% max HP once per stage cleared", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="woodPlankHeal" },
	{ id="PocketfulOfSunshine", name="Pocketful of Sunshine", description="A small bright spot for a long Florida day.", rarity="Rare", inscription="HEROIC",
		statText="Heal 1 HP every 3 enemy kills while equipped", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="sunshineHeal" },
}

Items.List = list
Items.ById = {} :: { [string]: ItemDef }
for _, it in list do
	Items.ById[it.id] = it
end

Items.SetBonuses = {
	HUMID = { name = "Swamp Sweat", text = "+5% dodge CDR / +8 HP", hpBonus = 8, dodgeBonus = 0.05 },
	FERAL = { name = "Bite Back", text = "+12% damage", damageBonus = 0.12 },
	LUCKY = { name = "Pelican Favor", text = "+better draft rarity", luckBonus = 0.2 },
	GREASY = { name = "Deep Fry Defense", text = "+15 HP, oil resist (milder slicks / half oil hazard dmg)", hpBonus = 15, special = "oilResist" },
	HEROIC = { name = "Turtle Oath", text = "Heal 6% of damage actually dealt", special = "lifesteal" },
	CHAOS = { name = "Headline Energy", text = "+8% damage", damageBonus = 0.08 },
}

function Items.Get(id: string): ItemDef?
	return Items.ById[id]
end

function Items.Count(): number
	return #list
end

function Items.RollDraft(rng: Random, luck: number, count: number, owned: {string}?): { ItemDef }
	local pool = {}
	for _, item in list do
		if not owned or not table.find(owned, item.id) then table.insert(pool, item) end
	end
	local picks = {}
	local n = math.min(count, #pool)
	for _ = 1, n do
		local weights = {}
		local total = 0
		for i, it in pool do
			local w = 1
			if it.rarity == "Common" then w = 50
			elseif it.rarity == "Rare" then w = 28 + luck * 40
			elseif it.rarity == "Unique" then w = 12 + luck * 50
			elseif it.rarity == "Legendary" then w = 3 + luck * 60
			end
			weights[i] = w
			total += w
		end
		local roll = rng:NextNumber() * total
		local acc = 0
		local chosen = 1
		for i, w in weights do
			acc += w
			if roll <= acc then
				chosen = i
				break
			end
		end
		table.insert(picks, pool[chosen])
		table.remove(pool, chosen)
	end
	return picks
end

function Items.CountInscriptions(owned: { string }): { [string]: number }
	local counts = { HUMID=0, FERAL=0, LUCKY=0, GREASY=0, HEROIC=0, CHAOS=0 }
	for _, id in owned do
		local it = Items.ById[id]
		if it then
			counts[it.inscription] = (counts[it.inscription] or 0) + 1
		end
	end
	return counts
end

return Items
