--!strict
--[[ Client VFX — swing, hit juice, swap burst, skill patterns, dodge readability. ]]

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

function VFX.SwingSlash(hrp: BasePart, facing: number, combo: number?)
	local c = combo or 1
	local slash = Instance.new("Part")
	slash.Name = "LocalSwing"
	slash.Anchored = true
	slash.CanCollide = false
	slash.Material = Enum.Material.Neon
	slash.Color = if c >= 3 then Color3.fromRGB(255, 160, 60) else Color3.fromRGB(255, 235, 140)
	slash.Size = Vector3.new(5.5 + c * 0.8, 0.35, 3.2)
	slash.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 4.5, 1.1, 0))
		* CFrame.Angles(0, 0, facing * math.rad(-18 + c * 6))
	slash.Transparency = 0.15
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = slash.Size + Vector3.new(2.5, 0, 1.2),
		CFrame = slash.CFrame * CFrame.new(facing * 1.2, 0.2, 0),
	}):Play()
	Debris:AddItem(slash, 0.22)

	local whoosh = Instance.new("Part")
	whoosh.Anchored = true
	whoosh.CanCollide = false
	whoosh.Transparency = 1
	whoosh.Size = Vector3.new(0.2, 0.2, 0.2)
	whoosh.Position = hrp.Position + Vector3.new(facing * 3, 1, 0)
	whoosh.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = whoosh
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 180), Color3.fromRGB(255, 160, 60))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.15, 0.28)
	pe.Speed = NumberRange.new(4, 10)
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Rate = 0
	pe.LightEmission = 0.7
	pe.Parent = att
	pe:Emit(10 + c * 3)
	Debris:AddItem(whoosh, 0.35)
end

function VFX.HitSpark(at: Vector3, heavy: boolean?)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Position = at
	p.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = p
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(255, 140, 40))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, if heavy then 1.2 else 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.12, 0.28)
	pe.Speed = NumberRange.new(6, 14)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.Rate = 0
	pe.LightEmission = 0.9
	pe.Parent = att
	pe:Emit(if heavy then 22 else 12)
	-- flash ring
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(255, 220, 120)
	ring.Size = Vector3.new(0.3, 1.5, 1.5)
	ring.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.2
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.15), { Size = Vector3.new(0.3, 6, 6), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.2)
	Debris:AddItem(p, 0.4)
end

function VFX.SwapBurst(hrp: BasePart, color: Color3?)
	local col = color or Color3.fromRGB(255, 160, 40)
	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = col
	ring.Size = Vector3.new(0.5, 6, 6)
	ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.28), { Size = Vector3.new(0.4, 18, 18), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.32)
	-- slash arc = swap-attack piece
	local slash = Instance.new("Part")
	slash.Anchored = true
	slash.CanCollide = false
	slash.Material = Enum.Material.Neon
	slash.Color = col
	slash.Size = Vector3.new(10, 0.5, 4)
	slash.CFrame = hrp.CFrame * CFrame.new(0, 1, 0)
	slash.Transparency = 0.1
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.22), { Transparency = 1, Size = Vector3.new(14, 0.3, 6) }):Play()
	Debris:AddItem(slash, 0.25)
	local att = Instance.new("Attachment")
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(col)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.25, 0.4)
	pe.Speed = NumberRange.new(4, 12)
	pe.Rate = 0
	pe.LightEmission = 0.8
	pe.Parent = att
	pe:Emit(24)
	Debris:AddItem(att, 0.5)
end

function VFX.SkillPattern(hrp: BasePart, kind: string, facing: number)
	local origin = hrp.Position
	if kind == "beam" then
		local beam = Instance.new("Part")
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = Color3.fromRGB(255, 120, 40)
		beam.Size = Vector3.new(22, 1.2, 3)
		beam.CFrame = CFrame.new(origin + Vector3.new(facing * 12, 1.2, 0))
		beam.Transparency = 0.15
		beam.Parent = workspace
		TweenService:Create(beam, TweenInfo.new(0.35), { Transparency = 1, Size = Vector3.new(26, 0.4, 4) }):Play()
		Debris:AddItem(beam, 0.4)
	elseif kind == "wave" then
		for i = 1, 3 do
			task.delay((i - 1) * 0.05, function()
				local w = Instance.new("Part")
				w.Anchored = true
				w.CanCollide = false
				w.Material = Enum.Material.ForceField
				w.Color = Color3.fromRGB(255, 200, 80)
				w.Size = Vector3.new(4 + i * 3, 2, 5)
				w.CFrame = CFrame.new(origin + Vector3.new(facing * (6 + i * 4), 1, 0))
				w.Transparency = 0.3
				w.Parent = workspace
				TweenService:Create(w, TweenInfo.new(0.3), { Transparency = 1 }):Play()
				Debris:AddItem(w, 0.35)
			end)
		end
	elseif kind == "aoe" or kind == "summon" then
		local burst = Instance.new("Part")
		burst.Shape = Enum.PartType.Ball
		burst.Anchored = true
		burst.CanCollide = false
		burst.Material = Enum.Material.ForceField
		burst.Color = if kind == "summon" then Color3.fromRGB(120, 255, 140) else Color3.fromRGB(255, 80, 120)
		burst.Size = Vector3.new(4, 4, 4)
		burst.CFrame = CFrame.new(origin)
		burst.Parent = workspace
		TweenService:Create(burst, TweenInfo.new(0.4), { Size = Vector3.new(22, 22, 22), Transparency = 1 }):Play()
		Debris:AddItem(burst, 0.45)
	elseif kind == "dash" then
		for i = 1, 5 do
			task.delay((i - 1) * 0.03, function()
				local g = Instance.new("Part")
				g.Anchored = true
				g.CanCollide = false
				g.Material = Enum.Material.ForceField
				g.Color = Color3.fromRGB(100, 200, 255)
				g.Size = Vector3.new(2, 4, 1)
				g.CFrame = CFrame.new(origin + Vector3.new(facing * i * 2.5, 0, 0))
				g.Transparency = 0.3
				g.Parent = workspace
				TweenService:Create(g, TweenInfo.new(0.25), { Transparency = 1 }):Play()
				Debris:AddItem(g, 0.3)
			end)
		end
	elseif kind == "shield" then
		local shell = Instance.new("Part")
		shell.Shape = Enum.PartType.Ball
		shell.Anchored = true
		shell.CanCollide = false
		shell.Material = Enum.Material.ForceField
		shell.Color = Color3.fromRGB(80, 220, 160)
		shell.Size = Vector3.new(6, 6, 6)
		shell.CFrame = CFrame.new(origin)
		shell.Transparency = 0.35
		shell.Parent = workspace
		TweenService:Create(shell, TweenInfo.new(1.0), { Transparency = 1, Size = Vector3.new(10, 10, 10) }):Play()
		Debris:AddItem(shell, 1.05)
	else
		local burst = Instance.new("Part")
		burst.Shape = Enum.PartType.Ball
		burst.Anchored = true
		burst.CanCollide = false
		burst.Material = Enum.Material.ForceField
		burst.Color = Color3.fromRGB(120, 220, 255)
		burst.Size = Vector3.new(4, 4, 4)
		burst.CFrame = CFrame.new(origin)
		burst.Parent = workspace
		TweenService:Create(burst, TweenInfo.new(0.35), { Size = Vector3.new(16, 16, 16), Transparency = 1 }):Play()
		Debris:AddItem(burst, 0.4)
	end
end

return VFX
