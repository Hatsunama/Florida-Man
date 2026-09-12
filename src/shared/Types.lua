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
	schemaVersion: number,
	deaths: number,
	sunburn: number,
	unlockedPersonas: { string },
	bestStageIndex: number,
	personaRarity: { [string]: string },
	personas: { string },
	unlockedWeapons: { string },
	weaponId: string,
	totalTurtlesRescued: number,
	settings: {
		ShakeEnabled: boolean,
		ColorblindTelegraphs: boolean,
		ReduceMotion: boolean,
		ReduceFlashes: boolean,
		LargeText: boolean,
		TextSpeed: string,
	},
}

-- Run fields mirrored from GameService.RunState (shared alias; server owns runtime table)
export type RunState = {
	sessionId: string,
	generation: number,
	stateVersion: number,
	phase: string,
	clientReady: boolean,
	characterReady: boolean,
	deathProcessed: boolean,
	completionCommitted: boolean,
	rewardLedger: { [string]: boolean },
	pendingOffer: any?,
	offerSequence: number,
	pendingNewspaper: any?,
	pendingCredits: any?,
	pendingDialogue: {any},
	bossState: any?,
	runTurtlesRescued: number,
	totalTurtlesRescued: number,
	stageId: string,
	stageIndex: number,
	hp: number,
	maxHp: number,
	personas: { string },
	activePersona: number,
	unlockedPersonas: { [string]: boolean },
	personaRarity: { [string]: string },
	items: { string },
	sunshineKills: number,
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
	emberUntil: number,
	facing: number,
	unlockedFireworks: boolean,
	weaponId: string,
	unlockedWeapons: { [string]: boolean },
	moveSpeed: number,
	checkpointX: number,
	tutorial: any,
	steveEvents: { [string]: boolean },
	pendingSteveEvent: string?,
	midRoomState: string,
	lastActShown: number,
}


-- N6: moveset cancel windows (server CombatService owns runtime tables)
-- cancelAfter = seconds after swing start when dodge/skill cancel opens
-- recovery = full swing lock before next attack connect
export type MovesetHit = {
	recovery: number,
	rangeMul: number,
	knockMul: number,
	dmgMul: number,
	cancelAfter: number,
	label: string,
}

export type WeaponSecondary = "foam" | "net" | "none"

return nil
