--!strict
--[[ Client VFX helpers — footstep dust, ripples, juice. ]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local VFX = {}

function VFX.FootstepDust(at: Vector3)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = Vector3.new(at.X, 0.3, Constants.LANE_Z)
	p.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(210, 180, 120))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.8) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.25, 0.45)
	pe.Speed = NumberRange.new(1, 3)
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(6)
	Debris:AddItem(p, 0.5)
end

function VFX.WaterRipple(at: Vector3)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.ForceField
	ring.Color = Color3.fromRGB(120, 180, 255)
	ring.Size = Vector3.new(0.2, 2, 2)
	ring.CFrame = CFrame.new(at.X, 0.4, Constants.LANE_Z) * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.45), { Size = Vector3.new(0.2, 8, 8), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.5)
end

return VFX
