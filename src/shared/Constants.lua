--!strict
local Constants = {
	GAME_NAME = "Florida Man",
	TAGLINE_MUTANTS = "It IS Florida… Anything is possible in the swamp I guess.",
	COMBO_WINDOW = 0.45,
	DODGE_IFRAME = 0.38,
	DODGE_COOLDOWN = 0.72,
	DODGE_DISTANCE = 18,
	SWAP_COOLDOWN = 1.15,
	SWAP_ATTACK_DAMAGE_MULT = 1.45,
	SWAP_IFRAME = 0.28, -- brief armor during swap-attack
	BASE_HP = 100,
	ATTACK_RANGE = 10,
	ATTACK_BUFFER = 0.12, -- Skul-like input buffer window
	ATTACK_RECOVERY = 0.22, -- base swing lock before next connect
	HITSTOP = 0.045, -- 0.03–0.06s freeze on every connect
	HITSTOP_HEAVY = 0.06, -- combo finisher / skill connect
	FLINCH_TIME = 0.18, -- enemy stun on hit (readable)
	STARTING_PERSONA = "BeachBurnout",
	STARTING_WEAPON = "BareHands",
	STARTING_ITEM_SLOTS = 1,
	ITEM_SLOTS_AFTER_FIRST_DEATH = 2,
	DRAFT_CHOICES = 3,
	INSCRIPTION_SET_SIZE = 3,
	SUNBURN_PER_COMMON = 5,
	SUNBURN_PER_RARE = 12,
	SUNBURN_PER_UNIQUE = 25,
	SUNBURN_PER_LEGENDARY = 50,
	LANE_Z = 0,
	STAGE_LENGTH = 240,
	SPAWN_X = 18, -- hub: within ProximityPrompt range of Flame at x=20
	REMOTE_FOLDER = "Remotes",
	COLD_ONE_HEAL = 35,
	HANGOVER_SLOW = 0.88,
	HANGOVER_DURATION = 999, -- cleared by Cold One pickup (stage 1 only)
	KNOCKBACK_BASE = 7,
	CAMERA_DEPTH = 32, -- side-scroll depth ~30–34
}
return Constants
