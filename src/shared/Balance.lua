--!strict
--[[ Difficulty + power curve (documented).
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
	  HP  *= 1 + 0.10 * idx   (was 0.12 — less sponge late)
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

Balance.ENEMY_HP_PER_STAGE = 0.10
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

-- Wave density hint used by GameService (early teach, late elite)
function Balance.WaveSpawnCap(stageIndex: number, requested: number): number
	local maxH = Balance.MaxHostiles(stageIndex)
	if stageIndex <= 2 then
		return math.min(requested, 2, maxH)
	elseif stageIndex <= 5 then
		return math.min(requested, 2, maxH)
	else
		return math.min(requested, maxH)
	end
end

return Balance
