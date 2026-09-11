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
