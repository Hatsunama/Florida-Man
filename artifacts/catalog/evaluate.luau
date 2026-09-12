local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Constants=(function()
--!strict
local Constants = {
	GAME_NAME = "Florida Man",
	TAGLINE_MUTANTS = "It IS Florida… Anything is possible in the swamp I guess.",
	COMBO_WINDOW = 0.45,
	DODGE_IFRAME = 0.38,
	DODGE_COOLDOWN = 0.72,
	DODGE_DISTANCE = 18,
	DODGE_DURATION = 0.18, -- burst duration; the separate iframe window includes recovery
	SWAP_COOLDOWN = 1.15,
	SWAP_ATTACK_DAMAGE_MULT = 1.55, -- Phase 3: clearer swap-attack reward
	SWAP_IFRAME = 0.28, -- brief armor during swap-attack
	BASE_HP = 100,
	ATTACK_RANGE = 10,
	ATTACK_RECOVERY = 0.22, -- base swing lock before next connect
	HITSTOP = 0.045, -- 0.03–0.06s freeze on every connect
	HITSTOP_HEAVY = 0.06, -- combo finisher / skill connect
	FLINCH_TIME = 0.18, -- enemy stun on hit (readable)
	STARTING_PERSONA = "BeachBurnout",
	STARTING_WEAPON = "BareHands",
	STARTING_ITEM_SLOTS = 3,
	MAX_ITEM_SLOTS = 6,
	SESSION_PLAYER_LIMIT = 1,
	DRAFT_CHOICES = 3,
	INSCRIPTION_SET_SIZE = 3,
	LANE_Z = 0,
	SPAWN_X = 18, -- hub: within ProximityPrompt range of Flame at x=20
	REMOTE_FOLDER = "Remotes",
	COLD_ONE_HEAL = 35,
	HANGOVER_SLOW = 0.88,
	HANGOVER_DURATION = 999, -- cleared by Cold One pickup (stage 1 only)
	OIL_SLOW_MULT = 0.70, -- hazard OilSlow; distinct from Hangover (min-stack, never multiply both)
	RESCUE_DEBOUNCE = 1.5,
	SOFT_FALL_TOAST_MAX = 3,
	COMBAT_REMOTE_RATE = { attack = 8, skill = 4, dodge = 5 }, -- token bucket refill / sec
	COMBAT_REMOTE_BURST = { attack = 3, skill = 2, dodge = 2 },
	META_SCHEMA_VERSION = 3,
	KNOCKBACK_BASE = 7,
	CAMERA_DEPTH = 32, -- side-scroll depth ~30–34
	-- Phase 3 combat depth
	HYPER_ARMOR_DURATION = 0.6, -- boss phase-flip flinch skip
	SWAP_PUNISH_WINDOW = 2.0, -- swap within 2s of taking a hit
	SWAP_PUNISH_BONUS = 1.28, -- bonus damage mult on punish swap-attack
	SHIELD_ABSORB_AMOUNT = 48, -- Turtle Paladin damage counter
	SUMMON_LINGER = 2.0, -- Snake Charmer coil duration
	SUMMON_TICK = 0.35,
	PROJECTILE_SPEED_RANGED = 78,
	PROJECTILE_SPEED_THROWN = 44,
	RANGED_PIERCE_HITS = 2, -- ranged caps pierce; thrown stays single-hit
	EMBER_BUFF_DURATION = 2.5,
	EMBER_DAMAGE_MULT = 1.25,
	OIL_SLOW_MULT_RESIST = 0.88, -- GREASY set milder slick slow
	CART_DASH_IFRAME = 0.55, -- Golf Cart Bandit skill armor frames
	-- N5 level verbs
	WATER_TIMEOUT = 2.4, -- recover after continuous deep-water exposure
	CONVEYOR_FLIP_PERIOD = 3.8, -- Act4 conveyor push sign flip
	-- N6 combat depth
	FOAM_FIRE_MULT = 1.45, -- foam extinguisher vs firearc enemies
	NET_ROOT_DURATION = 1.15, -- net gun brief root
	THROW_ARC_HEIGHT = 7.5, -- Lawn Dart / thrown lob (Roman Candle stays flat)
}


return Constants

end)()
local Stages=(function()
--!strict
--[[ Stage progression — coherent campaign arc. 20 combat stages + hub.
	Extended fields: hazards, setPiece, lighting, storyBeat, scalingTier, goalLabel, steveAct.
	N5: LevelVerb(stage) is the mechanical identity (not décor).
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
		propTheme = "beach", biome = "beach", setPiece = "pierWalkway", hazards = { "sandSlow" },
		lighting = "dawnGold", storyBeat = "The crabs stole your Florida Dew. Reclaim the glowing can, then follow the beach.",
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
		lighting = "midBeach", storyBeat = "Steve spots GulfGulp's logo on the cooler shipment. Why is a soda company shipping wildlife equipment?",
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
		lighting = "neonGas", storyBeat = "GulfGulp deliveries pass through this gas station. The slushie line is guarded far better than it should be.",
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
		lighting = "stripMall", storyBeat = "The delivery route leads to the drive-thru. Its newest employee has scales and a suspicious uniform.",
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
		lighting = "lateAfternoon", storyBeat = "A collared gator guards the drive-thru. Get past it so Steve can trace who supplied that hardware.",
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
		lighting = "swampGreen", storyBeat = "The collar shipment came through this canal. Follow it into the swamp, using the pads to escape deep water.",
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
		lighting = "greenBlack", storyBeat = "The oil gators and fire lizards wear matching collars. GulfGulp turned wildlife into security guards.",
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
		lighting = "greenBlack", storyBeat = "The conspiracy leaves a paper trail.",
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
		lighting = "clinicalLab", storyBeat = "The logo on the gate matches the collars. Follow the pipes to the lab and find the records.",
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
		lighting = "finaleRig", storyBeat = "The Spillfather and the last captive turtles are here. Defeat the mech and free every turtle before sunrise.",
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

-- N5: per-act gameplay verb (mechanical, not palette)
Stages.ACT_VERB = {
	[1] = "timedRhythm",
	[2] = "padWater",
	[3] = "turtleRescue",
	[4] = "conveyorFlip",
	[5] = "windGaps",
}

Stages.VERB_LABEL = {
	hangoverColdOne = "Hangover + Cold One walkover",
	timedRhythm = "Timed hazard rhythm — jump when HOT",
	padWater = "Pad-only traversal — leave deep water or soft-fall",
	oilSlick = "Oil slicks — skim or slip",
	turtleRescue = "Turtle rescue — use Interact beside each turtle",
	midGate = "MidGate room lock — clear the wave",
	conveyorFlip = "Conveyors flip direction on a timer",
	windGaps = "Barge gaps + wind opposing jumps",
	bossArena = "Boss arena telegraphs — no empty-wave softlock",
}

function Stages.LevelVerb(stage: StageDef): string
	if stage.isHub then
		return "hub"
	end
	if stage.hangover or stage.coldOnePickup then
		return "hangoverColdOne"
	end
	if stage.boss then
		return "bossArena"
	end
	if stage.rescueTurtles > 0 then
		return "turtleRescue"
	end
	local sp = stage.setPiece or ""
	if sp == "canalPads" then
		return "padWater"
	end
	if sp == "labConveyor" or sp == "pipeMaze" then
		return "conveyorFlip"
	end
	if sp == "bargeGaps" or sp == "helipadWind" then
		return "windGaps"
	end
	local act = stage.steveAct or 1
	-- Act2 swamp stages without canalPads still share pad/oil identity
	if act == 2 then
		for _, hk in stage.hazards do
			if hk == "oilSlick" then
				return "oilSlick"
			end
		end
		return "padWater"
	end
	if act == 4 then
		return "conveyorFlip"
	end
	if act == 5 then
		return "windGaps"
	end
	if act == 1 and (stage.index or 0) >= 3 then
		return "midGate"
	end
	return Stages.ACT_VERB[act] or "timedRhythm"
end

function Stages.VerbLabel(verb: string): string
	return Stages.VERB_LABEL[verb] or verb
end


return Stages

end)()
local Personas=(function()
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

end)()
local Enemies=(function()
--!strict
--[[ Enemy catalog — Florida Man folklore headlines. Cartoon violence. Turtles always allies.
	Roles kept: charger, spitter, burrower, hopper, summoner, puddle, firearc, tank, boss, scuttle, chase.
]]

local Enemies = {}

export type EnemyDef = {
	id: string,
	name: string,
	hp: number,
	damage: number,
	speed: number,
	color: Color3,
	accent: Color3,
	size: Vector3,
	telegraph: number,
	attackCooldown: number,
	isBoss: boolean,
	isMiniboss: boolean,
	isAlly: boolean,
	dropsPersona: string?,
	dropsItem: string?,
	flavor: string,
	shape: string,
	behavior: string,
	telegraphColor: Color3?,
}

local list: { EnemyDef } = {
	-- Crabs / beach
	{ id = "BeachCrab", name = "Hangover Pincher", hp = 24, damage = 5, speed = 10,
		color = Color3.fromRGB(220, 70, 50), accent = Color3.fromRGB(255, 180, 100),
		size = Vector3.new(3.2, 1.6, 3.2), telegraph = 0.72, attackCooldown = 1.65,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Stole your Cold One. Sideways and proud.", shape = "crab", behavior = "scuttle",
		telegraphColor = Color3.fromRGB(255, 120, 80) },
	{ id = "HermitCrab", name = "Stolen-Sunglasses Crab", hp = 34, damage = 7, speed = 7,
		color = Color3.fromRGB(180, 90, 60), accent = Color3.fromRGB(40, 40, 50),
		size = Vector3.new(2.8, 2.2, 2.8), telegraph = 0.55, attackCooldown = 1.7,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "SeashellShield",
		flavor = "Wears your shades. Shell tank. Slow pinch.", shape = "crab", behavior = "tank",
		telegraphColor = Color3.fromRGB(255, 200, 80) },
	{ id = "SandFlea", name = "Sand Flea", hp = 16, damage = 4, speed = 16,
		color = Color3.fromRGB(200, 180, 120), accent = Color3.fromRGB(255, 220, 160),
		size = Vector3.new(1.6, 1.2, 1.6), telegraph = 0.48, attackCooldown = 1.25,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Annoying hoppers. Tutorial pests.", shape = "hopper", behavior = "hopper",
		telegraphColor = Color3.fromRGB(255, 240, 180) },
	{ id = "CrabKingBoss", name = "King of the Tide Pool", hp = 85, damage = 10, speed = 9,
		color = Color3.fromRGB(180, 30, 40), accent = Color3.fromRGB(255, 220, 100),
		size = Vector3.new(5.5, 3, 5.5), telegraph = 0.85, attackCooldown = 1.75,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = "CrabKing", dropsItem = "LiveBait",
		flavor = "Sideways royalty. Holds court over your Florida Dew.", shape = "crab", behavior = "scuttle",
		telegraphColor = Color3.fromRGB(255, 80, 60) },
	-- Tourists
	{ id = "AngryTourist", name = "Lost Tourist", hp = 36, damage = 7, speed = 9,
		color = Color3.fromRGB(255, 210, 160), accent = Color3.fromRGB(80, 140, 200),
		size = Vector3.new(2.4, 5, 2), telegraph = 0.68, attackCooldown = 1.8,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "IHeartFLShirt",
		flavor = "Lost. Taking it personally.", shape = "humanoid", behavior = "chase",
		telegraphColor = Color3.fromRGB(255, 160, 100) },
	{ id = "SelfieZombie", name = "Influencer Stick", hp = 32, damage = 6, speed = 8,
		color = Color3.fromRGB(255, 200, 180), accent = Color3.fromRGB(100, 200, 255),
		size = Vector3.new(2.2, 4.8, 2), telegraph = 0.75, attackCooldown = 2.1,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "CrackedVisor",
		flavor = "Selfie-stick flash marks the danger strip. Step aside.", shape = "humanoid", behavior = "spitter",
		telegraphColor = Color3.fromRGB(180, 240, 255) },
	{ id = "CondoKaren", name = "HOA Binder Karen", hp = 48, damage = 9, speed = 8,
		color = Color3.fromRGB(255, 180, 160), accent = Color3.fromRGB(200, 40, 80),
		size = Vector3.new(2.5, 5.1, 2.1), telegraph = 0.7, attackCooldown = 1.9,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "HOACitation",
		flavor = "Paperwork strike slows you. Wants the manager of the swamp.", shape = "humanoid", behavior = "spitter",
		telegraphColor = Color3.fromRGB(255, 80, 120) },
	{ id = "SlushieSlime", name = "Slushie Spill", hp = 32, damage = 6, speed = 7,
		color = Color3.fromRGB(255, 60, 160), accent = Color3.fromRGB(120, 255, 255),
		size = Vector3.new(3.5, 2.5, 3.5), telegraph = 0.72, attackCooldown = 2.0,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "GasStationTaquito",
		flavor = "Floor is sticky. Neon pink.", shape = "slime", behavior = "puddle",
		telegraphColor = Color3.fromRGB(255, 100, 200) },
	{ id = "HotDogCart", name = "Runaway Hotdog Cart", hp = 48, damage = 9, speed = 14,
		color = Color3.fromRGB(220, 40, 40), accent = Color3.fromRGB(255, 220, 80),
		size = Vector3.new(4, 3, 2.5), telegraph = 0.58, attackCooldown = 2.4,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "NoveltyMug",
		flavor = "Mustard-yellow charger. Sidestep its marked strike.", shape = "cart", behavior = "charger",
		telegraphColor = Color3.fromRGB(255, 200, 40) },
	{ id = "SlushieKing", name = "Slushie King", hp = 100, damage = 11, speed = 6,
		color = Color3.fromRGB(255, 40, 140), accent = Color3.fromRGB(80, 255, 255),
		size = Vector3.new(5, 5, 5), telegraph = 0.8, attackCooldown = 2.1,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = nil, dropsItem = "GasStationTaquito",
		flavor = "Sticky crown. Wide strikes leave slowing slicks.", shape = "slime", behavior = "puddle",
		telegraphColor = Color3.fromRGB(255, 60, 180) },
	{ id = "HOAHydra", name = "HOA Hydra", hp = 125, damage = 12, speed = 7,
		color = Color3.fromRGB(100, 60, 120), accent = Color3.fromRGB(255, 200, 80),
		size = Vector3.new(6, 5, 4), telegraph = 0.75, attackCooldown = 1.9,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = nil, dropsItem = "HOACitation",
		flavor = "Three clipboards. Zero chill. Calls snake backup.", shape = "boss", behavior = "summoner",
		telegraphColor = Color3.fromRGB(200, 100, 255) },
	-- Gators / swamp
	{ id = "DriveThruGator", name = "Drive-Thru Gator", hp = 115, damage = 13, speed = 8,
		color = Color3.fromRGB(45, 110, 55), accent = Color3.fromRGB(255, 200, 40),
		size = Vector3.new(7, 3.2, 3.5), telegraph = 0.75, attackCooldown = 2.1,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = "GatorHauler", dropsItem = "RadioCollar",
		flavor = "Radio collar blinking. First real story beat.", shape = "gator", behavior = "tank",
		telegraphColor = Color3.fromRGB(255, 220, 60) },
	{ id = "Cottonmouth", name = "Rattle Cottonmouth", hp = 34, damage = 9, speed = 14,
		color = Color3.fromRGB(60, 80, 50), accent = Color3.fromRGB(240, 240, 220),
		size = Vector3.new(4, 1.2, 1.2), telegraph = 0.45, attackCooldown = 1.3,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = "SnakeCharmer", dropsItem = nil,
		flavor = "Raised-tail warning before the strike.", shape = "snake", behavior = "chase",
		telegraphColor = Color3.fromRGB(255, 255, 180) },
	{ id = "BurrowSnake", name = "Burrow Snake", hp = 36, damage = 9, speed = 11,
		color = Color3.fromRGB(80, 60, 40), accent = Color3.fromRGB(200, 180, 120),
		size = Vector3.new(3.5, 1.0, 1.0), telegraph = 0.6, attackCooldown = 1.9,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LiveBait",
		flavor = "Pops from sand with a dirt ring telegraph.", shape = "snake", behavior = "burrower",
		telegraphColor = Color3.fromRGB(180, 140, 80) },
	{ id = "OilGator", name = "Collared Oil Gator", hp = 58, damage = 11, speed = 8,
		color = Color3.fromRGB(25, 35, 30), accent = Color3.fromRGB(255, 200, 40),
		size = Vector3.new(6, 2.8, 3), telegraph = 0.7, attackCooldown = 1.8,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "SpillAbsorbent",
		flavor = "Neon collar + sludge trail. GulfGulp property.", shape = "gator", behavior = "puddle",
		telegraphColor = Color3.fromRGB(255, 180, 40) },
	{ id = "FireLizard", name = "Fire-Breathing Lizard", hp = 46, damage = 11, speed = 12,
		color = Color3.fromRGB(255, 90, 20), accent = Color3.fromRGB(255, 220, 60),
		size = Vector3.new(3.5, 2.2, 4), telegraph = 0.55, attackCooldown = 1.6,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = "LizardBreath", dropsItem = nil,
		flavor = "Ground fire-cone telegraph. Cartoon burn.", shape = "lizard", behavior = "firearc",
		telegraphColor = Color3.fromRGB(255, 100, 20) },
	{ id = "EmberSkink", name = "Ember Skink", hp = 26, damage = 7, speed = 15,
		color = Color3.fromRGB(255, 140, 40), accent = Color3.fromRGB(255, 80, 20),
		size = Vector3.new(2.2, 1.4, 3), telegraph = 0.4, attackCooldown = 1.3,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "ExpiredSunscreen",
		flavor = "Tiny flame arcs on the ground.", shape = "lizard", behavior = "firearc",
		telegraphColor = Color3.fromRGB(255, 160, 40) },
	{ id = "MutantAdd", name = "Enhanced Specimen", hp = 44, damage = 9, speed = 11,
		color = Color3.fromRGB(80, 200, 60), accent = Color3.fromRGB(255, 100, 0),
		size = Vector3.new(3, 3, 3), telegraph = 0.45, attackCooldown = 1.4,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Anything is possible in the swamp.", shape = "lizard", behavior = "chase",
		telegraphColor = Color3.fromRGB(120, 255, 80) },
	{ id = "SwampSummoner", name = "Swamp Open-Mic Host", hp = 58, damage = 8, speed = 5,
		color = Color3.fromRGB(70, 50, 90), accent = Color3.fromRGB(180, 100, 255),
		size = Vector3.new(3, 4.5, 3), telegraph = 1.05, attackCooldown = 3.1,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "HOACitation",
		flavor = "Calls cottonmouths. Purple circle telegraph.", shape = "humanoid", behavior = "summoner",
		telegraphColor = Color3.fromRGB(180, 80, 255) },
	{ id = "PelicanBully", name = "Bully Pelican", hp = 42, damage = 9, speed = 10,
		color = Color3.fromRGB(240, 240, 230), accent = Color3.fromRGB(255, 160, 40),
		size = Vector3.new(3.5, 3.5, 3), telegraph = 0.5, attackCooldown = 1.6,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "FlipFlops",
		flavor = "Not Captain Steve. Rude.", shape = "pelican", behavior = "charger",
		telegraphColor = Color3.fromRGB(255, 200, 120) },
	{ id = "MosquitoCloud", name = "Mosquito Cloud", hp = 20, damage = 4, speed = 14,
		color = Color3.fromRGB(40, 50, 40), accent = Color3.fromRGB(100, 120, 80),
		size = Vector3.new(4, 3, 4), telegraph = 0.35, attackCooldown = 1.0,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "ExpiredSunscreen",
		flavor = "Buzz. Bite. Repeat.", shape = "cloud", behavior = "hopper",
		telegraphColor = Color3.fromRGB(140, 160, 100) },
	{ id = "JetSkiBandit", name = "Jet Ski Bandit", hp = 44, damage = 10, speed = 17,
		color = Color3.fromRGB(40, 120, 200), accent = Color3.fromRGB(255, 80, 80),
		size = Vector3.new(4, 2.5, 2), telegraph = 0.45, attackCooldown = 1.6,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "FlipFlops",
		flavor = "Wake-jump charger.", shape = "cart", behavior = "charger",
		telegraphColor = Color3.fromRGB(80, 180, 255) },
	{ id = "OilPuddleLayer", name = "Oil Puddle Layer", hp = 40, damage = 7, speed = 6,
		color = Color3.fromRGB(20, 25, 30), accent = Color3.fromRGB(80, 60, 20),
		size = Vector3.new(3, 2.5, 3), telegraph = 0.85, attackCooldown = 2.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "SpillAbsorbent",
		flavor = "Leaves slicks that slow you.", shape = "slime", behavior = "puddle",
		telegraphColor = Color3.fromRGB(60, 50, 30) },
	-- Corp
	{ id = "GulfGulpGrunt", name = "Cheap Hazmat Grunt", hp = 46, damage = 10, speed = 10,
		color = Color3.fromRGB(50, 50, 60), accent = Color3.fromRGB(255, 180, 0),
		size = Vector3.new(2.6, 5.2, 2.2), telegraph = 0.55, attackCooldown = 1.6,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "Corporate mascot energy. Yellow tape.", shape = "humanoid", behavior = "chase",
		telegraphColor = Color3.fromRGB(255, 200, 40) },
	{ id = "DroneSpotter", name = "Mark Drone", hp = 28, damage = 6, speed = 12,
		color = Color3.fromRGB(60, 70, 90), accent = Color3.fromRGB(100, 255, 180),
		size = Vector3.new(2.5, 1.2, 2.5), telegraph = 0.5, attackCooldown = 1.7,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LuckyPenny",
		flavor = "Hover-hop. Marks you with a telegraph circle.", shape = "drone", behavior = "hopper",
		telegraphColor = Color3.fromRGB(100, 255, 180) },
	{ id = "LabCoat", name = "Sample Tosser", hp = 46, damage = 9, speed = 11,
		color = Color3.fromRGB(230, 230, 240), accent = Color3.fromRGB(40, 180, 220),
		size = Vector3.new(2.4, 5, 2), telegraph = 0.55, attackCooldown = 1.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "Marks a hazardous sample strip. Science without ethics.", shape = "humanoid", behavior = "spitter",
		telegraphColor = Color3.fromRGB(80, 220, 255) },
	{ id = "RigWelder", name = "Rig Welder", hp = 56, damage = 12, speed = 8,
		color = Color3.fromRGB(80, 80, 90), accent = Color3.fromRGB(255, 140, 40),
		size = Vector3.new(2.8, 5.2, 2.4), telegraph = 0.6, attackCooldown = 1.8,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "GatorSkinWallet",
		flavor = "Torch arcs on the ground.", shape = "humanoid", behavior = "firearc",
		telegraphColor = Color3.fromRGB(255, 140, 40) },
	{ id = "BarrelRoller", name = "Barrel Roller", hp = 38, damage = 11, speed = 13,
		color = Color3.fromRGB(40, 50, 40), accent = Color3.fromRGB(255, 180, 0),
		size = Vector3.new(3, 3, 3), telegraph = 0.4, attackCooldown = 2.1,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = nil,
		flavor = "Hazardous freestyle charger.", shape = "barrel", behavior = "charger",
		telegraphColor = Color3.fromRGB(255, 180, 0) },
	{ id = "RedTideBlob", name = "Red Tide Blob", hp = 52, damage = 10, speed = 5,
		color = Color3.fromRGB(180, 40, 60), accent = Color3.fromRGB(255, 80, 100),
		size = Vector3.new(4.5, 3, 4.5), telegraph = 0.75, attackCooldown = 2.1,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "TurtleSticker",
		flavor = "Bad for turtles. Cover for 'cleanup.'", shape = "slime", behavior = "puddle",
		telegraphColor = Color3.fromRGB(220, 40, 60) },
	{ id = "OffshoreCrab", name = "Offshore Pinch Crew", hp = 48, damage = 11, speed = 9,
		color = Color3.fromRGB(160, 40, 50), accent = Color3.fromRGB(255, 120, 60),
		size = Vector3.new(4, 2, 4), telegraph = 0.55, attackCooldown = 1.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LiveBait",
		flavor = "Oil-stained claws. Clocked in late.", shape = "crab", behavior = "scuttle",
		telegraphColor = Color3.fromRGB(255, 100, 50) },
	{ id = "StormPelican", name = "Storm Pelican", hp = 85, damage = 10, speed = 12,
		color = Color3.fromRGB(200, 210, 220), accent = Color3.fromRGB(80, 120, 180),
		size = Vector3.new(4, 3.5, 3.5), telegraph = 0.55, attackCooldown = 1.5,
		isBoss = false, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LuckyPenny",
		flavor = "Wind hoppers over the barge.", shape = "pelican", behavior = "hopper",
		telegraphColor = Color3.fromRGB(140, 180, 255) },
	{ id = "RigOverlord", name = "Rig Overlord", hp = 175, damage = 14, speed = 6,
		color = Color3.fromRGB(30, 35, 45), accent = Color3.fromRGB(255, 160, 0),
		size = Vector3.new(8, 7, 5), telegraph = 0.85, attackCooldown = 2.1,
		isBoss = false, isMiniboss = true, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "Middle management of doom. Wide warning arcs, then fire.", shape = "boss", behavior = "firearc",
		telegraphColor = Color3.fromRGB(255, 140, 0) },
	{ id = "Spillfather", name = "The Spillfather", hp = 340, damage = 16, speed = 7,
		color = Color3.fromRGB(20, 25, 30), accent = Color3.fromRGB(255, 140, 0),
		size = Vector3.new(12, 8, 6), telegraph = 0.9, attackCooldown = 2.3,
		isBoss = true, isMiniboss = false, isAlly = false, dropsPersona = nil, dropsItem = "LabBadge",
		flavor = "Oil-exec sludge mech. Phases: slam, summon, arena slick.", shape = "boss", behavior = "tank",
		telegraphColor = Color3.fromRGB(255, 120, 0) },
	{ id = "RescueTurtle", name = "Baby Turtle", hp = 9999, damage = 0, speed = 4,
		color = Color3.fromRGB(80, 160, 100), accent = Color3.fromRGB(200, 255, 180),
		size = Vector3.new(2, 1.2, 2.4), telegraph = 0, attackCooldown = 99,
		isBoss = false, isMiniboss = false, isAlly = true, dropsPersona = "TurtlePaladin", dropsItem = "TurtleSticker",
		flavor = "Always an ally. Always.", shape = "turtle", behavior = "chase",
		telegraphColor = Color3.fromRGB(120, 255, 180) },
}

Enemies.List = list
Enemies.ById = {} :: { [string]: EnemyDef }
for _, e in list do
	Enemies.ById[e.id] = e
end

function Enemies.Get(id: string): EnemyDef?
	return Enemies.ById[id]
end

function Enemies.Count(): number
	return #list
end

return Enemies

end)()
local Items=(function()
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

end)()
local Weapons=(function()
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

end)()
local Balance=(function()
--!strict
--[[ Difficulty + power curve (documented).
	See also docs/BALANCE_SHEET.md for DPS vs stage HP tables.

	Design intent — Skul readability, not HP sponges:

	STAGE BANDS
	  1–2  Tutorial: teach dodge then attack. Max 2 hostiles. Slow telegraphs.
	       Enemy HP ~25–40. Player wins by connecting, not farming.
	  3–5  Comedy coast: introduce roles (charger / flash / aura). Max 3.
	       Drive-Thru Gator collar beat teaches "unease" without sponge HP.
	  6–10 Swamp: tank+spitter mixes, oil/fire hazards. Density up, HP scale mild.
	 11–12 Turtle pressure: rescue gate, red tide. Skill check = positioning.
	 13–19 Facility: elites + hazards, not ballooned HP. Max 4 readable.
	 20    Spillfather: 3 phases (slam → summon → arena slick). Phase HP chunks.

	ENEMY SCALING (stageIndex = 1..20)
	  HP  *= 1 + 0.09 * idx
	  DMG *= 1 + 0.075 * idx
	  Elites (miniboss/boss) get +phase tools, not +200% HP.

	PLAYER POWER
	  Weapons + items + persona rarity must match if they draft well.
	  Rarity → attack & skill DAMAGE: Common +0 / Rare +15% / Unique +30% / Legendary +50%
	  Rarity → skill COOLDOWN: Rare −8% / Unique −14% / Legendary −20%
	  Lucky draft melts late; unlucky run stays completable with dodge skill.

	MAX HOSTILES: never smear — 2 → 3 → 4 by band.
]]

local Balance = {}

Balance.ENEMY_HP_PER_STAGE = 0.09 -- Phase 6: was 0.10; Act1 trash less sponge
Balance.ENEMY_DMG_PER_STAGE = 0.075

-- Persona rarity → attack & skill power
Balance.RARITY_POWER = {
	Common = 0,
	Rare = 0.15,
	Unique = 0.30,
	Legendary = 0.50,
}

-- Persona rarity → skill cooldown reduction (faster skills feel rarer)
Balance.RARITY_SKILL_CDR = {
	Common = 0,
	Rare = 0.08,
	Unique = 0.14,
	Legendary = 0.20,
}

-- Max simultaneous hostiles on screen (readable, not cube soup)
function Balance.MaxHostiles(stageIndex: number): number
	if stageIndex <= 2 then
		return 2
	elseif stageIndex <= 5 then
		return 3
	elseif stageIndex <= 12 then
		return 3
	else
		return 4
	end
end

function Balance.EnemyHpMult(stageIndex: number): number
	return 1 + Balance.ENEMY_HP_PER_STAGE * math.max(0, stageIndex)
end

function Balance.EnemyDmgMult(stageIndex: number): number
	return 1 + Balance.ENEMY_DMG_PER_STAGE * math.max(0, stageIndex)
end

function Balance.RarityMult(rarity: string?): number
	local r = rarity or "Common"
	return 1 + (Balance.RARITY_POWER[r] or 0)
end

function Balance.SkillCooldownMult(rarity: string?): number
	local r = rarity or "Common"
	return 1 - (Balance.RARITY_SKILL_CDR[r] or 0)
end

-- Soft tier labels for HUD / design notes
function Balance.TierName(stageIndex: number): string
	if stageIndex <= 5 then
		return "Hangover Coast"
	elseif stageIndex <= 10 then
		return "The Swamp That Isn't Wild"
	elseif stageIndex <= 12 then
		return "Red Tide Bargain"
	elseif stageIndex <= 19 then
		return "Inside GulfGulp"
	else
		return "The Spillfather"
	end
end

function Balance.ActNumber(stageIndex: number): number
	if stageIndex <= 5 then
		return 1
	elseif stageIndex <= 10 then
		return 2
	elseif stageIndex <= 12 then
		return 3
	elseif stageIndex <= 19 then
		return 4
	else
		return 5
	end
end

-- Phase 5: Act1–2 minibosses slightly softer so pacing teaches, not sponges
Balance.MINIBOSS_HP_ACT = {
	[1] = 0.88, -- Hangover Coast
	[2] = 0.92, -- Swamp
	[3] = 1.0,
	[4] = 1.0,
	[5] = 1.0,
}

function Balance.MinibossHpMult(stageIndex: number): number
	local act = Balance.ActNumber(stageIndex)
	return Balance.MINIBOSS_HP_ACT[act] or 1
end

function Balance.RestToast(actNumber: number): string
	local lines = {
		[1] = "REST — Dawn Bonfire. Captain Steve stocks upgrades at the hub only.",
		[2] = "REST — Swamp edge. Catch your breath; Steve's shop is back at hub.",
		[3] = "REST — Turtle beach calm. Shop = hub Steve only (by design).",
		[4] = "REST — Facility airlock. No mid-act shops — Steve waits at hub.",
		[5] = "REST — Rig approach. Last stretch. Steve stays at hub.",
	}
	return lines[actNumber] or "REST — Return to hub for Captain Steve upgrades."
end

-- Phase 6: seed-of-day luck bonus for drafts (±5% luck additive).
-- os.date UTC day → deterministic Random; documented in PUBLISH_CHECKLIST / BALANCE_SHEET.
function Balance.DailyLuckBonus(): number
	local d = os.date("!*t")
	local seed = d.year * 10000 + d.month * 100 + d.day
	local r = Random.new(seed)
	-- map [0,1) → [-0.05, +0.05]
	return (r:NextNumber() * 0.10) - 0.05
end

-- Rough starter DPS (BeachBurnout BareHands, Common, no items) for sheet notes
function Balance.EstimateStarterHitDamage(): number
	-- persona.attackDamage 12 + (weapon.damage 10 - 10)*0.65 = 12
	return 12
end

function Balance.EstimateScaledEnemyHp(baseHp: number, stageIndex: number, isMiniboss: boolean?): number
	local m = Balance.EnemyHpMult(stageIndex)
	if isMiniboss then
		m *= Balance.MinibossHpMult(stageIndex)
	end
	return math.floor(baseHp * m)
end


return Balance

end)()
local ProgressionRules=(function()
--!strict
-- Pure campaign rules. Presentation and transport cannot grant completion.
local Rules = {}

function Rules.ItemCapacity(stageIndex: number): number
	return math.clamp(3 + math.floor(math.max(0, stageIndex - 1) / 5), 3, 6)
end

function Rules.CanUnlockPersona(personaId: string, finaleCommitted: boolean): boolean
	return personaId ~= 'FireworksEnthusiast' or finaleCommitted
end

function Rules.RequiresMidRoom(stage: {index: number,isHub: boolean,waves: {any}}): boolean
	return not stage.isHub and stage.index>=3 and #stage.waves>0
end

function Rules.CanComplete(stage: {index: number,isHub: boolean, boss: string?, rescueTurtles: number, miniboss: string?, waves: {any},coldOnePickup: boolean?}, state: {bossDefeated: boolean, turtlesRescued: number, minibossSpawned: boolean, waveFlags: {[number]: boolean},midRoomState: string,coldOneTaken: boolean?}, outstanding: number): boolean
	if stage.isHub or outstanding > 0 then return false end
	if stage.coldOnePickup and not state.coldOneTaken then return false end
	if Rules.RequiresMidRoom(stage) and state.midRoomState~='cleared' then return false end
	if stage.boss and not state.bossDefeated then return false end
	if state.turtlesRescued < stage.rescueTurtles then return false end
	if stage.miniboss and not state.minibossSpawned then return false end
	for i in stage.waves do
		if not state.waveFlags[i] then return false end
	end
	return true
end

function Rules.Claim(ledger: {[string]: boolean}, key: string): boolean
	if ledger[key] then return false end
	ledger[key] = true
	return true
end

return table.freeze(Rules)

end)()
local ProgressionCatalog=(function()
--!strict
-- Permanent weapon unlocks awarded once per completed stage.
local weaponDrops: { [string]: { string } } = {
		DaytonaHangover = { "FlipFlopSlap", "CoolerLid" },
		BoardwalkChaos = { "PoolNoodle", "NewspaperRoll" },
		GasStationLegends = { "GolfClub", "TrafficCone" },
		StripMallShowdown = { "HOAClipboard", "BeachUmbrella" },
		DriveThruDisaster = { "GatorWrestleGloves", "ShoppingCart" },
		CanalRun = { "KayakPaddle", "WaterBalloonSling" },
		SwampShift = { "SnakeLasso", "FishSmack" },
		CypressCathedral = { "TikiTorch", "LawnDart" },
		SludgeBayou = { "SpillSkimmer" },
		ConspiracyShack = { "Skateboard", "PelicanBeakReplica" },
		TurtleBeach = { "NetGun" },
		GulfGulpGate = { "FireExtinguisher" },
		LabWing = { "BugZapper" },
		PipeGauntlet = { "OilBarrelLid" },
		BargeCrossing = { "BoogieBoard" },
		OilPlatformApproach = { "SludgeHose" },
		HelipadHysteria = { "RomanCandle" },
		GulfGulpRig = { "FinaleRocket" },
	}
return table.freeze(weaponDrops)

end)()
local Movesets=(function()
--!strict
-- Declarative action definitions shared by simulation and balance tooling.
local Movesets = {}

export type MovesetHit = {
	recovery: number,
	rangeMul: number,
	knockMul: number,
	dmgMul: number,
	cancelAfter: number,
	label: string,
}

local MOVESETS: { [string]: { MovesetHit } } = {
	BeachBurnout = {
		{ recovery = 0.16, rangeMul = 1.00, knockMul = 0.95, dmgMul = 0.95, cancelAfter = 0.08, label = "jab" },
		{ recovery = 0.18, rangeMul = 1.08, knockMul = 1.05, dmgMul = 1.05, cancelAfter = 0.09, label = "cross" },
		{ recovery = 0.26, rangeMul = 1.22, knockMul = 1.35, dmgMul = 1.38, cancelAfter = 0.13, label = "shuffle" },
	},
	CrabKing = {
		{ recovery = 0.22, rangeMul = 0.92, knockMul = 1.25, dmgMul = 1.12, cancelAfter = 0.11, label = "pinch" },
		{ recovery = 0.24, rangeMul = 1.00, knockMul = 1.40, dmgMul = 1.18, cancelAfter = 0.12, label = "sideways" },
		{ recovery = 0.34, rangeMul = 1.18, knockMul = 1.85, dmgMul = 1.55, cancelAfter = 0.17, label = "royal" },
	},
	GatorHauler = {
		{ recovery = 0.24, rangeMul = 0.95, knockMul = 1.30, dmgMul = 1.15, cancelAfter = 0.12, label = "clamp" },
		{ recovery = 0.26, rangeMul = 1.05, knockMul = 1.45, dmgMul = 1.22, cancelAfter = 0.13, label = "drag" },
		{ recovery = 0.36, rangeMul = 1.20, knockMul = 1.90, dmgMul = 1.50, cancelAfter = 0.18, label = "slam" },
	},
	SnakeCharmer = {
		{ recovery = 0.14, rangeMul = 1.05, knockMul = 0.85, dmgMul = 0.90, cancelAfter = 0.07, label = "flick" },
		{ recovery = 0.16, rangeMul = 1.12, knockMul = 0.95, dmgMul = 1.00, cancelAfter = 0.08, label = "coil" },
		{ recovery = 0.22, rangeMul = 1.28, knockMul = 1.15, dmgMul = 1.28, cancelAfter = 0.11, label = "strike" },
	},
	GolfCartBandit = {
		{ recovery = 0.12, rangeMul = 0.95, knockMul = 1.10, dmgMul = 0.88, cancelAfter = 0.06, label = "tap" },
		{ recovery = 0.14, rangeMul = 1.00, knockMul = 1.20, dmgMul = 0.95, cancelAfter = 0.07, label = "scrape" },
		{ recovery = 0.20, rangeMul = 1.15, knockMul = 1.55, dmgMul = 1.25, cancelAfter = 0.1, label = "bumper" },
	},
	FireworksEnthusiast = {
		{ recovery = 0.18, rangeMul = 1.00, knockMul = 0.90, dmgMul = 1.00, cancelAfter = 0.09, label = "spark" },
		{ recovery = 0.20, rangeMul = 1.10, knockMul = 1.00, dmgMul = 1.10, cancelAfter = 0.1, label = "roman" },
		{ recovery = 0.30, rangeMul = 1.25, knockMul = 1.40, dmgMul = 1.42, cancelAfter = 0.15, label = "finale" },
	},
	LizardBreath = {
		{ recovery = 0.20, rangeMul = 1.05, knockMul = 1.00, dmgMul = 1.08, cancelAfter = 0.1, label = "hiss" },
		{ recovery = 0.22, rangeMul = 1.12, knockMul = 1.10, dmgMul = 1.15, cancelAfter = 0.11, label = "exhale" },
		{ recovery = 0.32, rangeMul = 1.30, knockMul = 1.35, dmgMul = 1.45, cancelAfter = 0.16, label = "burn" },
	},
	TurtlePaladin = {
		{ recovery = 0.20, rangeMul = 0.95, knockMul = 1.15, dmgMul = 1.05, cancelAfter = 0.1, label = "shell" },
		{ recovery = 0.22, rangeMul = 1.00, knockMul = 1.25, dmgMul = 1.12, cancelAfter = 0.11, label = "smite" },
		{ recovery = 0.30, rangeMul = 1.15, knockMul = 1.50, dmgMul = 1.40, cancelAfter = 0.15, label = "sanctuary" },
	},
}

local DEFAULT_MOVESET: { MovesetHit } = {
	{ recovery = 0.20, rangeMul = 1.0, knockMul = 1.0, dmgMul = 1.0, cancelAfter = 0.1, label = "hit1" },
	{ recovery = 0.22, rangeMul = 1.05, knockMul = 1.1, dmgMul = 1.1, cancelAfter = 0.11, label = "hit2" },
	{ recovery = 0.28, rangeMul = 1.2, knockMul = 1.35, dmgMul = 1.35, cancelAfter = 0.14, label = "hit3" },
}

Movesets.List = MOVESETS
Movesets.Default = DEFAULT_MOVESET
function Movesets.Get(personaId: string, comboIndex: number): MovesetHit
	local moves = MOVESETS[personaId] or DEFAULT_MOVESET
	local index = math.clamp(math.floor(comboIndex), 1, 3)
	return moves[index] or DEFAULT_MOVESET[index]
end
return Movesets

end)()
local BuildRules=(function()
--!strict
-- Pure derivation from catalog definitions, shared by runtime and balance analysis.
local BuildRules={}
export type Stats={maxHp:number,damageMult:number,speedBonus:number,luck:number,dodgeBonus:number}
function BuildRules.Compute(ids: {string}, Items: any, Constants: any): Stats
	local maxHp = Constants.BASE_HP
	local dmg = 1
	local speed = 0
	local luck = 0
	local dodge = 0
	for _, id in ids do
		local it = Items.Get(id)
		if it then
			maxHp += it.hpBonus
			dmg += it.damageBonus / 20
			speed += it.speedBonus
			luck += it.luckBonus
			dodge += it.dodgeBonus
			if it.special == "antiCorp" then
				dmg += 0.08
			end
			if it.special == "badge" then
				maxHp += 5
				dmg += 0.1
			end
		end
	end
	local counts = Items.CountInscriptions(ids)
	for tag, n in counts do
		if n >= Constants.INSCRIPTION_SET_SIZE then
			local bonus = Items.SetBonuses[tag]
			if bonus then
				maxHp += bonus.hpBonus or 0
				if bonus.damageBonus then
					dmg += bonus.damageBonus
				end
				luck += bonus.luckBonus or 0
				dodge += bonus.dodgeBonus or 0
			end
		end
	end
    return {maxHp=maxHp,damageMult=dmg,speedBonus=speed,luck=luck,dodgeBonus=dodge}
end

return table.freeze(BuildRules)

end)()
local LayoutPlan=(function()
--!strict
-- Fixed coordinates make endpoint/support guarantees independent of random decor.
local LayoutPlan = {}
export type Span = { first: number, last: number, gap: boolean }
export type StageLayout = { length: number, index: number?, setPiece: string?, rescueTurtles: number?,
	waves: { { atProgress: number } } }

function LayoutPlan.Build(length: number, stageIndex: number, allowGaps: boolean, reservations: { number }?): { Span }
	local spans: { Span } = {}
	local cursor = -10
	local finish = length + 20
	local safe: { number } = reservations or {}
	local gapWidth = 6 -- conservative baseline; never scaled by stage/difficulty
	if allowGaps and stageIndex >= 5 then
		for _, fraction in { 0.28, 0.70 } do
			local center = math.floor(length * fraction)
			local allowed = center > 35 and center < length - 45 and math.abs(center - length * 0.48) > 32
			for _, x in safe do
				if math.abs(center - x) < 16 then allowed = false end
			end
			if allowed then
				table.insert(spans, { first = cursor, last = center - gapWidth / 2, gap = false })
				table.insert(spans, { first = center - gapWidth / 2, last = center + gapWidth / 2, gap = true })
				cursor = center + gapWidth / 2
			end
		end
	end
	table.insert(spans, { first = cursor, last = finish, gap = false })
	return spans
end

function LayoutPlan.HasSupport(spans: { Span }, x: number, clearance: number?): boolean
	local pad = clearance or 0
	for _, span in spans do
		if not span.gap and x - pad >= span.first and x + pad <= span.last then return true end
	end
	return false
end

-- Set-piece collision must respect the same gaps as the ground plan.
function LayoutPlan.SupportedSlices(spans: { Span }, first: number, last: number): { Span }
	local slices: { Span } = {}
	for _, span in spans do
		local a, b = math.max(first, span.first), math.min(last, span.last)
		if not span.gap and b > a then table.insert(slices, {first=a,last=b,gap=false}) end
	end
	return slices
end

function LayoutPlan.ForStage(stage: StageLayout, spawnX: number): { Span }
	local length = stage.length
	local reservations = { spawnX, length - 6, length * 0.48 - 10, length * 0.82 }
	for _, wave in stage.waves do table.insert(reservations, length * wave.atProgress + 16) end
	for i = 1, stage.rescueTurtles or 0 do table.insert(reservations, length * (0.2 + 0.12 * i)) end
	local allowGaps = stage.setPiece == "bargeGaps" or stage.setPiece == "canalPads"
	return LayoutPlan.Build(length, stage.index or 0, allowGaps, reservations)
end

return LayoutPlan

end)()

local function encode(value)
    local kind=type(value)
    if kind=='nil' then return 'null' end
    if kind=='boolean' or kind=='number' then return tostring(value) end
    if kind=='string' then return '"'..value:gsub('\\','\\\\'):gsub('"','\\"'):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t')..'"' end
    local entries={}
    if #value>0 then
        for _,v in value do table.insert(entries,encode(v)) end
        return '['..table.concat(entries,',')..']'
    end
    for k,v in value do if type(v)~='function' then table.insert(entries,encode(tostring(k))..':'..encode(v)) end end
    return '{'..table.concat(entries,',')..'}'
end
local bounds={}
for capacity=3,6 do
    local b={count=0}; bounds[tostring(capacity)]=b
    for _,field in {'maxHp','damageMult','speedBonus','luck','dodgeBonus'} do b[field]={min=math.huge,max=-math.huge} end
    local ids={}
    local function visit(first)
        if #ids==capacity then
            b.count+=1
            local stats=BuildRules.Compute(ids,Items,Constants)
            for field,score in stats do
                local bound=b[field]
                if score<bound.min then bound.min=score;bound.minBuild=table.clone(ids) end
                if score>bound.max then bound.max=score;bound.maxBuild=table.clone(ids) end
            end
            return
        end
        for i=first,#Items.List-(capacity-#ids)+1 do
            table.insert(ids,Items.List[i].id); visit(i+1); table.remove(ids)
        end
    end
    visit(1)
end
local layouts={}
local layoutChecks=0
for _,stage in Stages.List do
    local spans=LayoutPlan.ForStage(stage,Constants.SPAWN_X)
    local function supported(x,clearance,label)
        assert(LayoutPlan.HasSupport(spans,x,clearance),label..' unsupported: '..stage.id..' at '..tostring(x))
        layoutChecks+=1
    end
    supported(Constants.SPAWN_X,3,'Actual spawn')
    supported(stage.length-6,4,'Actual exit')
    supported(stage.length*0.48-10,5,'Midroom trigger')
    supported(stage.length*0.82,4,'Late encounter reservation')
    for _,wave in stage.waves do supported(stage.length*wave.atProgress+16,3,'Wave landing reservation') end
    for i=1,stage.rescueTurtles do supported(stage.length*(0.2+0.12*i),3,'Actual turtle spawn') end
    assert(spans[1].first==-10 and spans[#spans].last==stage.length+20,'Route endpoints: '..stage.id)
    for i,span in spans do
        assert(span.first<span.last,'Reversed span: '..stage.id)
        if i>1 then assert(spans[i-1].last==span.first,'Discontinuous span: '..stage.id) end
        if span.gap then
            assert(stage.setPiece=='canalPads' or stage.setPiece=='bargeGaps','Unexpected gap stage: '..stage.id)
            assert(span.last-span.first<=6,'Oversized gap: '..stage.id)
        end
    end
    layouts[stage.id]=spans
end
print(encode({stages=Stages.List,personas=Personas.List,enemies=Enemies.List,items=Items.List,weapons=Weapons.List,sets=Items.SetBonuses,movesets=Movesets.List,rarity=Balance.RARITY_POWER,skillCdr=Balance.RARITY_SKILL_CDR,hpScale=Balance.ENEMY_HP_PER_STAGE,damageScale=Balance.ENEMY_DMG_PER_STAGE,minibossHp=Balance.MINIBOSS_HP_ACT,unlocks=ProgressionCatalog,bounds=bounds,layouts=layouts,layoutSupportAssertions=layoutChecks}))
