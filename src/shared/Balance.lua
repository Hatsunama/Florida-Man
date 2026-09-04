--!strict
--[[ Difficulty + power curve. Stage index drives enemy HP/damage;
	player keeps up via weapons, items, and persona rarity. ]]

local Balance = {}

-- Enemy scaling: HP *= (1 + 0.12 * stageIndex); damage *= (1 + 0.08 * stageIndex)
Balance.ENEMY_HP_PER_STAGE = 0.12
Balance.ENEMY_DMG_PER_STAGE = 0.08

-- Persona rarity → attack & skill power
Balance.RARITY_POWER = {
	Common = 0,
	Rare = 0.15,
	Unique = 0.30,
	Legendary = 0.50,
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

return Balance
