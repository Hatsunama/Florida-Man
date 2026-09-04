--!strict
--[[ Stage progression — coherent campaign arc. 20 combat stages + hub.
	Extended fields: hazards, setPiece, lighting, storyBeat, scalingTier, goalLabel, steveAct.
]]

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
	biome: string,
	setPiece: string,
	hazards: { string },
	lighting: string,
	storyBeat: string,
	scalingTier: number,
	goalLabel: string,
	steveAct: number,
	platformLedges: number,
}

local list: { StageDef } = {
	{
		id = "Hub", index = 0, name = "Dawn Bonfire",
		headline = "FLORIDA MAN — you danced until the fire died. The crabs stole your Cold One.",
		blurb = "Wake on the beach. Press E at the bonfire (or click the prompt) to start your legend.",
		length = 70, groundColor = Color3.fromRGB(210, 180, 110), accentColor = Color3.fromRGB(255, 140, 40),
		fogColor = Color3.fromRGB(180, 200, 220), clockTime = 6.2,
		waves = {}, miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = true, coldOnePickup = false, hangover = false,
		propTheme = "beach", biome = "beach", setPiece = "hubBonfire", hazards = {},
		lighting = "dawnGold", storyBeat = "Wake after the last honest night of your life.",
		scalingTier = 0, goalLabel = "BONFIRE", steveAct = 1, platformLedges = 0,
	},
	-- ACT 1: Hangover Coast (1–5)
	{
		id = "DaytonaHangover", index = 1, name = "Daytona Hangover Beach",
		headline = "VIRAL: Florida Man wakes to missing Florida Dew — crabs named persons of interest",
		blurb = "Comedy first. Reclaim The Cold One. Face the King of the Tide Pool. Hangover wears off with the can.",
		length = 200, groundColor = Color3.fromRGB(220, 190, 120), accentColor = Color3.fromRGB(70, 160, 220),
		fogColor = Color3.fromRGB(200, 220, 240), clockTime = 7.5,
		waves = {
			{ enemyId = "BeachCrab", count = 2, atProgress = 0.15 },
			{ enemyId = "SandFlea", count = 2, atProgress = 0.35 },
			{ enemyId = "BeachCrab", count = 2, atProgress = 0.55 },
		},
		miniboss = "CrabKingBoss", boss = nil, unlockPersona = "CrabKing", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = true, hangover = true,
		propTheme = "beach", biome = "beach", setPiece = "collapsingPier", hazards = { "sandSlow" },
		lighting = "dawnGold", storyBeat = "Comedy first: reclaim the Cold One. The collar beeps come later.",
		scalingTier = 1, goalLabel = "PIER LIGHT →", steveAct = 1, platformLedges = 0,
	},
	{
		id = "BoardwalkChaos", index = 2, name = "Boardwalk Chaos",
		headline = "BOARDWALK: Influencer selfie-flash blinds vendors — runaway hotdog cart declared sovereign",
		blurb = "Tourists, fleas, mustard trails. Keep your flip-flops. Jump the fryer oil.",
		length = 220, groundColor = Color3.fromRGB(200, 170, 100), accentColor = Color3.fromRGB(255, 100, 80),
		fogColor = Color3.fromRGB(190, 210, 230), clockTime = 10,
		waves = {
			{ enemyId = "AngryTourist", count = 1, atProgress = 0.12 },
			{ enemyId = "SandFlea", count = 2, atProgress = 0.28 },
			{ enemyId = "SelfieZombie", count = 1, atProgress = 0.45 },
			{ enemyId = "HotDogCart", count = 1, atProgress = 0.62 },
			{ enemyId = "AngryTourist", count = 2, atProgress = 0.78 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "beach", biome = "beach", setPiece = "fryerOil", hazards = { "fryerOil", "hoaCone" },
		lighting = "midBeach", storyBeat = "Comedy still sells. Something beeps under a tourist's cooler.",
		scalingTier = 1, goalLabel = "BOARDWALK EXIT →", steveAct = 1, platformLedges = 1,
	},
	{
		id = "GasStationLegends", index = 3, name = "Gas Station of Legends",
		headline = "NEON: Slushie machine files restraining order — HOA binder cited as blunt instrument",
		blurb = "Sticky floors. Neon pumps. Unlock Golf Cart Bandit energy.",
		length = 230, groundColor = Color3.fromRGB(55, 55, 60), accentColor = Color3.fromRGB(255, 200, 40),
		fogColor = Color3.fromRGB(35, 40, 50), clockTime = 14,
		waves = {
			{ enemyId = "AngryTourist", count = 1, atProgress = 0.1 },
			{ enemyId = "SlushieSlime", count = 2, atProgress = 0.28 },
			{ enemyId = "SelfieZombie", count = 1, atProgress = 0.45 },
			{ enemyId = "CondoKaren", count = 1, atProgress = 0.65 },
		},
		miniboss = "SlushieKing", boss = nil, unlockPersona = "GolfCartBandit", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "gas", biome = "town", setPiece = "neonCanopy", hazards = { "slushPuddle", "hoaCone" },
		lighting = "neonGas", storyBeat = "Parody convenience-store chaos. Still funny. Still uneasy.",
		scalingTier = 1, goalLabel = "OPEN 24HRS →", steveAct = 1, platformLedges = 1,
	},
	{
		id = "StripMallShowdown", index = 4, name = "Strip Mall Showdown",
		headline = "PARKING LOT: Karen requests supervisor of physics — clipboard hydra forms",
		blurb = "Clipboards, carts, flash stuns. Chaos rhythm unlocks.",
		length = 230, groundColor = Color3.fromRGB(70, 70, 75), accentColor = Color3.fromRGB(255, 80, 120),
		fogColor = Color3.fromRGB(50, 55, 65), clockTime = 15,
		waves = {
			{ enemyId = "CondoKaren", count = 1, atProgress = 0.12 },
			{ enemyId = "HotDogCart", count = 1, atProgress = 0.3 },
			{ enemyId = "SelfieZombie", count = 2, atProgress = 0.48 },
			{ enemyId = "AngryTourist", count = 2, atProgress = 0.68 },
		},
		miniboss = "HOAHydra", boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "gas", biome = "town", setPiece = "parkingArena", hazards = { "hoaCone" },
		lighting = "stripMall", storyBeat = "Last pure comedy beat before the collar beeps.",
		scalingTier = 1, goalLabel = "MALL EXIT →", steveAct = 1, platformLedges = 1,
	},
	{
		id = "DriveThruDisaster", index = 5, name = "Drive-Thru Disaster",
		headline = "UNEASE: Drive-thru gator refuses to supersize — GulfGulp radio collar beeping on live stream",
		blurb = "Miniboss Drive-Thru Gator. First radio collar. Science experiment gone wrong.",
		length = 240, groundColor = Color3.fromRGB(90, 100, 70), accentColor = Color3.fromRGB(255, 80, 40),
		fogColor = Color3.fromRGB(120, 130, 90), clockTime = 16,
		waves = {
			{ enemyId = "AngryTourist", count = 1, atProgress = 0.15 },
			{ enemyId = "BeachCrab", count = 2, atProgress = 0.32 },
			{ enemyId = "SlushieSlime", count = 1, atProgress = 0.5 },
			{ enemyId = "HotDogCart", count = 1, atProgress = 0.65 },
		},
		miniboss = "DriveThruGator", boss = nil, unlockPersona = "GatorHauler", rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "drive", biome = "town", setPiece = "driveThruLane", hazards = { "fryerOil" },
		lighting = "lateAfternoon", storyBeat = "The collar is the first real clue. Comedy cracks.",
		scalingTier = 1, goalLabel = "ORDER WINDOW →", steveAct = 1, platformLedges = 1,
	},
	-- ACT 2: The Swamp That Isn't Wild (6–10)
	{
		id = "CanalRun", index = 6, name = "Canal Run",
		headline = "CANAL: Jet-ski bandits rewrite wake rules — cottonmouths rattle a warning first",
		blurb = "Water edges, jump pads, burrow snakes. Depth optional. Chaos mandatory.",
		length = 250, groundColor = Color3.fromRGB(70, 110, 90), accentColor = Color3.fromRGB(40, 160, 220),
		fogColor = Color3.fromRGB(100, 140, 130), clockTime = 11,
		waves = {
			{ enemyId = "JetSkiBandit", count = 1, atProgress = 0.1 },
			{ enemyId = "BurrowSnake", count = 2, atProgress = 0.28 },
			{ enemyId = "Cottonmouth", count = 2, atProgress = 0.48 },
			{ enemyId = "JetSkiBandit", count = 1, atProgress = 0.65 },
			{ enemyId = "MosquitoCloud", count = 2, atProgress = 0.8 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "drive", biome = "swamp", setPiece = "canalPads", hazards = { "canalWater" },
		lighting = "swampGreen", storyBeat = "Snakes first. Mutants next. Steve is watching.",
		scalingTier = 2, goalLabel = "LOCK GATE →", steveAct = 2, platformLedges = 3,
	},
	{
		id = "SwampShift", index = 7, name = "The Swamp Shift",
		headline = "STEVE: 'It IS Florida… Anything is possible in the swamp I guess.' — oil gators confirmed",
		blurb = "Mutant oil-gators + fire lizards. Captain Steve sting. Animals aren't the enemy.",
		length = 280, groundColor = Color3.fromRGB(40, 70, 45), accentColor = Color3.fromRGB(120, 200, 60),
		fogColor = Color3.fromRGB(50, 80, 55), clockTime = 19,
		waves = {
			{ enemyId = "Cottonmouth", count = 2, atProgress = 0.1 },
			{ enemyId = "MosquitoCloud", count = 2, atProgress = 0.22 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.38 },
			{ enemyId = "FireLizard", count = 2, atProgress = 0.52 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.68 },
			{ enemyId = "EmberSkink", count = 2, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = "LizardBreath", rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "swamp", biome = "swamp", setPiece = "cypressCanopy", hazards = { "oilSlick", "fireCone" },
		lighting = "greenBlack", storyBeat = "Steve says the line once. Then you see the collars — animals aren't the enemy.",
		scalingTier = 2, goalLabel = "CYPRESS PASS →", steveAct = 2, platformLedges = 2,
	},
	{
		id = "CypressCathedral", index = 8, name = "Cypress Cathedral",
		headline = "CATHEDRAL: Summoner hosts swamp open mic — cottonmouths RSVP under collars",
		blurb = "Summoners, burrowers, cypress gloom. Keep hissing back.",
		length = 260, groundColor = Color3.fromRGB(35, 60, 40), accentColor = Color3.fromRGB(160, 100, 255),
		fogColor = Color3.fromRGB(40, 70, 50), clockTime = 20,
		waves = {
			{ enemyId = "SwampSummoner", count = 1, atProgress = 0.15 },
			{ enemyId = "Cottonmouth", count = 2, atProgress = 0.32 },
			{ enemyId = "BurrowSnake", count = 2, atProgress = 0.5 },
			{ enemyId = "SwampSummoner", count = 1, atProgress = 0.7 },
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.85 },
		},
		miniboss = nil, boss = nil, unlockPersona = "SnakeCharmer", rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "swamp", biome = "swamp", setPiece = "cypressCanopy", hazards = { "oilSlick" },
		lighting = "greenBlack", storyBeat = "The conspiracy gets a soundtrack.",
		scalingTier = 2, goalLabel = "ROOT BRIDGE →", steveAct = 2, platformLedges = 2,
	},
	{
		id = "SludgeBayou", index = 9, name = "Sludge Bayou",
		headline = "BAYOU: Oil puddles elect themselves mayor — GulfGulp drones take attendance",
		blurb = "Puddle layers and collared oil gators. Skim or slip.",
		length = 260, groundColor = Color3.fromRGB(30, 45, 35), accentColor = Color3.fromRGB(255, 160, 40),
		fogColor = Color3.fromRGB(35, 50, 40), clockTime = 18.5,
		waves = {
			{ enemyId = "OilPuddleLayer", count = 1, atProgress = 0.12 },
			{ enemyId = "OilGator", count = 2, atProgress = 0.3 },
			{ enemyId = "EmberSkink", count = 2, atProgress = 0.48 },
			{ enemyId = "OilPuddleLayer", count = 2, atProgress = 0.65 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "swamp", biome = "swamp", setPiece = "sludgeFlats", hazards = { "oilSlick", "fireCone" },
		lighting = "greenBlack", storyBeat = "Sludge trails lead toward a logo.",
		scalingTier = 2, goalLabel = "BAYOU MOUTH →", steveAct = 2, platformLedges = 2,
	},
	{
		id = "ConspiracyShack", index = 10, name = "Conspiracy Shack",
		headline = "SHACK: Corkboard links pelicans, collars, and GulfGulp stock — lab coats arrive early",
		blurb = "Bully pelicans and lab coats. The conspiracy gets loud.",
		length = 250, groundColor = Color3.fromRGB(80, 70, 55), accentColor = Color3.fromRGB(255, 220, 80),
		fogColor = Color3.fromRGB(70, 65, 50), clockTime = 17,
		waves = {
			{ enemyId = "PelicanBully", count = 1, atProgress = 0.1 },
			{ enemyId = "LabCoat", count = 2, atProgress = 0.3 },
			{ enemyId = "DroneSpotter", count = 2, atProgress = 0.48 },
			{ enemyId = "PelicanBully", count = 1, atProgress = 0.65 },
			{ enemyId = "LabCoat", count = 2, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "swamp", biome = "swamp", setPiece = "corkboardShack", hazards = { "oilSlick" },
		lighting = "swampGreen", storyBeat = "Evidence on a corkboard. Next stop: turtle nests.",
		scalingTier = 2, goalLabel = "DIRT ROAD →", steveAct = 2, platformLedges = 1,
	},
	-- ACT 3: Red Tide Bargain (11–12)
	{
		id = "TurtleBeach", index = 11, name = "Turtle Beach / Red Tide",
		headline = "RED TIDE: GulfGulp 'cleanup' crew oils nests — Florida Man declares turtles under protection",
		blurb = "Rescue turtles. Their cleanup is a cover. Unlock Turtle Paladin.",
		length = 260, groundColor = Color3.fromRGB(180, 140, 90), accentColor = Color3.fromRGB(220, 60, 80),
		fogColor = Color3.fromRGB(160, 80, 90), clockTime = 17.5,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.12 },
			{ enemyId = "RedTideBlob", count = 1, atProgress = 0.3 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.48 },
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.65 },
			{ enemyId = "FireLizard", count = 1, atProgress = 0.8 },
		},
		miniboss = nil, boss = nil, unlockPersona = "TurtlePaladin", rescueTurtles = 5,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "turtle", biome = "beach", setPiece = "turtleNests", hazards = { "redTide", "oilSlick" },
		lighting = "redTide", storyBeat = "Rescue is the mission. Pipelines wanted 'no habitat.'",
		scalingTier = 3, goalLabel = "NEST LIGHT →", steveAct = 3, platformLedges = 1,
	},
	{
		id = "NestGuard", index = 12, name = "Nest Guard Night",
		headline = "NEST WATCH: Drones clock in for overtime — baby turtles demand snacks and justice",
		blurb = "More turtles to free. Red tide and mark-drones try to stop you.",
		length = 250, groundColor = Color3.fromRGB(160, 120, 80), accentColor = Color3.fromRGB(100, 255, 180),
		fogColor = Color3.fromRGB(40, 50, 70), clockTime = 21.5,
		waves = {
			{ enemyId = "DroneSpotter", count = 2, atProgress = 0.1 },
			{ enemyId = "RedTideBlob", count = 2, atProgress = 0.3 },
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.5 },
			{ enemyId = "OilPuddleLayer", count = 1, atProgress = 0.72 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 4,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "turtle", biome = "beach", setPiece = "turtleNests", hazards = { "redTide" },
		lighting = "nightNest", storyBeat = "Shell up. The facility gate is next.",
		scalingTier = 3, goalLabel = "SAFE NEST →", steveAct = 3, platformLedges = 2,
	},
	-- ACT 4: Inside GulfGulp (13–19)
	{
		id = "GulfGulpGate", index = 13, name = "GulfGulp Gate",
		headline = "GATE: 'Authorized personnel only' — Florida Man cites pelican testimony",
		blurb = "First look at the facilities. Hazmat grunts and welders.",
		length = 270, groundColor = Color3.fromRGB(45, 48, 55), accentColor = Color3.fromRGB(255, 170, 40),
		fogColor = Color3.fromRGB(35, 38, 48), clockTime = 19.5,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.1 },
			{ enemyId = "RigWelder", count = 1, atProgress = 0.28 },
			{ enemyId = "BarrelRoller", count = 2, atProgress = 0.48 },
			{ enemyId = "DroneSpotter", count = 2, atProgress = 0.65 },
			{ enemyId = "LabCoat", count = 1, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "facility", setPiece = "corpGate", hazards = { "oilSlick", "hoaCone" },
		lighting = "clinicalLab", storyBeat = "Inside the logo. No more jokes about vibes.",
		scalingTier = 4, goalLabel = "BADGE SCAN →", steveAct = 4, platformLedges = 2,
	},
	{
		id = "LabWing", index = 14, name = "Mutant Lab Wing",
		headline = "LAB FILE: 'Engineered gators to guard spills' — memo stamped CONFIDENTIAL, still sticky",
		blurb = "Mutant adds, fire lizards, collared gators. Evidence everywhere.",
		length = 270, groundColor = Color3.fromRGB(40, 50, 55), accentColor = Color3.fromRGB(80, 220, 120),
		fogColor = Color3.fromRGB(30, 45, 50), clockTime = 20,
		waves = {
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.1 },
			{ enemyId = "FireLizard", count = 1, atProgress = 0.25 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.42 },
			{ enemyId = "LabCoat", count = 2, atProgress = 0.58 },
			{ enemyId = "EmberSkink", count = 2, atProgress = 0.75 },
			{ enemyId = "MutantAdd", count = 1, atProgress = 0.88 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "facility", setPiece = "labConveyor", hazards = { "fireCone", "oilSlick" },
		lighting = "clinicalLab", storyBeat = "They engineered the gators. The memo is the smoking gun.",
		scalingTier = 4, goalLabel = "LAB EXIT →", steveAct = 4, platformLedges = 2,
	},
	{
		id = "PipeGauntlet", index = 15, name = "Pipe Gauntlet",
		headline = "PIPES: Barrel rollers unionize mid-gauntlet — Rig Overlord clocks in early",
		blurb = "Pipe-maze platforms. Chargers in metal halls. Keep your footing.",
		length = 280, groundColor = Color3.fromRGB(35, 38, 45), accentColor = Color3.fromRGB(255, 120, 40),
		fogColor = Color3.fromRGB(25, 28, 35), clockTime = 21,
		waves = {
			{ enemyId = "BarrelRoller", count = 2, atProgress = 0.1 },
			{ enemyId = "RigWelder", count = 1, atProgress = 0.3 },
			{ enemyId = "BarrelRoller", count = 2, atProgress = 0.5 },
			{ enemyId = "OilPuddleLayer", count = 1, atProgress = 0.68 },
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.82 },
		},
		miniboss = "RigOverlord", boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "facility", setPiece = "pipeMaze", hazards = { "oilSlick", "fireCone" },
		lighting = "industrialOrange", storyBeat = "Middle management of doom blocks the docks.",
		scalingTier = 4, goalLabel = "VALVE LOCK →", steveAct = 4, platformLedges = 3,
	},
	{
		id = "LoadingDock", index = 16, name = "Loading Dock Riot",
		headline = "DOCK: Offshore crabs punch in late — corporate security loses clipboard war",
		blurb = "Offshore crabs meet hazmat. Sideways vs clipboard.",
		length = 260, groundColor = Color3.fromRGB(50, 55, 60), accentColor = Color3.fromRGB(200, 60, 60),
		fogColor = Color3.fromRGB(40, 50, 70), clockTime = 16.5,
		waves = {
			{ enemyId = "OffshoreCrab", count = 2, atProgress = 0.12 },
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.32 },
			{ enemyId = "HermitCrab", count = 1, atProgress = 0.5 },
			{ enemyId = "BarrelRoller", count = 2, atProgress = 0.68 },
			{ enemyId = "OffshoreCrab", count = 2, atProgress = 0.85 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "facility", setPiece = "loadingDock", hazards = { "oilSlick" },
		lighting = "industrialOrange", storyBeat = "The barge is loading. You are not invited — you go anyway.",
		scalingTier = 4, goalLabel = "CRANE LIGHT →", steveAct = 4, platformLedges = 2,
	},
	{
		id = "BargeCrossing", index = 17, name = "Barge Crossing",
		headline = "BARGE: Storm pelicans claim airspace — gaps in the deck rated 'Florida'",
		blurb = "Barge gaps. Hoppers and jet-ski leftovers. Don't fall in the joke.",
		length = 270, groundColor = Color3.fromRGB(55, 70, 80), accentColor = Color3.fromRGB(120, 180, 255),
		fogColor = Color3.fromRGB(80, 100, 120), clockTime = 15,
		waves = {
			{ enemyId = "StormPelican", count = 1, atProgress = 0.1 },
			{ enemyId = "JetSkiBandit", count = 1, atProgress = 0.28 },
			{ enemyId = "OffshoreCrab", count = 2, atProgress = 0.48 },
			{ enemyId = "StormPelican", count = 2, atProgress = 0.65 },
			{ enemyId = "DroneSpotter", count = 2, atProgress = 0.82 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "offshore", setPiece = "bargeGaps", hazards = { "canalWater", "oilSlick" },
		lighting = "offshoreWind", storyBeat = "Jump the gaps. The platform is a silhouette ahead.",
		scalingTier = 4, goalLabel = "FAR DECK →", steveAct = 4, platformLedges = 3,
	},
	{
		id = "OilPlatformApproach", index = 18, name = "Oil Platform Approach",
		headline = "PLATFORM: Approach rated hostile by anonymous pelican — slicks bloom under the rig",
		blurb = "Welders, drones, slicks. Finale is close.",
		length = 280, groundColor = Color3.fromRGB(40, 42, 50), accentColor = Color3.fromRGB(255, 140, 20),
		fogColor = Color3.fromRGB(30, 32, 40), clockTime = 20.5,
		waves = {
			{ enemyId = "RigWelder", count = 2, atProgress = 0.1 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.26 },
			{ enemyId = "DroneSpotter", count = 2, atProgress = 0.42 },
			{ enemyId = "FireLizard", count = 1, atProgress = 0.58 },
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.72 },
			{ enemyId = "BarrelRoller", count = 1, atProgress = 0.88 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "offshore", setPiece = "platformApproach", hazards = { "oilSlick", "fireCone" },
		lighting = "industrialOrange", storyBeat = "The helipad waits. So does the Spillfather.",
		scalingTier = 4, goalLabel = "RIG FLARE →", steveAct = 4, platformLedges = 2,
	},
	{
		id = "HelipadHysteria", index = 19, name = "Helipad Hysteria",
		headline = "HELIPAD: Closed for mutant maintenance — wind push rated 'personality'",
		blurb = "Last security wave. Wind push set piece. Then the sludge mech.",
		length = 250, groundColor = Color3.fromRGB(50, 52, 58), accentColor = Color3.fromRGB(255, 80, 60),
		fogColor = Color3.fromRGB(35, 30, 40), clockTime = 21.5,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.1 },
			{ enemyId = "LabCoat", count = 1, atProgress = 0.28 },
			{ enemyId = "StormPelican", count = 1, atProgress = 0.45 },
			{ enemyId = "OilPuddleLayer", count = 1, atProgress = 0.6 },
			{ enemyId = "RigWelder", count = 2, atProgress = 0.75 },
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.88 },
		},
		miniboss = nil, boss = nil, unlockPersona = nil, rescueTurtles = 0,
		showMutantTagline = false, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "offshore", setPiece = "helipadWind", hazards = { "windPush", "oilSlick" },
		lighting = "industrialOrange", storyBeat = "One more headline between you and the Spillfather.",
		scalingTier = 4, goalLabel = "HELIPAD EDGE →", steveAct = 4, platformLedges = 1,
	},
	-- ACT 5
	{
		id = "GulfGulpRig", index = 20, name = "GulfGulp Rig",
		headline = "FINALE: The Spillfather makes an offer Florida Man can't refuse — he refuses, for the turtles",
		blurb = "Oil-exec sludge mech. Save remaining turtles. Sunrise credits.",
		length = 320, groundColor = Color3.fromRGB(35, 38, 45), accentColor = Color3.fromRGB(255, 150, 0),
		fogColor = Color3.fromRGB(30, 32, 40), clockTime = 22,
		waves = {
			{ enemyId = "GulfGulpGrunt", count = 2, atProgress = 0.08 },
			{ enemyId = "OilGator", count = 1, atProgress = 0.2 },
			{ enemyId = "MutantAdd", count = 2, atProgress = 0.32 },
			{ enemyId = "FireLizard", count = 1, atProgress = 0.42 },
			{ enemyId = "RigWelder", count = 1, atProgress = 0.5 },
		},
		miniboss = nil, boss = "Spillfather", unlockPersona = "FireworksEnthusiast", rescueTurtles = 3,
		showMutantTagline = true, isHub = false, coldOnePickup = false, hangover = false,
		propTheme = "rig", biome = "offshore", setPiece = "spillfatherArena", hazards = { "oilSlick", "fireCone" },
		lighting = "finaleRig", storyBeat = "Refuse the bargain. Save the nests. Earn the sunrise.",
		scalingTier = 5, goalLabel = "SUNRISE →", steveAct = 5, platformLedges = 1,
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

function Stages.CountPlayable(): number
	return #Stages.Order
end

return Stages
