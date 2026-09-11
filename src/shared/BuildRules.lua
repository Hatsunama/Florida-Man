--!strict
-- Pure derivation from catalog definitions, shared by runtime and balance analysis.
local BuildRules={}
export type Stats={maxHp:number,damageMult:number,speedBonus:number,luck:number,dodgeBonus:number}
function BuildRules.Compute(ids: {string}, Items: any, Constants: any): Stats
	local maxHp = Constants.BASE_HP
	local dmg = 1
	local speed = 0
	local luck = 0
	local dodge = 0
	for _, id in ids do
		local it = Items.Get(id)
		if it then
			maxHp += it.hpBonus
			dmg += it.damageBonus / 20
			speed += it.speedBonus
			luck += it.luckBonus
			dodge += it.dodgeBonus
			if it.special == "antiCorp" then
				dmg += 0.08
			end
			if it.special == "badge" then
				maxHp += 5
				dmg += 0.1
			end
		end
	end
	local counts = Items.CountInscriptions(ids)
	for tag, n in counts do
		if n >= Constants.INSCRIPTION_SET_SIZE then
			local bonus = Items.SetBonuses[tag]
			if bonus then
				maxHp += bonus.hpBonus or 0
				if bonus.damageBonus then
					dmg += bonus.damageBonus
				end
				luck += bonus.luckBonus or 0
				dodge += bonus.dodgeBonus or 0
			end
		end
	end
    return {maxHp=maxHp,damageMult=dmg,speedBonus=speed,luck=luck,dodgeBonus=dodge}
end

return table.freeze(BuildRules)
