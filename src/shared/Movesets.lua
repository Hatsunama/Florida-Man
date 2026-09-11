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
