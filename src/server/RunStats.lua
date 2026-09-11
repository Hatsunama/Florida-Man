--!strict
-- Derived build statistics only. No persistence, transport, or character mutation.
local Shared = game:GetService('ReplicatedStorage'):WaitForChild('Shared')
local Constants = require(Shared:WaitForChild('Constants'))
local Items = require(Shared:WaitForChild('Items'))
local Types = require(Shared:WaitForChild('Types'))
type RunState = Types.RunState
local BuildRules=require(Shared:WaitForChild("BuildRules"))
local RunStats = {}
function RunStats.ComputeStats(s: RunState)
    local result=BuildRules.Compute(s.items,Items,Constants)
    s.maxHp=result.maxHp; s.damageMult=result.damageMult; s.speedBonus=result.speedBonus
    s.luck=result.luck; s.dodgeBonus=result.dodgeBonus
    s.hp=math.min(s.hp,s.maxHp)
end

function RunStats.HasItemSpecial(s: RunState, special: string): boolean
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == special then
			return true
		end
	end
	return false
end

function RunStats.HasHeroicLifesteal(s: RunState): boolean
	local counts = Items.CountInscriptions(s.items)
	return (counts.HEROIC or 0) >= Constants.INSCRIPTION_SET_SIZE
end

function RunStats.HasGreasyOilResist(s: RunState): boolean
	local counts = Items.CountInscriptions(s.items)
	return (counts.GREASY or 0) >= Constants.INSCRIPTION_SET_SIZE
end


return RunStats
