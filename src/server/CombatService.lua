--!strict
--[[ CombatService — knockback helpers + hit validation shared with GameService. ]]

local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local CombatService = {}

function CombatService.LaneKnockback(originX: number, targetPos: Vector3, strength: number): Vector3
	local dir = if targetPos.X >= originX then 1 else -1
	local kb = math.clamp(strength or Constants.KNOCKBACK_BASE, 0, 24)
	return Vector3.new(targetPos.X + dir * kb, targetPos.Y, Constants.LANE_Z)
end

function CombatService.InLaneMelee(attackerX: number, facing: number, targetX: number, range: number): boolean
	local dx = targetX - attackerX
	if math.abs(dx) <= 3.5 then
		return true
	end
	return math.abs(dx) <= range and math.sign(dx + 0.001) == facing
end

return CombatService
