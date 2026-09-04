--!strict
--[[ Item catalog — inscription tags: HUMID FERAL LUCKY GREASY HEROIC CHAOS
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
	{ id="LiveBait", name="Live Bait", description="Enemies get interested. You get openings.", rarity="Common", inscription="FERAL",
		statText="+Damage", hpBonus=0, damageBonus=3, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="aggro" },
	{ id="ExpiredSunscreen", name="Expired Sunscreen", description="Sticky armor. SPF: emotional.", rarity="Common", inscription="HUMID",
		statText="+HP, slight slow", hpBonus=20, damageBonus=0, speedBonus=-1, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="IHeartFLShirt", name="I♥FL Shirt", description="Tourist camouflage. +swagger.", rarity="Rare", inscription="CHAOS",
		statText="+Luck +HP", hpBonus=10, damageBonus=0, speedBonus=0, luckBonus=0.08, dodgeBonus=0, healOnPickup=0, special="" },
	{ id="NoveltyMug", name="Novelty Mug", description="Says WORLD'S OKAYEST FLORIDA MAN. Holds Florida Dew vibes.", rarity="Rare", inscription="HUMID",
		statText="Heal on stage clear", hpBonus=5, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=0, special="stageHeal" },
	{ id="TurtleSticker", name="Turtle Sticker", description="Never harm turtles. This sticker agrees.", rarity="Rare", inscription="HEROIC",
		statText="+Damage vs GulfGulp", hpBonus=0, damageBonus=2, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=5, special="antiCorp" },
	{ id="GasStationTaquito", name="Gas-Station Taquito", description="Rolling since Tuesday. Heal now, regret never (cartoon).", rarity="Common", inscription="GREASY",
		statText="Instant heal", hpBonus=0, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0, healOnPickup=25, special="" },
	{ id="LawnDart", name="Lawn Dart", description="Banned in 12 HOAs. Still flies true.", rarity="Rare", inscription="CHAOS",
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
		statText="+Resist oil spit", hpBonus=15, damageBonus=0, speedBonus=0, luckBonus=0, dodgeBonus=0.05, healOnPickup=0, special="absorb" },
	{ id="LabBadge", name="Lab Badge", description="GulfGulp Energy — TEMPORARY. Very temporary.", rarity="Legendary", inscription="GREASY",
		statText="+All stats vs finale", hpBonus=20, damageBonus=6, speedBonus=1, luckBonus=0.1, dodgeBonus=0, healOnPickup=0, special="badge" },
}

Items.List = list
Items.ById = {} :: { [string]: ItemDef }
for _, it in list do
	Items.ById[it.id] = it
end

Items.SetBonuses = {
	HUMID = { name = "Swamp Sweat", text = "+10% dodge window feel / +8 HP", hpBonus = 8, dodgeBonus = 0.05 },
	FERAL = { name = "Bite Back", text = "+12% damage", damageBonus = 0.12 },
	LUCKY = { name = "Pelican Favor", text = "+better draft rarity", luckBonus = 0.2 },
	GREASY = { name = "Deep Fry Defense", text = "+15 HP, oil resist", hpBonus = 15 },
	HEROIC = { name = "Turtle Oath", text = "+heal 2 HP on hit", special = "lifesteal" },
	CHAOS = { name = "Headline Energy", text = "+skill damage burst", damageBonus = 0.08 },
}

function Items.Get(id: string): ItemDef?
	return Items.ById[id]
end

function Items.RollDraft(rng: Random, luck: number, count: number): { ItemDef }
	local pool = table.clone(list)
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
