--!strict
-- Overlapping hazards commute: one strongest damage tick, additive bounded motion,
-- independent slowing categories. Geometry and cooldowns belong to the server adapter.
local Rules = {}
export type Definition = {slow: ('oil' | 'environment')?,water: boolean?,damage: number?,oilResist: boolean?,impulseY: number?,velocityX: number?,velocityY: number?}
export type Effects = {damage: number,impulseY: number,velocityX: number,velocityY: number,oilSlow: boolean,environmentSlow: boolean,water: boolean}
function Rules.New(): Effects
	return {damage=0,impulseY=0,velocityX=0,velocityY=0,oilSlow=false,environmentSlow=false,water=false}
end
function Rules.Add(result: Effects, def: Definition, oilResist: boolean, direction: number)
	result.oilSlow = result.oilSlow or def.slow == 'oil'
	result.environmentSlow = result.environmentSlow or def.slow == 'environment'
	result.water = result.water or def.water == true
	result.velocityX += (def.velocityX or 0) * direction
	result.velocityY += def.velocityY or 0
	local damage = def.damage or 0
	if def.oilResist and oilResist and damage > 0 then damage = math.max(1, math.floor(damage * 0.5)) end
	result.damage = math.max(result.damage, damage)
	result.impulseY = math.max(result.impulseY, def.impulseY or 0)
end
function Rules.SlowMultiplier(hungover: boolean, oiled: boolean, environmental: boolean, oilResist: boolean, hangoverMult: number, slowMult: number, oilResistMult: number): number
	local result = 1
	if hungover then result = math.min(result, hangoverMult) end
	if oiled then result = math.min(result, if oilResist then oilResistMult else slowMult) end
	if environmental then result = math.min(result, slowMult) end
	return result
end
return table.freeze(Rules)
