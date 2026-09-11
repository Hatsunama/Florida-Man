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
