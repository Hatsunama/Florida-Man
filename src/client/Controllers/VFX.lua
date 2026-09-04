--!strict
--[[ Client VFX — swing arcs by weapon.vfx, hit juice, swap burst, skill patterns. ]]

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local VFX = {}

local function emitBurst(at: Vector3, color: ColorSequence, count: number, speed: NumberRange?)
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
	pe.Color = color
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.15, 0.3)
	pe.Speed = speed or NumberRange.new(4, 10)
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Rate = 0
	pe.LightEmission = 0.75
	pe.Parent = att
	pe:Emit(count)
	Debris:AddItem(p, 0.4)
end

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

local function genericSlash(hrp: BasePart, facing: number, combo: number, color: Color3, sizeMul: number, angleDeg: number)
	local c = combo
	local slash = Instance.new("Part")
	slash.Name = "LocalSwing"
	slash.Anchored = true
	slash.CanCollide = false
	slash.Material = Enum.Material.Neon
	slash.Color = color
	slash.Size = Vector3.new((5.5 + c * 0.8) * sizeMul, 0.35, 3.2 * sizeMul)
	slash.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 4.5, 1.1, 0))
		* CFrame.Angles(0, 0, facing * math.rad(angleDeg + c * 6))
	slash.Transparency = 0.15
	slash.Parent = workspace
	TweenService:Create(slash, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Transparency = 1,
		Size = slash.Size + Vector3.new(2.5, 0, 1.2),
		CFrame = slash.CFrame * CFrame.new(facing * 1.2, 0.2, 0),
	}):Play()
	Debris:AddItem(slash, 0.22)
end

--- Weapon-specific swing arcs. `vfxKind` from Weapons.*.vfx (punch/slap/dart/firework wired).
function VFX.SwingSlash(hrp: BasePart, facing: number, combo: number?, vfxKind: string?)
	local c = combo or 1
	local kind = vfxKind or "swing"
	local origin = hrp.Position + Vector3.new(facing * 3.2, 1.0, 0)

	-- Ranged catalog VFX (flat spark trail — pairs with server lane projectile)
	if kind == "foam" or kind == "balloon" or kind == "hose" or kind == "net" or kind == "firework" then
		local streak = Instance.new("Part")
		streak.Name = "RangedArc"
		streak.Anchored = true
		streak.CanCollide = false
		streak.Material = Enum.Material.Neon
		streak.Color = if kind == "firework" then Color3.fromRGB(255, 80, 160)
			elseif kind == "foam" then Color3.fromRGB(220, 240, 255)
			elseif kind == "hose" then Color3.fromRGB(90, 70, 40)
			elseif kind == "net" then Color3.fromRGB(180, 220, 160)
			else Color3.fromRGB(80, 160, 255)
		streak.Size = Vector3.new(12 + c * 2, 0.25, 0.4)
		streak.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 8, 1.2, 0))
		streak.Transparency = 0.05
		streak.Parent = workspace
		TweenService:Create(streak, TweenInfo.new(0.2), {
			Transparency = 1,
			CFrame = streak.CFrame * CFrame.new(facing * 10, 0, 0),
		}):Play()
		Debris:AddItem(streak, 0.25)
		emitBurst(origin, ColorSequence.new(streak.Color), 14, NumberRange.new(8, 16))
		return
	end
	-- Thrown catalog VFX (arcing preview — pairs with server gravity projectile)
	if kind == "dart" or kind == "cone" or kind == "lasso" or kind == "disc" or kind == "rocket" then
		local streak = Instance.new("Part")
		streak.Name = "ThrownArc"
		streak.Anchored = true
		streak.CanCollide = false
		streak.Material = Enum.Material.Neon
		streak.Color = if kind == "rocket" then Color3.fromRGB(255, 100, 60)
			elseif kind == "dart" then Color3.fromRGB(180, 255, 120)
			elseif kind == "cone" then Color3.fromRGB(255, 140, 40)
			else Color3.fromRGB(200, 220, 255)
		streak.Size = Vector3.new(8 + c, 0.35, 0.5)
		streak.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 5, 2.0, 0))
			* CFrame.Angles(0, 0, facing * math.rad(-28))
		streak.Transparency = 0.05
		streak.Parent = workspace
		TweenService:Create(streak, TweenInfo.new(0.28), {
			Transparency = 1,
			CFrame = streak.CFrame * CFrame.new(facing * 8, -2.5, 0) * CFrame.Angles(0, 0, facing * math.rad(40)),
		}):Play()
		Debris:AddItem(streak, 0.32)
		emitBurst(origin + Vector3.new(0, 1.5, 0), ColorSequence.new(streak.Color), 12)
		return
	end
	if kind == "punch" then
		-- Short fist burst
		local fist = Instance.new("Part")
		fist.Name = "PunchArc"
		fist.Shape = Enum.PartType.Ball
		fist.Anchored = true
		fist.CanCollide = false
		fist.Material = Enum.Material.Neon
		fist.Color = if c >= 3 then Color3.fromRGB(255, 200, 80) else Color3.fromRGB(255, 240, 200)
		fist.Size = Vector3.new(1.2 + c * 0.25, 1.2 + c * 0.25, 1.2 + c * 0.25)
		fist.CFrame = CFrame.new(origin)
		fist.Transparency = 0.1
		fist.Parent = workspace
		TweenService:Create(fist, TweenInfo.new(0.16), {
			Transparency = 1,
			Size = fist.Size * 2.2,
			CFrame = fist.CFrame * CFrame.new(facing * 2.5, 0, 0),
		}):Play()
		Debris:AddItem(fist, 0.2)
		emitBurst(origin, ColorSequence.new(Color3.fromRGB(255, 245, 200), Color3.fromRGB(255, 160, 60)), 8 + c * 2)
		return
	elseif kind == "slap" then
		-- Wide horizontal flip-flop arc
		genericSlash(hrp, facing, c, Color3.fromRGB(255, 120, 160), 1.25, -8)
		local flop = Instance.new("Part")
		flop.Name = "SlapArc"
		flop.Anchored = true
		flop.CanCollide = false
		flop.Material = Enum.Material.SmoothPlastic
		flop.Color = Color3.fromRGB(40, 40, 50)
		flop.Size = Vector3.new(2.2, 0.25, 1.1)
		flop.CFrame = CFrame.new(origin) * CFrame.Angles(0, 0, facing * math.rad(-25))
		flop.Parent = workspace
		TweenService:Create(flop, TweenInfo.new(0.2), {
			Transparency = 1,
			CFrame = flop.CFrame * CFrame.new(facing * 3, 0.4, 0) * CFrame.Angles(0, 0, facing * math.rad(50)),
		}):Play()
		Debris:AddItem(flop, 0.22)
		emitBurst(origin, ColorSequence.new(Color3.fromRGB(255, 180, 200), Color3.fromRGB(255, 80, 120)), 12)
		return
	elseif kind == "dart" then
		-- Thin thrown streak + tip spark
		local streak = Instance.new("Part")
		streak.Name = "DartArc"
		streak.Anchored = true
		streak.CanCollide = false
		streak.Material = Enum.Material.Neon
		streak.Color = Color3.fromRGB(180, 255, 120)
		streak.Size = Vector3.new(10 + c, 0.18, 0.35)
		streak.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 7, 1.3, 0))
		streak.Transparency = 0.05
		streak.Parent = workspace
		TweenService:Create(streak, TweenInfo.new(0.22), {
			Transparency = 1,
			CFrame = streak.CFrame * CFrame.new(facing * 6, -0.3, 0),
			Size = Vector3.new(14, 0.1, 0.2),
		}):Play()
		Debris:AddItem(streak, 0.25)
		local tip = hrp.Position + Vector3.new(facing * 14, 1.0, 0)
		emitBurst(tip, ColorSequence.new(Color3.fromRGB(220, 255, 160), Color3.fromRGB(80, 200, 60)), 10, NumberRange.new(2, 6))
		return
	elseif kind == "firework" then
		-- Multicolor sparkler trail
		genericSlash(hrp, facing, c, Color3.fromRGB(255, 80, 160), 0.9, -22)
		local colors = {
			Color3.fromRGB(255, 80, 120),
			Color3.fromRGB(255, 220, 60),
			Color3.fromRGB(80, 180, 255),
			Color3.fromRGB(180, 80, 255),
		}
		for i, col in colors do
			task.delay((i - 1) * 0.03, function()
				emitBurst(
					origin + Vector3.new(facing * i * 1.2, 0.3 * i, 0),
					ColorSequence.new(col, col:Lerp(Color3.new(1, 1, 1), 0.4)),
					8,
					NumberRange.new(6, 14)
				)
			end)
		end
		return
	end

	-- Default / catalog fallback (swing, grab, bash, …)
	genericSlash(
		hrp,
		facing,
		c,
		if c >= 3 then Color3.fromRGB(255, 160, 60) else Color3.fromRGB(255, 235, 140),
		1,
		-18
	)
	emitBurst(origin, ColorSequence.new(Color3.fromRGB(255, 240, 180), Color3.fromRGB(255, 160, 60)), 10 + c * 3)
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
