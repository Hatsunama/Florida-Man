--!strict
-- Pure item decisions; server services own kill eligibility and reward claims.
local Rules = {}

function Rules.StageClear(health: number, maxHealth: number, equipped: boolean): number
	if not equipped or health <= 0 then return health end
	return math.min(maxHealth, health + maxHealth * 0.03)
end

function Rules.EnemyKill(health: number, maxHealth: number, progress: number, equipped: boolean, eligible: boolean): (number, number)
	if not equipped then return health, 0 end
	if not eligible or health <= 0 then return health, progress end
	local nextProgress = progress + 1
	if nextProgress < 3 then return health, nextProgress end
	-- Consume the third kill even at full HP; healing cannot be banked.
	return math.min(maxHealth, health + 1), 0
end

function Rules.EquipmentProgress(progress: number, wasEquipped: boolean, equipped: boolean): number
	return if wasEquipped and equipped then progress else 0
end

return table.freeze(Rules)
