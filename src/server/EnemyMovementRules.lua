--!strict
-- Pure horizontal containment; world adapters supply the current gate face.
local Rules = {}
local negativeZ: {[string]: boolean} = {crab=true,lizard=true,slime=true,humanoid=true,boss=true,turtle=true,drone=true,pelican=true,cloud=true}
function Rules.ForwardAxis(shape: string): string
	return if negativeZ[shape] then '-Z' else '+X'
end
function Rules.FacingYaw(facing: number, forwardAxis: string): number
	if forwardAxis == '-Z' then return if facing < 0 then math.pi / 2 else -math.pi / 2 end
	return if facing < 0 then math.pi else 0
end
function Rules.ClampX(x: number, stageLength: number, halfWidth: number, lockedGateLeft: number?): number
	local lower = math.max(0, halfWidth) + 0.5
	local upper = math.max(lower, stageLength - halfWidth - 0.5)
	if lockedGateLeft then upper = math.max(lower, math.min(upper, lockedGateLeft - halfWidth - 0.25)) end
	if x ~= x then return lower end
	return math.clamp(x, lower, upper)
end
return table.freeze(Rules)
