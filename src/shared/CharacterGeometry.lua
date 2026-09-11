--!strict
-- Rig dimensions, shared by movement and hazard adapters. R6 HipHeight excludes
-- leg length; omitting it makes a standing R6 character appear airborne.
local Geometry={}
function Geometry.StandingHeight(hipHeight: number, rootHeight: number, r6LegHeight: number?): number
	return math.max(0,hipHeight)+math.max(0,rootHeight)*0.5+math.max(0,r6LegHeight or 0)
end
function Geometry.FeetDistance(char: Model, root: BasePart, hum: Humanoid): number
	local legHeight: number?=nil
	if hum.RigType==Enum.HumanoidRigType.R6 then
		local leg=char:FindFirstChild('Left Leg') or char:FindFirstChild('Right Leg')
		legHeight=if leg and leg:IsA('BasePart') then leg.Size.Y else 2
	end
	return Geometry.StandingHeight(hum.HipHeight,root.Size.Y,legHeight)
end
return table.freeze(Geometry)
