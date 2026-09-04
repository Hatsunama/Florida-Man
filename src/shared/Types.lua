--!strict
export type Inscription = "HUMID" | "FERAL" | "LUCKY" | "GREASY" | "HEROIC" | "CHAOS"
export type Rarity = "Common" | "Rare" | "Unique" | "Legendary"
export type WeaponKind = "melee" | "ranged" | "thrown"
export type HazardKind =
	"sandSlow"
	| "fryerOil"
	| "hoaCone"
	| "slushPuddle"
	| "oilSlick"
	| "fireCone"
	| "canalWater"
	| "redTide"
	| "pipeSpray"
	| "slickRing"
	| "movingSample"
	| "conveyor"
	| "windPush"

-- Meta persist shape (mirrors MetaService.MetaProfile)
export type MetaProfile = {
	deaths: number,
	sunburn: number,
	unlockedPersonas: { string },
	bestStageIndex: number,
	settings: {
		ShakeEnabled: boolean,
		ColorblindTelegraphs: boolean,
	},
}

-- Run fields mirrored from GameService.RunState (shared alias; server owns runtime table)
export type RunState = {
	stageId: string,
	stageIndex: number,
	hp: number,
	maxHp: number,
	personas: { string },
	activePersona: number,
	unlockedPersonas: { [string]: boolean },
	personaRarity: { [string]: string },
	items: { string },
	itemSlots: number,
	sunburn: number,
	luck: number,
	damageMult: number,
	speedBonus: number,
	dodgeBonus: number,
	deaths: number,
	turtlesRescued: number,
	turtlesNeeded: number,
	hangoverUntil: number,
	coldOneTaken: boolean,
	waveFlags: { [number]: boolean },
	minibossSpawned: boolean,
	bossSpawned: boolean,
	bossDefeated: boolean,
	awaitingDraft: boolean,
	awaitingNewspaper: boolean,
	inHub: boolean,
	runActive: boolean,
	combo: number,
	lastAttackAt: number,
	lastHurtAt: number,
	skillReadyAt: number,
	swapReadyAt: number,
	dodgeReadyAt: number,
	facing: number,
	unlockedFireworks: boolean,
	weaponId: string,
	unlockedWeapons: { [string]: boolean },
	moveSpeed: number,
	checkpointX: number,
	midRoomState: string,
	lastActShown: number,
}

return nil
