--!strict
--[[ EnemyFactory — single Model, WeldConstraints/Motor6Ds, animated silhouettes.
	NEVER leave orphan Anchored accent parts. All limbs move with root.
]]

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArtAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArtAssets"))
local MovementRules = require(script.Parent:WaitForChild('EnemyMovementRules'))

local EnemyFactory = {}
local rigCache: { [Model]: { Instance }? } = {}

local function clearCached(model: Model)
	rigCache[model] = nil
end

local function rigParts(model: Model): { Instance }
	local cached = rigCache[model]
	if cached then return cached end
	local parts: { Instance } = model:GetDescendants()
	rigCache[model] = parts
	model.Destroying:Connect(function() clearCached(model) end)
	return parts
end

local function weld(a: BasePart, b: BasePart, name: string?): WeldConstraint
	local w = Instance.new("WeldConstraint")
	w.Name = name or "Weld"
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Name = props.Name or "Part"
	p.Size = props.Size or Vector3.new(1, 1, 1)
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Anchored = false
	p.CanCollide = props.CanCollide == true
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = props.Massless ~= false
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	p.CFrame = props.CFrame or CFrame.new()
	p.Parent = props.Parent
	return p
end

local function attachToRoot(root: BasePart, child: BasePart)
	-- Static visual parts only — NEVER use on Motor6D Part0/Part1 driven limbs
	child.Anchored = false
	child.CanCollide = false
	child.Massless = true
	weld(root, child)
end

local function addSpecialMesh(p: BasePart, meshType: Enum.MeshType, scale: Vector3?): SpecialMesh
	local sm = Instance.new("SpecialMesh")
	sm.Name = "ArtMesh"
	sm.MeshType = meshType
	if scale then
		sm.Scale = scale
	end
	sm.Parent = p
	return sm
end

local function tagArtKit(model: Model, kit: string?)
	model:SetAttribute("ArtKit", kit or ArtAssets.ART_KIT_PART)
end

local function motor6d(name: string, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame?): Motor6D
	part1.Anchored = false
	part1.CanCollide = false
	part1.Massless = true
	local m = Instance.new("Motor6D")
	m.Name = name
	m.Part0 = part0
	m.Part1 = part1
	m.C0 = c0
	m.C1 = c1 or CFrame.new()
	m.Parent = part0
	return m
end

local function isMotorConnected(model: Model, part: BasePart): boolean
	for _, c in model:GetDescendants() do
		if c:IsA("Motor6D") and (c.Part0 == part or c.Part1 == part) then
			return true
		end
		if c:IsA("WeldConstraint") and (c.Part0 == part or c.Part1 == part) then
			return true
		end
	end
	return false
end

local function buildCrab(model: Model, root: Part, def: any)
	local s = def.size
	-- Wider flatter body — stylized crab silhouette
	root.Size = Vector3.new(s.X * 0.95, s.Y * 0.55, s.Z * 0.75)
	root.Shape = Enum.PartType.Block
	root.Material = Enum.Material.Sand
	root.Color = def.color
	root.TopSurface = Enum.SurfaceType.Smooth
	root.BottomSurface = Enum.SurfaceType.Smooth

	-- Beveled carapace stack (shell feel without meshes)
	local shell = part({
		Name = "Carapace",
		Parent = model,
		Size = Vector3.new(s.X * 1.15, s.Y * 0.42, s.Z * 0.95),
		Color = def.color:Lerp(Color3.fromRGB(255, 110, 50), 0.22),
		Material = Enum.Material.SmoothPlastic,
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.28, 0),
	})
	attachToRoot(root, shell)
	local dome = part({
		Name = "ShellDome",
		Parent = model,
		Size = Vector3.new(s.X * 0.75, s.Y * 0.35, s.Z * 0.65),
		Shape = Enum.PartType.Ball,
		Color = def.color:Lerp(Color3.fromRGB(255, 90, 40), 0.35),
		Material = Enum.Material.Sand,
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.42, 0.05),
	})
	addSpecialMesh(dome, Enum.MeshType.Sphere, Vector3.new(1.05, 0.85, 1.0))
	attachToRoot(root, dome)
	local ridge = part({
		Name = "ShellRidge",
		Parent = model,
		Size = Vector3.new(s.X * 0.15, s.Y * 0.2, s.Z * 0.7),
		Color = def.color:Lerp(Color3.fromRGB(40, 15, 10), 0.35),
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.5, 0),
	})
	attachToRoot(root, ridge)
	local mustard = part({
		Name = "MustardStripe",
		Parent = model,
		Size = Vector3.new(s.X * 0.08, s.Y * 0.12, s.Z * 0.55),
		Color = Color3.fromRGB(255, 200, 40),
		Material = Enum.Material.Neon,
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.52, 0),
	})
	attachToRoot(root, mustard)

	local belly = part({
		Name = "CrabBelly",
		Parent = model,
		Size = Vector3.new(s.X * 0.7, s.Y * 0.25, s.Z * 0.55),
		Color = def.color:Lerp(Color3.fromRGB(255, 200, 160), 0.4),
		Material = Enum.Material.SmoothPlastic,
		CFrame = root.CFrame * CFrame.new(0, -s.Y * 0.12, 0.1),
	})
	attachToRoot(root, belly)

	-- Eye stalks (static welds to root)
	for _, side in { -1, 1 } do
		local stalk = part({
			Name = "EyeStalk",
			Parent = model,
			Size = Vector3.new(0.22, 1.25, 0.22),
			Color = def.color,
			CFrame = root.CFrame * CFrame.new(side * s.X * 0.22, s.Y * 0.62, -s.Z * 0.28),
		})
		attachToRoot(root, stalk)
		local eye = part({
			Name = "Eye",
			Parent = model,
			Size = Vector3.new(0.5, 0.5, 0.5),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(18, 18, 18),
			CFrame = stalk.CFrame * CFrame.new(0, 0.7, 0),
		})
		attachToRoot(root, eye)
		local pupil = part({
			Name = "PupilGlow",
			Parent = model,
			Size = Vector3.new(0.22, 0.22, 0.22),
			Shape = Enum.PartType.Ball,
			Color = def.accent,
			Material = Enum.Material.Neon,
			CFrame = eye.CFrame * CFrame.new(0, 0, -0.18),
		})
		attachToRoot(root, pupil)
	end

	-- 6 legs: hip bone Motor6D from root (NO weld on animated chain)
	local legsFolder = Instance.new("Folder")
	legsFolder.Name = "Legs"
	legsFolder.Parent = model
	for i = 1, 6 do
		local side = if i <= 3 then -1 else 1
		local row = ((i - 1) % 3) - 1
		local hipCF = root.CFrame * CFrame.new(side * s.X * 0.48, -s.Y * 0.05, row * s.Z * 0.32)
		local hip = part({
			Name = "LegHip" .. i,
			Parent = legsFolder,
			Size = Vector3.new(0.32, 0.32, 0.32),
			Color = def.color,
			CFrame = hipCF,
		})
		-- Root → hip via Motor6D only (animatable / assembly stays connected)
		motor6d(
			"RootHipMotor",
			root,
			hip,
			CFrame.new(side * s.X * 0.48, -s.Y * 0.05, row * s.Z * 0.32),
			CFrame.new()
		)
		hip:SetAttribute("LegIndex", i)
		hip:SetAttribute("LegSide", side)

		local upper = part({
			Name = "LegUpper" .. i,
			Parent = legsFolder,
			Size = Vector3.new(0.26, 1.05, 0.26),
			Color = def.color:Lerp(Color3.fromRGB(40, 20, 10), 0.2),
			CFrame = hipCF * CFrame.new(side * 0.65, -0.25, 0) * CFrame.Angles(0, 0, side * math.rad(40)),
		})
		motor6d("HipMotor", hip, upper, CFrame.new(side * 0.18, 0, 0), CFrame.new(0, 0.45, 0))

		local lower = part({
			Name = "LegLower" .. i,
			Parent = legsFolder,
			Size = Vector3.new(0.2, 0.95, 0.2),
			Color = def.accent,
			CFrame = upper.CFrame * CFrame.new(side * 0.3, -0.75, 0),
		})
		motor6d("KneeMotor", upper, lower, CFrame.new(0, -0.5, 0), CFrame.new(0, 0.4, 0))

		local tip = part({
			Name = "Foot" .. i,
			Parent = legsFolder,
			Size = Vector3.new(0.35, 0.18, 0.45),
			Color = def.color:Lerp(Color3.fromRGB(30, 10, 5), 0.4),
			CFrame = lower.CFrame * CFrame.new(0, -0.5, 0),
		})
		-- Foot is decorative child of lower — Motor6D keeps it in the chain (no root weld)
		motor6d("FootMotor", lower, tip, CFrame.new(0, -0.45, 0), CFrame.new())
	end

	-- Claws: Motor6D chain from root — snap on attack telegraph
	for _, side in { -1, 1 } do
		local arm = part({
			Name = "ClawArm",
			Parent = model,
			Size = Vector3.new(0.42, 0.42, 1.35),
			Color = def.color,
			CFrame = root.CFrame * CFrame.new(side * s.X * 0.55, 0.15, -s.Z * 0.4),
		})
		motor6d(
			"ClawMotor",
			root,
			arm,
			CFrame.new(side * s.X * 0.42, 0.15, -s.Z * 0.15),
			CFrame.new(0, 0, 0.45)
		)

		local claw = part({
			Name = "Claw",
			Parent = model,
			Size = Vector3.new(1.25, 0.75, 1.55),
			Color = def.color:Lerp(Color3.fromRGB(255, 80, 40), 0.18),
			CFrame = arm.CFrame * CFrame.new(0, 0, -0.95),
		})
		motor6d("PinchMotor", arm, claw, CFrame.new(0, 0, -0.75), CFrame.new())

		-- Dual pincer tips — welded to claw only (static relative to claw)
		local tipA = part({
			Name = "PincerA",
			Parent = model,
			Size = Vector3.new(0.4, 0.28, 0.85),
			Color = def.accent,
			Material = Enum.Material.Neon,
			CFrame = claw.CFrame * CFrame.new(side * 0.35, 0.12, -0.55),
		})
		tipA.Anchored = false
		tipA.CanCollide = false
		tipA.Massless = true
		weld(claw, tipA, "PincerWeldA")

		local tipB = part({
			Name = "PincerB",
			Parent = model,
			Size = Vector3.new(0.35, 0.22, 0.7),
			Color = def.accent:Lerp(Color3.fromRGB(255, 255, 200), 0.3),
			Material = Enum.Material.Neon,
			CFrame = claw.CFrame * CFrame.new(side * -0.15, -0.1, -0.5),
		})
		tipB.Anchored = false
		tipB.CanCollide = false
		tipB.Massless = true
		weld(claw, tipB, "PincerWeldB")
	end

	-- Phase 1 hero: Crab King crown + bigger claws silhouette
	if def.id == "CrabKingBoss" or def.isMiniboss then
		local crown = part({
			Name = "TideCrown",
			Parent = model,
			Size = Vector3.new(s.X * 0.55, 0.55, s.Z * 0.45),
			Color = Color3.fromRGB(255, 210, 60),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, s.Y * 0.72, 0),
		})
		attachToRoot(root, crown)
		for _, sx in { -0.35, 0, 0.35 } do
			local spike = part({
				Name = "CrownSpike",
				Parent = model,
				Size = Vector3.new(0.42, 1.1, 0.42),
				Color = Color3.fromRGB(255, 230, 120),
				Material = Enum.Material.Neon,
				CFrame = crown.CFrame * CFrame.new(sx * s.X * 0.35, 0.65, 0),
			})
			addSpecialMesh(spike, Enum.MeshType.Wedge, Vector3.new(1, 1.4, 1))
			attachToRoot(root, spike)
		end
		local sandAtt = Instance.new("Attachment")
		sandAtt.Name = "KingSand"
		sandAtt.Parent = crown
		local sandPe = Instance.new("ParticleEmitter")
		sandPe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 210, 80)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 140, 40)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 180, 120)),
		})
		sandPe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		sandPe.Lifetime = NumberRange.new(0.4, 0.7)
		sandPe.Rate = 4
		sandPe.Speed = NumberRange.new(0.5, 1.5)
		sandPe.LightEmission = 0.4
		sandPe.Parent = sandAtt
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.4
		pl.Range = 14
		pl.Color = Color3.fromRGB(255, 160, 60)
		pl.Parent = crown
	end

	local dust = Instance.new("Attachment")
	dust.Name = "WalkDust"
	dust.Position = Vector3.new(0, -s.Y * 0.3, 0)
	dust.Parent = root
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "SandDust"
	pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 190, 130))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.2) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.4, 0.8)
	pe.Rate = 0
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.Parent = dust
end

local function buildGator(model: Model, root: Part, def: any)
	local s = def.size
	root.Size = Vector3.new(s.X * 0.7, s.Y * 0.55, s.Z * 0.7)
	root.Color = def.color
	if def.id == "OilGator" or def.id == "DriveThruGator" then
		root.Material = Enum.Material.Mud
	else
		root.Material = Enum.Material.SmoothPlastic
	end
	local snout = part({
		Name = "Snout",
		Parent = model,
		Size = Vector3.new(s.X * 0.45, s.Y * 0.35, s.Z * 0.5),
		Color = def.color:Lerp(Color3.fromRGB(60, 100, 50), 0.2),
		Material = Enum.Material.Mud,
		CFrame = root.CFrame * CFrame.new(s.X * 0.45, 0, 0),
	})
	addSpecialMesh(snout, Enum.MeshType.Brick, Vector3.new(1.1, 0.9, 1))
	attachToRoot(root, snout)
	for _, side in { -1, 1 } do
		local eye = part({
			Name = "GatorEye",
			Parent = model,
			Size = Vector3.new(0.45, 0.45, 0.35),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 230, 80),
			Material = Enum.Material.Glass,
			CFrame = root.CFrame * CFrame.new(s.X * 0.35, s.Y * 0.25, side * s.Z * 0.28),
		})
		attachToRoot(root, eye)
	end
	local teeth = part({
		Name = "Teeth",
		Parent = model,
		Size = Vector3.new(s.X * 0.35, 0.25, s.Z * 0.35),
		Color = Color3.fromRGB(240, 240, 230),
		Material = Enum.Material.Neon,
		CFrame = snout.CFrame * CFrame.new(s.X * 0.15, -s.Y * 0.12, 0),
	})
	attachToRoot(root, teeth)
	local tail = part({
		Name = "Tail",
		Parent = model,
		Size = Vector3.new(s.X * 0.5, s.Y * 0.25, s.Z * 0.35),
		Color = def.color,
		CFrame = root.CFrame * CFrame.new(-s.X * 0.5, -0.1, 0),
	})
	local mTail = Instance.new("Motor6D")
	mTail.Name = "TailMotor"
	mTail.Part0 = root
	mTail.Part1 = tail
	mTail.C0 = CFrame.new(-s.X * 0.35, -0.1, 0)
	mTail.Parent = root
	for i = 1, 4 do
		local side = if i % 2 == 0 then 1 else -1
		local leg = part({
			Name = "Leg",
			Parent = model,
			Size = Vector3.new(0.5, 1.2, 0.5),
			Color = def.accent,
			CFrame = root.CFrame * CFrame.new((i - 2.5) * 0.8, -s.Y * 0.35, side * s.Z * 0.4),
		})
		attachToRoot(root, leg)
	end
	if def.id == "OilGator" or def.id == "DriveThruGator" then
		local collar = part({
			Name = "RadioCollar",
			Parent = model,
			Size = Vector3.new(1.35, 0.45, 1.35),
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.new(-s.X * 0.1, s.Y * 0.35, 0),
		})
		attachToRoot(root, collar)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(90, 18)
		bb.StudsOffset = Vector3.new(0, 2.5, 0)
		bb.Parent = collar
		local t = Instance.new("TextLabel")
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Text = "GULFGULP"
		t.TextColor3 = Color3.fromRGB(255, 220, 80)
		t.TextScaled = true
		t.Font = Enum.Font.GothamBold
		t.Parent = bb
		local sheen = part({
			Name = "OilSheen",
			Parent = model,
			Size = Vector3.new(s.X * 0.75, s.Y * 0.15, s.Z * 0.75),
			Color = Color3.fromRGB(40, 60, 30),
			Material = Enum.Material.ForceField,
			Transparency = 0.35,
			CFrame = root.CFrame * CFrame.new(0, s.Y * 0.2, 0),
		})
		attachToRoot(root, sheen)
		local drip = Instance.new("Attachment")
		drip.Name = "GatorOilDrip"
		drip.Parent = root
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(30, 40, 20), Color3.fromRGB(10, 15, 8))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.5, 0.9)
		pe.Rate = 6
		pe.Speed = NumberRange.new(0.5, 1.5)
		pe.Parent = drip
	end
end

local function buildLizard(model: Model, root: Part, def: any)
	local s = def.size
	root.Size = Vector3.new(s.X * 0.6, s.Y * 0.5, s.Z * 0.55)
	root.Color = def.color
	local head = part({
		Name = "Head",
		Parent = model,
		Size = Vector3.new(1.2, 1.0, 1.4),
		Shape = Enum.PartType.Ball,
		Color = def.color,
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.2, -s.Z * 0.35),
	})
	attachToRoot(root, head)
	local crest = part({
		Name = "FlameCrest",
		Parent = model,
		Size = Vector3.new(0.5, 1.8, 1.6),
		Color = Color3.fromRGB(255, 140, 20),
		Material = Enum.Material.Neon,
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.55, 0),
	})
	attachToRoot(root, crest)
	local flame = Instance.new("Attachment")
	flame.Name = "FlameAttach"
	flame.Parent = crest
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "FlameVFX"
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 220, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 20)),
	})
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.3, 0.6)
	pe.Rate = 12
	pe.Speed = NumberRange.new(2, 5)
	pe.LightEmission = 0.6
	pe.Parent = flame
	for i = 1, 4 do
		local leg = part({
			Name = "Leg",
			Parent = model,
			Size = Vector3.new(0.35, 0.9, 0.35),
			Color = def.accent,
			CFrame = root.CFrame * CFrame.new((i - 2.5) * 0.7, -s.Y * 0.3, (if i % 2 == 0 then 1 else -1) * 0.6),
		})
		attachToRoot(root, leg)
	end
end

local function buildSnake(model: Model, root: Part, def: any)
	local s = def.size
	root.Size = Vector3.new(s.X * 0.35, s.Y, s.Z)
	root.Color = def.color
	root.Shape = Enum.PartType.Cylinder
	for i = 1, 3 do
		local seg = part({
			Name = "Seg" .. i,
			Parent = model,
			Size = Vector3.new(s.X * 0.28, s.Y * 0.9, s.Z * 0.9),
			Color = if i % 2 == 0 then def.accent else def.color,
			CFrame = root.CFrame * CFrame.new(-i * s.X * 0.3, 0, 0),
		})
		local m = Instance.new("Motor6D")
		m.Name = "SegMotor"
		m.Part0 = if i == 1 then root else model:FindFirstChild("Seg" .. (i - 1)) :: BasePart
		m.Part1 = seg
		m.C0 = CFrame.new(-s.X * 0.28, 0, 0)
		m.Parent = m.Part0
	end
	local head = part({
		Name = "Head",
		Parent = model,
		Size = Vector3.new(1.1, 0.9, 1.1),
		Color = def.accent,
		CFrame = root.CFrame * CFrame.new(s.X * 0.25, 0.1, 0),
	})
	attachToRoot(root, head)
end

local function buildSlime(model: Model, root: Part, def: any)
	-- Phase 1 hero: layered blob + drip + eyes for readable slushie silhouette
	root.Shape = Enum.PartType.Ball
	root.Size = def.size * 0.85
	root.Color = def.color
	root.Material = Enum.Material.ForceField
	local core = part({
		Name = "Core",
		Parent = model,
		Size = def.size * 0.4,
		Shape = Enum.PartType.Ball,
		Color = def.accent,
		Material = Enum.Material.Neon,
		CFrame = root.CFrame,
	})
	attachToRoot(root, core)
	local blob = part({
		Name = "BlobHalo",
		Parent = model,
		Size = def.size * 1.05,
		Shape = Enum.PartType.Ball,
		Color = def.color:Lerp(Color3.fromRGB(255, 255, 255), 0.15),
		Material = Enum.Material.ForceField,
		Transparency = 0.35,
		CFrame = root.CFrame,
	})
	attachToRoot(root, blob)
	for _, side in { -1, 1 } do
		local eye = part({
			Name = "SlushEye",
			Parent = model,
			Size = Vector3.new(0.55, 0.7, 0.35),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(20, 20, 30),
			CFrame = root.CFrame * CFrame.new(side * def.size.X * 0.18, def.size.Y * 0.12, -def.size.Z * 0.28),
		})
		attachToRoot(root, eye)
	end
	local drip = part({
		Name = "Drip",
		Parent = model,
		Size = Vector3.new(def.size.X * 0.35, def.size.Y * 0.45, def.size.Z * 0.35),
		Shape = Enum.PartType.Ball,
		Color = def.color,
		Material = Enum.Material.Neon,
		CFrame = root.CFrame * CFrame.new(0, -def.size.Y * 0.4, 0),
	})
	attachToRoot(root, drip)
	if def.id == "SlushieKing" or def.isMiniboss then
		local cup = part({
			Name = "SlushCrown",
			Parent = model,
			Size = Vector3.new(def.size.X * 0.5, 0.4, def.size.Z * 0.5),
			Color = Color3.fromRGB(80, 255, 255),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.45, 0),
		})
		attachToRoot(root, cup)
	end
	local att = Instance.new("Attachment")
	att.Name = "SlushSpray"
	att.Parent = root
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "StickyMist"
	pe.Color = ColorSequence.new(def.color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.8) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.4, 0.7)
	pe.Rate = 6
	pe.Speed = NumberRange.new(0.5, 1.5)
	pe.Parent = att
end

local function buildHumanoidish(model: Model, root: Part, def: any)
	local s = def.size
	root.Size = Vector3.new(s.X * 0.7, s.Y * 0.45, s.Z * 0.6)
	root.Color = def.color
	-- Hazmat suit for corp grunts
	if def.id == "GulfGulpGrunt" then
		root.Material = Enum.Material.SmoothPlastic
		root.Color = Color3.fromRGB(60, 70, 50)
	end
	local head = part({
		Name = "Head",
		Parent = model,
		Size = Vector3.new(1.4, 1.4, 1.4),
		Shape = Enum.PartType.Ball,
		Color = def.color:Lerp(Color3.fromRGB(255, 220, 180), 0.3),
		CFrame = root.CFrame * CFrame.new(0, s.Y * 0.4, 0),
	})
	attachToRoot(root, head)
	local accent = part({
		Name = "Accent",
		Parent = model,
		Size = Vector3.new(1.2, 0.4, 1.2),
		Color = def.accent,
		Material = Enum.Material.Neon,
		CFrame = head.CFrame * CFrame.new(0, 0.8, 0),
	})
	attachToRoot(root, accent)
	-- Phase 1 hero: Lost Tourist — visor, camera, fanny pack, flip-flops silhouette
	if def.id == "AngryTourist" then
		local visor = part({
			Name = "TouristVisor",
			Parent = model,
			Size = Vector3.new(1.7, 0.25, 1.7),
			Color = Color3.fromRGB(255, 80, 80),
			Material = Enum.Material.SmoothPlastic,
			CFrame = head.CFrame * CFrame.new(0, 0.55, 0),
		})
		attachToRoot(root, visor)
		local cam = part({
			Name = "TouristCamera",
			Parent = model,
			Size = Vector3.new(0.7, 0.55, 0.9),
			Color = Color3.fromRGB(40, 40, 50),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.new(1.1, 0.3, -0.4),
		})
		attachToRoot(root, cam)
		local lens = part({
			Name = "Lens",
			Parent = model,
			Size = Vector3.new(0.35, 0.35, 0.35),
			Shape = Enum.PartType.Cylinder,
			Color = Color3.fromRGB(80, 180, 255),
			Material = Enum.Material.Neon,
			CFrame = cam.CFrame * CFrame.new(0, 0, -0.5) * CFrame.Angles(0, math.rad(90), 0),
		})
		attachToRoot(root, lens)
		local pack = part({
			Name = "FannyPack",
			Parent = model,
			Size = Vector3.new(1.6, 0.55, 0.7),
			Color = def.accent,
			Material = Enum.Material.SmoothPlastic,
			CFrame = root.CFrame * CFrame.new(0, -s.Y * 0.15, 0.55),
		})
		attachToRoot(root, pack)
		local shirt = part({
			Name = "IHeartFL",
			Parent = model,
			Size = Vector3.new(s.X * 0.75, s.Y * 0.35, 0.2),
			Color = Color3.fromRGB(255, 255, 255),
			CFrame = root.CFrame * CFrame.new(0, 0.1, -s.Z * 0.35),
		})
		attachToRoot(root, shirt)
	end
	-- Selfie stick for influencer
	if def.id == "SelfieZombie" then
		local stick = part({
			Name = "SelfieStick",
			Parent = model,
			Size = Vector3.new(0.2, 3.5, 0.2),
			Color = Color3.fromRGB(40, 40, 50),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.new(1.2, 1.5, -0.5),
		})
		attachToRoot(root, stick)
		local phone = part({
			Name = "Phone",
			Parent = model,
			Size = Vector3.new(0.8, 1.2, 0.15),
			Color = Color3.fromRGB(20, 20, 30),
			Material = Enum.Material.SmoothPlastic,
			CFrame = stick.CFrame * CFrame.new(0, 1.9, 0),
		})
		attachToRoot(root, phone)
		local flash = part({
			Name = "Flash",
			Parent = model,
			Size = Vector3.new(0.5, 0.5, 0.5),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(255, 255, 220),
			Material = Enum.Material.Neon,
			CFrame = phone.CFrame * CFrame.new(0, 0, -0.3),
		})
		attachToRoot(root, flash)
	end
	-- HOA binder for Karen
	if def.id == "CondoKaren" then
		local binder = part({
			Name = "HOABinder",
			Parent = model,
			Size = Vector3.new(1.5, 2.0, 0.35),
			Color = Color3.fromRGB(200, 40, 80),
			CFrame = root.CFrame * CFrame.new(1.2, 0.4, 0),
		})
		attachToRoot(root, binder)
		local paper = part({
			Name = "Citation",
			Parent = model,
			Size = Vector3.new(1.1, 1.4, 0.1),
			Color = Color3.fromRGB(245, 240, 220),
			CFrame = binder.CFrame * CFrame.new(0, 0, -0.25),
		})
		attachToRoot(root, paper)
		local bob = part({
			Name = "BobHair",
			Parent = model,
			Size = Vector3.new(1.8, 0.8, 1.8),
			Color = Color3.fromRGB(40, 30, 25),
			CFrame = head.CFrame * CFrame.new(0, 0.6, 0),
		})
		attachToRoot(root, bob)
	end
	-- Hazmat tank for grunt
	if def.id == "GulfGulpGrunt" then
		local tank = part({
			Name = "AirTank",
			Parent = model,
			Size = Vector3.new(1.2, 2.2, 1.0),
			Color = Color3.fromRGB(255, 180, 0),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.new(0, 0.2, 0.9),
		})
		attachToRoot(root, tank)
		local tape = part({
			Name = "CautionTape",
			Parent = model,
			Size = Vector3.new(2.4, 0.3, 0.3),
			Color = Color3.fromRGB(255, 200, 40),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, 0.8, 0),
		})
		attachToRoot(root, tape)
	end
	for _, side in { -1, 1 } do
		local arm = part({
			Name = "Arm",
			Parent = model,
			Size = Vector3.new(0.55, 2.2, 0.55),
			Color = def.color,
			CFrame = root.CFrame * CFrame.new(side * s.X * 0.55, 0, 0),
		})
		local m = Instance.new("Motor6D")
		m.Name = "ArmMotor"
		m.Part0 = root
		m.Part1 = arm
		m.C0 = CFrame.new(side * s.X * 0.4, 0.2, 0)
		m.Parent = root
		local leg = part({
			Name = "Leg",
			Parent = model,
			Size = Vector3.new(0.6, 2.4, 0.6),
			Color = def.accent,
			CFrame = root.CFrame * CFrame.new(side * 0.4, -s.Y * 0.35, 0),
		})
		attachToRoot(root, leg)
	end
end

local function buildBoss(model: Model, root: Part, def: any)
	buildHumanoidish(model, root, def)
	root.Size = def.size * Vector3.new(0.5, 0.4, 0.5)
	root.Material = Enum.Material.Metal
	root.Color = def.color
	local crown = part({
		Name = "Crown",
		Parent = model,
		Size = Vector3.new(def.size.X * 0.5, 2, 2),
		Color = Color3.fromRGB(255, 180, 0),
		Material = Enum.Material.Neon,
		CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.45, 0),
	})
	attachToRoot(root, crown)
	local armor = part({
		Name = "ArmorPlate",
		Parent = model,
		Size = Vector3.new(2.5, 2.5, 1.2),
		Color = def.color:Lerp(def.accent,0.15),
		Material = Enum.Material.Metal,
		CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.1, -def.size.Z * 0.25),
	})
	attachToRoot(root, armor)
	-- Spillfather sludge mech extras
	if def.id == "Spillfather" then
		local chassis = part({
			Name = "SludgeChassis",
			Parent = model,
			Size = Vector3.new(def.size.X * 0.7, def.size.Y * 0.35, def.size.Z * 0.6),
			Color = Color3.fromRGB(30, 40, 35),
			Material = Enum.Material.Mud,
			CFrame = root.CFrame * CFrame.new(0, -def.size.Y * 0.15, 0),
		})
		attachToRoot(root, chassis)
		local suit = part({
			Name = "ExecSuit",
			Parent = model,
			Size = Vector3.new(3, 4, 2),
			Color = Color3.fromRGB(25, 25, 35),
			Material = Enum.Material.Metal,
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.15, 0),
		})
		attachToRoot(root, suit)
		local tie = part({
			Name = "OilTie",
			Parent = model,
			Size = Vector3.new(0.5, 2, 0.2),
			Color = Color3.fromRGB(255, 140, 0),
			Material = Enum.Material.Neon,
			CFrame = suit.CFrame * CFrame.new(0, 0, -1.1),
		})
		addSpecialMesh(tie, Enum.MeshType.Wedge, Vector3.new(1, 1.2, 0.6))
		attachToRoot(root, tie)
		local visor = part({
			Name = "HazmatVisor",
			Parent = model,
			Size = Vector3.new(2.2, 1.0, 0.4),
			Color = Color3.fromRGB(80, 255, 180),
			Material = Enum.Material.Glass,
			Transparency = 0.25,
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.38, -def.size.Z * 0.2),
		})
		attachToRoot(root, visor)
		for _, side in { -1, 1 } do
			local claw = part({
				Name = "MechClaw",
				Parent = model,
				Size = Vector3.new(2.5, 1.5, 4),
				Color = Color3.fromRGB(255, 160, 40),
				Material = Enum.Material.Metal,
				CFrame = root.CFrame * CFrame.new(side * def.size.X * 0.4, 0, -2),
			})
			addSpecialMesh(claw, Enum.MeshType.Brick, Vector3.new(1, 0.85, 1.15))
			attachToRoot(root, claw)
		end
		local drip = Instance.new("Attachment")
		drip.Name = "OilDrip"
		drip.Parent = chassis
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 50, 25)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(20, 30, 15)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 15, 8)),
		})
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.6, 1.0)
		pe.Rate = 12
		pe.Speed = NumberRange.new(1, 3)
		pe.LightEmission = 0.05
		pe.Parent = drip
	end
end

local function buildTurtle(model: Model, root: Part, def: any)
	root.Size = Vector3.new(def.size.X, def.size.Y * 0.7, def.size.Z)
	root.Color = def.color
	root.Shape = Enum.PartType.Ball
	local shell = part({
		Name = "Shell",
		Parent = model,
		Size = Vector3.new(def.size.X * 1.2, def.size.Y, def.size.Z * 1.1),
		Color = def.accent,
		CFrame = root.CFrame * CFrame.new(0, 0.3, 0),
	})
	attachToRoot(root, shell)
	local head = part({
		Name = "Head",
		Parent = model,
		Size = Vector3.new(0.8, 0.7, 1.0),
		Color = def.color,
		CFrame = root.CFrame * CFrame.new(0, 0.2, -def.size.Z * 0.55),
	})
	attachToRoot(root, head)
end

local function buildGeneric(model: Model, root: Part, def: any)
	root.Size = def.size
	root.Color = def.color
	local shape = def.shape or "hopper"
	if shape == "drone" or def.id == "DroneSpotter" then
		root.Size = Vector3.new(def.size.X, def.size.Y * 0.6, def.size.Z)
		root.Material = Enum.Material.Metal
		root.Color = Color3.fromRGB(50, 60, 80)
		local rotor = part({
			Name = "Rotor",
			Parent = model,
			Size = Vector3.new(def.size.X * 1.4, 0.2, 0.4),
			Color = def.accent,
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.45, 0),
		})
		attachToRoot(root, rotor)
		local lens = part({
			Name = "MarkLens",
			Parent = model,
			Size = Vector3.new(0.8, 0.8, 0.8),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(100, 255, 180),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, -0.2, -def.size.Z * 0.4),
		})
		attachToRoot(root, lens)
		return
	end
	if shape == "pelican" then
		root.Size = Vector3.new(def.size.X * 0.7, def.size.Y * 0.7, def.size.Z * 0.7)
		root.Color = Color3.fromRGB(240, 240, 230)
		local beak = part({
			Name = "Beak",
			Parent = model,
			Size = Vector3.new(2.4, 0.6, 0.7),
			Color = Color3.fromRGB(255, 160, 40),
			CFrame = root.CFrame * CFrame.new(0, 0.2, -def.size.Z * 0.55),
		})
		attachToRoot(root, beak)
		local wing = part({
			Name = "Wing",
			Parent = model,
			Size = Vector3.new(0.4, 1.5, 3.5),
			Color = Color3.fromRGB(220, 220, 210),
			CFrame = root.CFrame * CFrame.new(def.size.X * 0.4, 0.2, 0),
		})
		attachToRoot(root, wing)
		return
	end
	if shape == "cart" then
		-- Phase 1 hero: runaway hotdog cart — canopy, mustard stripe, umbrella, 4 wheels
		root.Material = Enum.Material.Metal
		root.Color = def.color
		for _, ox in { -0.32, 0.32 } do
			for _, oz in { -0.55, 0.55 } do
				local wheel = part({
					Name = "Wheel",
					Parent = model,
					Size = Vector3.new(1.15, 1.15, 0.4),
					Shape = Enum.PartType.Cylinder,
					Color = Color3.fromRGB(30, 30, 35),
					CFrame = root.CFrame * CFrame.new(ox * def.size.X, -def.size.Y * 0.38, oz * def.size.Z * 0.35) * CFrame.Angles(0, 0, math.rad(90)),
				})
				attachToRoot(root, wheel)
			end
		end
		local canopy = part({
			Name = "Canopy",
			Parent = model,
			Size = Vector3.new(def.size.X * 1.05, 0.25, def.size.Z * 1.15),
			Color = Color3.fromRGB(255, 240, 220),
			Material = Enum.Material.SmoothPlastic,
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.55, 0),
		})
		attachToRoot(root, canopy)
		local stripe = part({
			Name = "MustardStripe",
			Parent = model,
			Size = Vector3.new(def.size.X * 0.9, 0.35, def.size.Z * 0.2),
			Color = def.accent,
			Material = Enum.Material.Neon,
			CFrame = root.CFrame * CFrame.new(0, 0.1, -def.size.Z * 0.35),
		})
		attachToRoot(root, stripe)
		local umbrella = part({
			Name = "UmbrellaPole",
			Parent = model,
			Size = Vector3.new(0.2, 2.2, 0.2),
			Color = Color3.fromRGB(80, 40, 40),
			CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.85, 0),
		})
		attachToRoot(root, umbrella)
		local shade = part({
			Name = "Umbrella",
			Parent = model,
			Size = Vector3.new(2.4, 0.35, 2.4),
			Shape = Enum.PartType.Ball,
			Color = Color3.fromRGB(220, 40, 50),
			Material = Enum.Material.SmoothPlastic,
			CFrame = umbrella.CFrame * CFrame.new(0, 1.1, 0),
		})
		attachToRoot(root, shade)
		local dog = part({
			Name = "HotdogProp",
			Parent = model,
			Size = Vector3.new(1.8, 0.45, 0.45),
			Color = Color3.fromRGB(180, 90, 50),
			Material = Enum.Material.SmoothPlastic,
			CFrame = canopy.CFrame * CFrame.new(0, 0.4, 0),
		})
		attachToRoot(root, dog)
		local pl = Instance.new("PointLight")
		pl.Brightness = 0.8
		pl.Range = 10
		pl.Color = def.accent
		pl.Parent = stripe
		return
	end
	if shape == "barrel" then
		root.Shape = Enum.PartType.Cylinder
		root.Size = Vector3.new(def.size.Y, def.size.X, def.size.Z)
		root.Material = Enum.Material.Metal
		local stripe = part({
			Name = "HazardStripe",
			Parent = model,
			Size = Vector3.new(def.size.Y * 0.3, def.size.X * 1.05, def.size.Z * 1.05),
			Color = Color3.fromRGB(255, 180, 0),
			Material = Enum.Material.Neon,
			CFrame = root.CFrame,
		})
		attachToRoot(root, stripe)
		return
	end
	local accent = part({
		Name = "Accent",
		Parent = model,
		Size = Vector3.new(1.2, 1.2, 1.2),
		Color = def.accent,
		Material = Enum.Material.Neon,
		CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.4, 0),
	})
	attachToRoot(root, accent)
end

local SHAPERS: { [string]: (Model, Part, any) -> () } = {
	crab = buildCrab,
	gator = buildGator,
	lizard = buildLizard,
	snake = buildSnake,
	slime = buildSlime,
	humanoid = buildHumanoidish,
	boss = buildBoss,
	turtle = buildTurtle,
	hopper = buildGeneric,
	cart = buildGeneric,
	drone = buildGeneric,
	pelican = buildGeneric,
	barrel = buildGeneric,
	cloud = buildSlime,
}

local function applyEnemyAttrs(model: Model, root: BasePart, def: any)
	model:SetAttribute("EnemyId", def.id)
	model:SetAttribute("IsAlly", def.isAlly)
	model:SetAttribute("IsBoss", def.isBoss)
	model:SetAttribute("IsMiniboss", def.isMiniboss)
	model:SetAttribute("Damage", def.damage)
	model:SetAttribute("Speed", def.speed)
	model:SetAttribute("Telegraph", def.telegraph)
	model:SetAttribute("AttackCooldown", def.attackCooldown)
	model:SetAttribute("Behavior", def.behavior or "chase")
	model:SetAttribute("Facing", 1)
	model:SetAttribute("AnimPhase", 0)
	model:SetAttribute("Shape", def.shape)
	if def.telegraphColor then
		model:SetAttribute("TelegraphColor", def.telegraphColor)
	end
	if not model:FindFirstChild("NamePlate") and not root:FindFirstChild("NamePlate") then
		local bb = Instance.new("BillboardGui")
		bb.Name = "NamePlate"
		bb.Size = UDim2.fromOffset(160, 36)
		bb.StudsOffset = Vector3.new(0, def.size.Y * 0.55 + 2, 0)
		bb.AlwaysOnTop = true
		bb.Parent = root
		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size = UDim2.new(1, 0, 0.55, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Text = def.name
		nameLbl.TextColor3 = if def.isAlly then Color3.fromRGB(120, 255, 180) else Color3.fromRGB(255, 220, 200)
		nameLbl.TextScaled = true
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.Parent = bb
		local hpLbl = Instance.new("TextLabel")
		hpLbl.Name = "HP"
		hpLbl.Size = UDim2.new(1, 0, 0.45, 0)
		hpLbl.Position = UDim2.new(0, 0, 0.55, 0)
		hpLbl.BackgroundTransparency = 1
		hpLbl.Text = if def.isAlly then "Rescue (never harm)" else string.format("%d / %d", def.hp, def.hp)
		hpLbl.TextColor3 = Color3.fromRGB(200, 255, 200)
		hpLbl.TextScaled = true
		hpLbl.Font = Enum.Font.Gotham
		hpLbl.Parent = bb
	end
end

local function tryMeshEnemy(def: any, position: Vector3): Model?
	local clone = ArtAssets.TryCloneMeshModel(def.id)
	if not clone then
		return nil
	end
	clone.Name = def.id
	local root = clone.PrimaryPart or clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root or not root:IsA("BasePart") then
		clone:Destroy()
		return nil
	end
	clone.PrimaryPart = root
	root.Anchored = true
	root.CanCollide = true
	root.CanQuery = true
	root.CanTouch = false
	root:SetAttribute("EnemyHitbox", true)
	root.Size = def.size
	clone:PivotTo(CFrame.new(position))
	for _, child in clone:GetDescendants() do
		if child:IsA("BasePart") and child ~= root then
			child.CanCollide, child.CanQuery, child.CanTouch = false, false, false
		end
	end
	local hum: Humanoid = clone:FindFirstChildOfClass("Humanoid") or Instance.new("Humanoid")
	hum.Parent = clone
	hum.MaxHealth = def.hp
	hum.BreakJointsOnDeath = false
	hum.Health = def.hp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	applyEnemyAttrs(clone, root, def)
	clone:SetAttribute('VisualForwardAxis', '+X') -- validated imported art contract
	clone:SetAttribute('VisualFacing', 1)
	return clone
end

function EnemyFactory.Build(def: any, position: Vector3): Model
	local meshed = tryMeshEnemy(def, position)
	if meshed then
		return meshed
	end

	local model = Instance.new("Model")
	tagArtKit(model)
	model.Name = def.id

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = def.size
	root.Color = def.color
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true -- AI PivotTo; whole welded assembly moves together
	root.CanCollide = true
	root.CanQuery = true
	root:SetAttribute("EnemyHitbox", true)
	root.CFrame = CFrame.new(position)
	root.Parent = model

	local shaper = SHAPERS[def.shape]
	if shaper then shaper(model, root, def) else buildGeneric(model, root, def) end

	-- Safety net: every BasePart must be in the assembly.
	-- CRITICAL: never WeldConstraint a part that is already Motor6D-driven — welds freeze animation.
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") and d ~= root then
			d.Anchored = false
			d.CanCollide = false
			d.Massless = true
			if not isMotorConnected(model, d) then
				weld(root, d, "SafetyWeld")
			end
		end
	end

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = def.hp
	hum.BreakJointsOnDeath = false
	hum.Health = def.hp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = root
	applyEnemyAttrs(model, root, def)
	local forwardAxis = MovementRules.ForwardAxis(def.shape)
	model:SetAttribute('VisualForwardAxis', forwardAxis)
	model:SetAttribute('VisualFacing', 1)
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, MovementRules.FacingYaw(1, forwardAxis), 0))

	return model
end

function EnemyFactory.Animate(model: Model, dt: number, moving: boolean, attacking: boolean)
	local phase = (model:GetAttribute("AnimPhase") :: number?) or 0
	phase += dt * (if moving then 10 else 2)
	model:SetAttribute("AnimPhase", phase)
	local shape = model:GetAttribute("Shape")

	if shape == "crab" then
		for _, d in rigParts(model) do
			if d:IsA("Motor6D") and d.Name == "RootHipMotor" then
				local hip = d.Part1
				local idx = if hip then (hip:GetAttribute("LegIndex") :: number?) or 0 else 0
				local side = if hip then (hip:GetAttribute("LegSide") :: number?) or 1 else 1
				-- Alternating tripod gait
				local offset = idx * 1.05
				local sway = if moving then math.sin(phase + offset) * 0.22 else math.sin(phase * 0.25 + offset) * 0.04
				d.C1 = CFrame.Angles(0, 0, side * sway)
			elseif d:IsA("Motor6D") and d.Name == "HipMotor" then
				local hip = d.Part0
				local idx = if hip then (hip:GetAttribute("LegIndex") :: number?) or 0 else 0
				local offset = idx * 1.05
				local swing = if moving then math.sin(phase + offset) * 0.65 else math.sin(phase * 0.3 + offset) * 0.08
				d.C1 = CFrame.new(0, 0.45, 0) * CFrame.Angles(swing, 0, 0)
			elseif d:IsA("Motor6D") and d.Name == "KneeMotor" then
				local upper = d.Part0
				local idx = 0
				if upper then
					local n = tonumber(string.match(upper.Name, "%d+"))
					idx = n or 0
				end
				local offset = idx * 1.05
				local bend = if moving then 0.25 + math.sin(phase * 1.15 + offset) * 0.45 else 0.12
				d.C1 = CFrame.new(0, 0.4, 0) * CFrame.Angles(-math.abs(bend), 0, 0)
			elseif d:IsA("Motor6D") and d.Name == "ClawMotor" then
				-- Raise + lunge on attack telegraph
				local snap = if attacking then math.sin(phase * 9) * 0.55 else math.sin(phase * 0.5) * 0.1
				local raise = if attacking then -0.45 else -0.08
				d.C1 = CFrame.new(0, 0, 0.45) * CFrame.Angles(raise, snap, 0)
			elseif d:IsA("Motor6D") and d.Name == "PinchMotor" then
				-- Claw snap open/close
				local pinch = if attacking then 0.15 + math.abs(math.sin(phase * 12)) * 0.7 else 0.2
				d.C1 = CFrame.Angles(0, pinch * 0.35, pinch)
			end
		end
		local dust = model.PrimaryPart and model.PrimaryPart:FindFirstChild("WalkDust")
		if dust then
			local pe = dust:FindFirstChild("SandDust") :: ParticleEmitter?
			if pe then
				pe.Rate = if moving then 18 else 0
			end
		end
	elseif shape == "gator" or shape == "lizard" then
		for _, d in rigParts(model) do
			if d:IsA("Motor6D") and d.Name == "TailMotor" then
				d.C1 = CFrame.Angles(0, math.sin(phase) * 0.35, 0)
			end
		end
	elseif shape == "snake" then
		for _, d in rigParts(model) do
			if d:IsA("Motor6D") and d.Name == "SegMotor" and d.Part1 then
				d.C1 = CFrame.Angles(0, math.sin(phase + d.Part1.Name:len()) * 0.25, 0)
			end
		end
	elseif shape == "humanoid" or shape == "boss" then
		for _, d in rigParts(model) do
			if d:IsA("Motor6D") and d.Name == "ArmMotor" then
				local swing = if moving then math.sin(phase) * 0.6 else math.sin(phase * 0.4) * 0.1
				if attacking then
					swing = math.sin(phase * 6) * 0.9
				end
				d.C1 = CFrame.Angles(swing, 0, 0)
			end
		end
	elseif shape == "slime" then
		local root = model.PrimaryPart
		if root and moving then
			local squash = 1 + math.sin(phase * 2) * 0.08
			-- visual only via attribute; avoid fighting PivotTo size
			root:SetAttribute("Squash", squash)
		end
	end
end

function EnemyFactory.HitFlash(model: Model)
	local revision = ((model:GetAttribute("HitFlashRevision") :: number?) or 0) + 1
	model:SetAttribute("HitFlashRevision", revision)
	for _, child in rigParts(model) do
		if child:IsA("BasePart") then
			if typeof(child:GetAttribute("BaseColor")) ~= "Color3" then child:SetAttribute("BaseColor", child.Color) end
			child.Color = Color3.new(1, 1, 1)
		end
	end
	task.delay(0.07, function()
		if not model.Parent or model:GetAttribute("HitFlashRevision") ~= revision then return end
		for _, child in rigParts(model) do
			if child:IsA("BasePart") then
				local color = child:GetAttribute("BaseColor")
				if typeof(color) == "Color3" then child.Color = color end
			end
		end
	end)
end

function EnemyFactory.DeathPoof(pos: Vector3, color: Color3)
	local puff = Instance.new("Part")
	puff.Shape = Enum.PartType.Ball
	puff.Size = Vector3.new(1.5, 1.5, 1.5)
	puff.Color = color
	puff.Material = Enum.Material.Neon
	puff.Anchored = true
	puff.CanCollide = false
	puff.CanQuery, puff.CanTouch = false, false
	puff.CFrame = CFrame.new(pos)
	puff.Parent = workspace
	local att = Instance.new("Attachment")
	att.Parent = puff
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.35, 0.6)
	pe.Speed = NumberRange.new(6, 14)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Rate = 0
	pe.LightEmission = 0.6
	pe.Parent = att
	pe:Emit(28)
	local ring = Instance.new("Part")
	ring.Anchored = true
	ring.CanCollide = false
	ring.CanQuery, ring.CanTouch = false, false
	ring.Material = Enum.Material.ForceField
	ring.Color = color
	ring.Size = Vector3.new(0.3, 2, 2)
	ring.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	ring.Transparency = 0.25
	ring.Parent = workspace
	TweenService:Create(ring, TweenInfo.new(0.35), { Size = Vector3.new(0.3, 9, 9), Transparency = 1 }):Play()
	Debris:AddItem(ring, 0.4)
	TweenService:Create(puff, TweenInfo.new(0.4), { Size = Vector3.new(7, 7, 7), Transparency = 1 }):Play()
	Debris:AddItem(puff, 0.5)
end

return EnemyFactory
