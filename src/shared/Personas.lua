--!strict
--[[
	Persona catalog — dual-persona Skul-like kit.
	Each persona: unique attack feel, skill, moveSpeed, swap-attack punch.
]]

local Personas = {}

export type PersonaDef = {
	id: string,
	name: string,
	description: string,
	color: Color3,
	accent: Color3,
	attackDamage: number,
	attackSpeed: number,
	moveSpeed: number,
	skillName: string,
	skillDescription: string,
	skillCooldown: number,
	skillDamage: number,
	skillKind: string, -- "wave" | "dash" | "aoe" | "summon" | "buff" | "beam" | "shield"
	unlockHint: string,
	starter: boolean?,
}

local list: { PersonaDef } = {
	{
		id = "BeachBurnout",
		name = "Beach Burnout",
		description = "Woke up sandy. Still got rhythm. Starter persona of legend.",
		color = Color3.fromRGB(255, 196, 72),
		accent = Color3.fromRGB(255, 120, 40),
		attackDamage = 12,
		attackSpeed = 1.0,
		moveSpeed = 18,
		skillName = "Bonfire Shuffle",
		skillDescription = "Spin-kick wave of hot sand. Hits in a cone.",
		skillCooldown = 5,
		skillDamage = 28,
		skillKind = "wave",
		unlockHint = "Start the run.",
		starter = true,
	},
	{
		id = "CrabKing",
		name = "Crab King",
		description = "Sideways swagger. Pinch first, ask never.",
		color = Color3.fromRGB(220, 60, 60),
		accent = Color3.fromRGB(255, 180, 180),
		attackDamage = 14,
		attackSpeed = 0.95,
		moveSpeed = 16,
		skillName = "Royal Pinch",
		skillDescription = "Dash forward with a heavy pinch through the lane.",
		skillCooldown = 6,
		skillDamage = 36,
		skillKind = "dash",
		unlockHint = "Defeat the Crab King on Daytona Hangover Beach.",
	},
	{
		id = "GatorHauler",
		name = "Gator Hauler",
		description = "Borrowed a wrestling hold from a science experiment.",
		color = Color3.fromRGB(40, 120, 70),
		accent = Color3.fromRGB(20, 60, 30),
		attackDamage = 16,
		attackSpeed = 0.85,
		moveSpeed = 15,
		skillName = "Tailgate Toss",
		skillDescription = "Grab the lane and slam — heavy AOE.",
		skillCooldown = 7,
		skillDamage = 42,
		skillKind = "aoe",
		unlockHint = "Defeat the Drive-Thru Gator in Drive-Thru Disaster.",
	},
	{
		id = "SnakeCharmer",
		name = "Snake Charmer",
		description = "Hisses back. Somehow it works.",
		color = Color3.fromRGB(120, 200, 90),
		accent = Color3.fromRGB(60, 140, 40),
		attackDamage = 11,
		attackSpeed = 1.15,
		moveSpeed = 19,
		skillName = "Coil Call",
		skillDescription = "Summon a friendly coil that lingers and bites for 2s.",
		skillCooldown = 8,
		skillDamage = 30,
		skillKind = "summon",
		unlockHint = "Defeat a Cottonmouth, first found in Canal Run.",
	},
	{
		id = "GolfCartBandit",
		name = "Golf Cart Bandit",
		description = "HOA's most wanted. Top speed: legally unclear.",
		color = Color3.fromRGB(90, 200, 255),
		accent = Color3.fromRGB(40, 100, 160),
		attackDamage = 10,
		attackSpeed = 1.25,
		moveSpeed = 22,
		skillName = "Cartwheel Drive-By",
		skillDescription = "Dash through the lane with armor frames and one heavy scrape per enemy.",
		skillCooldown = 5.5,
		skillDamage = 24,
		skillKind = "dash",
		unlockHint = "Defeat the Slushie King or clear Gas Station of Legends.",
	},
	{
		id = "FireworksEnthusiast",
		name = "Fireworks Enthusiast",
		description = "Safety third. Sparks first.",
		color = Color3.fromRGB(255, 80, 120),
		accent = Color3.fromRGB(255, 220, 60),
		attackDamage = 13,
		attackSpeed = 1.05,
		moveSpeed = 17,
		skillName = "Illegal Finale",
		skillDescription = "Pop a burst of cartoon rockets in a radius.",
		skillCooldown = 7.5,
		skillDamage = 38,
		skillKind = "aoe",
		unlockHint = "Defeat the Spillfather and rescue the final turtles.",
	},
	{
		id = "LizardBreath",
		name = "Lizard Breath",
		description = "Learned from fire-breathing lizards. HR approved? No.",
		color = Color3.fromRGB(255, 90, 30),
		accent = Color3.fromRGB(255, 220, 80),
		attackDamage = 15,
		attackSpeed = 0.9,
		moveSpeed = 17,
		skillName = "Swamp Exhale",
		skillDescription = "Flame breath beam — extra damage against Oil Gators.",
		skillCooldown = 6.5,
		skillDamage = 40,
		skillKind = "beam",
		unlockHint = "Defeat fire lizards in The Swamp Shift.",
	},
	{
		id = "TurtlePaladin",
		name = "Turtle Paladin",
		description = "Shell up. Save the babies. Smite GulfGulp.",
		color = Color3.fromRGB(70, 160, 140),
		accent = Color3.fromRGB(200, 255, 220),
		attackDamage = 14,
		attackSpeed = 0.9,
		moveSpeed = 15,
		skillName = "Shell Sanctuary",
		skillDescription = "Heal 18 HP and ready a shell that absorbs incoming damage.",
		skillCooldown = 9,
		skillDamage = 18,
		skillKind = "shield",
		unlockHint = "Rescue turtles at Turtle Beach / Red Tide.",
	},
}

Personas.List = list
Personas.ById = {} :: { [string]: PersonaDef }
for _, p in list do
	Personas.ById[p.id] = p
end

function Personas.Get(id: string): PersonaDef?
	return Personas.ById[id]
end

function Personas.GetStarter(): PersonaDef
	return Personas.ById.BeachBurnout
end

function Personas.AllIds(): { string }
	local ids = {}
	for _, p in list do
		table.insert(ids, p.id)
	end
	return ids
end

return Personas
