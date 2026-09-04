--!strict
--[[ Stage progression — Hub through GulfGulp Rig finale. ]]

local Stages = {}

export type WaveSpawn = { enemyId: string, count: number, atProgress: number }
export type StageDef = {
	id: string,
	index: number,
	name: string,
	headline: string,
	blurb: string,
	length: number,
	groundColor: Color3,
	accentColor: Color3,
	fogColor: Color3,
	clockTime: number,
	waves: { WaveSpawn },
	miniboss: string?,
	boss: string?,
	unlockPersona: string?,
	rescueTurtles: number,
	showMutantTagline: boolean,
	isHub: boolean,
	coldOnePickup: boolean,
	hangover: boolean,
	propTheme: string,
}

local list: { StageDef } = {
	{
		id = "Hub", index = 0, name = "Dawn Bonfire",
		headline = "FLORIDA MAN — you danced until the fire died. The crabs stole your Cold One.",
		blurb = "Wake on the beach. Touch the bonfire to start your legend.",
		length = 60, groundColor = Color3.fromRGB(210, 180, 110), accentColor = Color3.fromRGB(255, 140, 40),
		fogColor = Color3.fromRGB(180, 200, 220), clockTime = 6.2,
		waves = {}, miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = true, coldOnePickup = false, hangover = false, propTheme = "beach",
	},
	{
		id = "DaytonaHangover", index = 1, name = "Daytona Hangover Beach",
		headline = "BREAKING: Florida Man chases crabs for stolen Cold One — experts blame 'vibes'",
		blurb = "Tutorial crabs. Reclaim The Cold One (Florida Dew). Face the Crab King.",
		length = 220, groundColor = Color3.fromRGB(220, 190, 120), accentColor = Color3.fromRGB(70, 160, 220),
		fogColor = Color3.fromRGB(200, 220, 240), clockTime = 7.5,
		waves = {
			{ enemyId = "BeachCrab", count = 3, atProgress = 0.12 },
			{ enemyId = "BeachCrab", count = 4, atProgress = 0.35 },
			{ enemyId = "BeachCrab", count = 5, atProgress = 0.55 },
		},
		miniboss = "CrabKingBoss", boss = nil, unlockPersona = "CrabKing", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = true, hangover = true, propTheme = "beach",
	},
	{
		id = "GasStationLegends", index = 2, name = "Gas Station of Legends",
		headline = "BREAKING: Florida Man declares war on slushie machine — HOA watching",
		blurb = "Parody convenience-store chaos. Tourists. Sticky floors. Golf-cart energy.",
		length = 240, groundColor = Color3.fromRGB(60, 60, 65), accentColor = Color3.fromRGB(255, 200, 40),
		fogColor = Color3.fromRGB(40, 45, 55), clockTime = 14,
		waves = {
			{ enemyId = "AngryTourist", count = 2, atProgress = 0.1 },
			{ enemyId = "SlushieSlime", count = 2, atProgress = 0.25 },
			{ enemyId = "AngryTourist", count = 3, atProgress = 0.4 },
			{ enemyId = "SlushieSlime", count = 3, atProgress = 0.55 },
			{ enemyId = "AngryTourist", count = 2, atProgress = 0.7 },
		},
		miniboss = nil, boss = nil, unlockPersona = "GolfCartBandit", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false, propTheme = "gas",
	},
	{
		id = "DriveThruDisaster", index = 3, name = "Drive-Thru Disaster",
		headline = "BREAKING: Drive-thru gator refuses to supersize — radio collar beeping suspiciously",
		blurb = "Miniboss Drive-Thru Gator. Radio collar hint: science experiment gone wrong.",
		length = 240, groundColor = Color3.fromRGB(90, 100, 70), accentColor = Color3.fromRGB(255, 80, 40),
		fogColor = Color3.fromRGB(120, 130, 90), clockTime = 16,
		waves = {
			{ enemyId = "AngryTourist", count = 2, atProgress = 0.15 },
			{ enemyId = "BeachCrab", count = 3, atProgress = 0.3 },
			{ enemyId = "SlushieSlime", count = 2, atProgress = 0.45 },
		},
		miniboss = "DriveThruGator", boss = nil, unlockPersona = "GatorHauler", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false, propTheme = "drive",
	},
	{
		id = "SwampShift", index = 4, name = "The Swamp Shift",
		headline = "BREAKING: Mutant wildlife sighted — Captain Steve says 'It IS Florida…'",
		blurb = "Snakes, then mutant oil-gators + fire lizards. Captain Steve sting.",
		length = 280, groundColor = Color3.fromRGB(40, 70, 45), accentColor = Color3.fromRGB(120, 200, 60),
		fogColor = Color3.fromRGB(50, 80, 55), clockTime = 19,
		waves = {
			{ enemyId = "Cottonmouth", count = 3, atProgress = 0.1 },
			{ enemyId = "Cottonmouth", count = 4, atProgress = 0.25 },
			{ enemyId = "OilGator", count = 2, atProgress = 0.4 },
			{ enemyId = "FireLizard", count = 3, atProgress = 0.5 },
			{ enemyId = "OilGator", count = 2, atProgress = 0.65 },
			{ enemyId = "FireLizard", count = 3, atProgress = 0.75 },
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = "LizardBreath", rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false, propTheme = "swamp",
	},
	{
		id = "TurtleBeach", index = 5, name = "Turtle Beach / Red Tide",
		headline = "BREAKING: Florida Man vs GulfGulp Energy — turtles demand snacks and justice",
		blurb = "Rescue turtles from GulfGulp. Unlock Turtle Paladin. Never harm turtles.",
		length = 260, groundColor = Color3.fromRGB(180, 140, 90), accentColor = Color3.fromRGB(220, 60, 80),
		fogColor = Color3.fromRGB(160, 80, 90), clockTime = 17.5,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.12 },
			{ enemyId = "OilGator", count = 2, atProgress = 0.28 },
			{ enemyId = "GulfGulpGrunt", count = 3, atProgress = 0.45 },
			{ enemyId = "FireLizard", count = 2, atProgress = 0.6 },
			{ enemyId = "GulfGulpGrunt", count = 3, atProgress = 0.75 },
		},
		miniboss = nil, boss = nil, unlockPersona = "TurtlePaladin", rescueTurtles = 5,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false, propTheme = "turtle",
	},
	{
		id = "GulfGulpRig", index = 6, name = "GulfGulp Rig",
		headline = "BREAKING: The Spillfather makes an offer Florida Man can't refuse (he refuses)",
		blurb = "Finale. The Spillfather + mutant adds. Save the swamp. Credits.",
		length = 300, groundColor = Color3.fromRGB(35, 38, 45), accentColor = Color3.fromRGB(255, 150, 0),
		fogColor = Color3.fromRGB(30, 32, 40), clockTime = 21,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 3, atProgress = 0.1 },
			{ enemyId = "OilGator", count = 2, atProgress = 0.22 },
			{ enemyId = "MutantAdd", count = 3, atProgress = 0.35 },
			{ enemyId = "FireLizard", count = 2, atProgress = 0.45 },
		},
		miniboss = nil, boss = "Spillfather", unlockPersona = "FireworksEnthusiast", rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false, propTheme = "rig",
	},
}

Stages.List = list
Stages.ById = {} :: { [string]: StageDef }
Stages.Order = {} :: { string }
for _, s in list do
	Stages.ById[s.id] = s
	if not s.isHub then
		table.insert(Stages.Order, s.id)
	end
end

function Stages.Get(id: string): StageDef?
	return Stages.ById[id]
end

function Stages.GetByIndex(index: number): StageDef?
	for _, s in list do
		if s.index == index then
			return s
		end
	end
	return nil
end

function Stages.NextAfter(id: string): StageDef?
	local cur = Stages.ById[id]
	if not cur then
		return nil
	end
	return Stages.GetByIndex(cur.index + 1)
end

return Stages
