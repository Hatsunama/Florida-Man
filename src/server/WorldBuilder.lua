--!strict
--[[ Builds 2.5D stages with unique set pieces, 3+ parallax layers,
	hazards, mini-arenas, visible goals, and biome lighting profiles.
	No more identical lanes with 4 repeated cubes.
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))
local Stages = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Stages"))
local Story = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Story"))

local WorldBuilder = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide ~= false
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or Color3.new(1, 1, 1)
	p.Size = props.Size or Vector3.new(1, 1, 1)
	p.CFrame = props.CFrame or CFrame.new()
	p.Name = props.Name or "Part"
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = props.CastShadow ~= false
	if props.Transparency then
		p.Transparency = props.Transparency
	end
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	return p
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

local function label(parent: Instance, text: string, color: Color3?, offsetY: number?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(240, 44)
	bb.StudsOffset = Vector3.new(0, offsetY or 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.3
	tl.Font = Enum.Font.GothamBold
	tl.TextScaled = true
	tl.Parent = bb
	return bb
end


local function proximityPrompt(parent: Instance, props: { [string]: any }): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = props.ActionText or "Interact"
	pp.ObjectText = props.ObjectText or ""
	pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.HoldDuration = 0
	pp.ClickablePrompt = true
	pp.RequiresLineOfSight = false
	pp.MaxActivationDistance = props.MaxActivationDistance or 12
	pp.Style = Enum.ProximityPromptStyle.Default
	pp:SetAttribute("FM_Action", props.Action or "")
	pp.Parent = parent
	return pp
end

local function clearEffects()
	for _, name in { "FM_Atmosphere", "FM_CC", "FM_Bloom", "FM_DoF" } do
		local e = Lighting:FindFirstChild(name)
		if e then
			e:Destroy()
		end
	end
end

local LIGHTING_PROFILES = {
	dawnGold = { density = 0.2, sat = 0.18, contrast = 0.06, tint = Color3.fromRGB(255, 235, 200), bloom = 0.4, haze = 1.0, glare = 0.25 },
	midBeach = { density = 0.18, sat = 0.15, contrast = 0.08, tint = Color3.fromRGB(255, 250, 240), bloom = 0.35, haze = 0.9, glare = 0.2 },
	neonGas = { density = 0.25, sat = 0.22, contrast = 0.12, tint = Color3.fromRGB(255, 240, 200), bloom = 0.55, haze = 1.1, glare = 0.15 },
	stripMall = { density = 0.22, sat = 0.05, contrast = 0.1, tint = Color3.fromRGB(245, 245, 250), bloom = 0.3, haze = 1.0, glare = 0.08 },
	lateAfternoon = { density = 0.24, sat = 0.12, contrast = 0.08, tint = Color3.fromRGB(255, 220, 180), bloom = 0.38, haze = 1.3, glare = 0.18 },
	swampGreen = { density = 0.38, sat = 0.12, contrast = 0.06, tint = Color3.fromRGB(220, 255, 220), bloom = 0.28, haze = 2.0, glare = 0.05 },
	greenBlack = { density = 0.42, sat = 0.08, contrast = 0.1, tint = Color3.fromRGB(200, 255, 210), bloom = 0.25, haze = 2.4, glare = 0.04 },
	redTide = { density = 0.3, sat = 0.1, contrast = 0.1, tint = Color3.fromRGB(255, 210, 210), bloom = 0.32, haze = 1.6, glare = 0.1 },
	nightNest = { density = 0.28, sat = -0.02, contrast = 0.12, tint = Color3.fromRGB(200, 220, 255), bloom = 0.4, haze = 1.4, glare = 0.06 },
	clinicalLab = { density = 0.26, sat = -0.08, contrast = 0.14, tint = Color3.fromRGB(230, 245, 255), bloom = 0.3, haze = 1.1, glare = 0.05 },
	industrialOrange = { density = 0.3, sat = 0.05, contrast = 0.12, tint = Color3.fromRGB(255, 230, 200), bloom = 0.4, haze = 1.5, glare = 0.08 },
	offshoreWind = { density = 0.22, sat = 0.08, contrast = 0.08, tint = Color3.fromRGB(230, 240, 255), bloom = 0.35, haze = 1.2, glare = 0.12 },
	finaleRig = { density = 0.32, sat = 0.1, contrast = 0.15, tint = Color3.fromRGB(255, 200, 160), bloom = 0.5, haze = 1.8, glare = 0.1 },
}

function WorldBuilder.ApplyLighting(stage: any)
	clearEffects()
	Lighting.ClockTime = stage.clockTime
	Lighting.FogColor = stage.fogColor
	Lighting.FogStart = 80
	Lighting.FogEnd = 300
	Lighting.OutdoorAmbient = stage.groundColor:Lerp(Color3.new(0.5, 0.5, 0.5), 0.4)
	Lighting.Ambient = stage.fogColor:Lerp(Color3.new(0.3, 0.3, 0.3), 0.5)
	Lighting.Brightness = 2.2

	local prof = LIGHTING_PROFILES[stage.lighting or "dawnGold"] or LIGHTING_PROFILES.dawnGold

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "FM_Atmosphere"
	atmo.Density = prof.density
	atmo.Offset = 0.1
	atmo.Color = stage.fogColor
	atmo.Decay = stage.fogColor:Lerp(Color3.fromRGB(20, 20, 30), 0.5)
	atmo.Glare = prof.glare
	atmo.Haze = prof.haze
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FM_CC"
	cc.Saturation = prof.sat
	cc.Contrast = prof.contrast
	cc.TintColor = if stage.hangover then Color3.fromRGB(255, 235, 210) else prof.tint
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "FM_Bloom"
	bloom.Intensity = prof.bloom
	bloom.Size = 18
	bloom.Threshold = 1.05
	bloom.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "FM_DoF"
	dof.FarIntensity = 0.14
	dof.NearIntensity = 0.04
	dof.FocusDistance = 36
	dof.InFocusRadius = 28
	dof.Parent = Lighting
end

function WorldBuilder.Clear()
	local world = Workspace:FindFirstChild("GameWorld")
	if world then
		world:ClearAllChildren()
	else
		world = Instance.new("Folder")
		world.Name = "GameWorld"
		world.Parent = Workspace
	end
	return world :: Folder
end

function WorldBuilder._Parallax(world: Folder, stage: any, laneZ: number, length: number)
	local folder = Instance.new("Folder")
	folder.Name = "Parallax"
	folder.Parent = world
	local biome = stage.biome
	-- Layer 1 far sky
	local farColor = if biome == "swamp" then stage.fogColor:Lerp(Color3.fromRGB(20, 40, 25), 0.4)
		elseif biome == "facility" or biome == "offshore" then stage.fogColor:Lerp(Color3.fromRGB(15, 15, 25), 0.5)
		else stage.fogColor:Lerp(Color3.fromRGB(255, 190, 130), 0.2)
	part({
		Name = "SkyFar",
		Parent = folder,
		Size = Vector3.new(length + 100, 55, 1),
		CFrame = CFrame.new(length / 2, 24, laneZ - 52),
		Color = farColor,
		CanCollide = false,
		CastShadow = false,
		Transparency = 0.12,
	})
	-- Layer 2 mid silhouettes — unique per biome
	local midFolder = Instance.new("Folder")
	midFolder.Name = "MidSilhouettes"
	midFolder.Parent = folder
	local count = math.floor(length / 36) + 2
	for i = 1, count do
		local x = (i - 1) * 36 + 8 + (i % 3) * 4
		if biome == "beach" or biome == "town" then
			-- palm / shack / billboard variety
			local kind = i % 4
			if kind == 0 then
				part({ Name = "FarPalm", Parent = midFolder, Size = Vector3.new(1.4, 14 + (i % 3) * 2, 1.4),
					CFrame = CFrame.new(x, 8, laneZ - 32), Color = Color3.fromRGB(60, 40, 25), Material = Enum.Material.Wood, CanCollide = false, CastShadow = false, Transparency = 0.2 })
				part({ Name = "FarFrond", Parent = midFolder, Size = Vector3.new(7, 0.8, 7),
					CFrame = CFrame.new(x, 15, laneZ - 32), Color = Color3.fromRGB(30, 100, 45), CanCollide = false, CastShadow = false, Transparency = 0.25 })
			elseif kind == 1 then
				part({ Name = "Shack", Parent = midFolder, Size = Vector3.new(10, 6 + (i % 2) * 2, 2),
					CFrame = CFrame.new(x, 4, laneZ - 30), Color = stage.fogColor:Lerp(Color3.new(0, 0, 0), 0.35), CanCollide = false, CastShadow = false, Transparency = 0.22 })
			elseif kind == 2 then
				part({ Name = "Billboard", Parent = midFolder, Size = Vector3.new(12, 5, 0.6),
					CFrame = CFrame.new(x, 10, laneZ - 30), Color = Color3.fromRGB(30, 50, 90), CanCollide = false, CastShadow = false, Transparency = 0.2 })
			else
				part({ Name = "Dune", Parent = midFolder, Size = Vector3.new(16, 3 + (i % 3), 3),
					CFrame = CFrame.new(x, 2, laneZ - 28), Color = stage.groundColor:Lerp(Color3.new(0, 0, 0), 0.2), CanCollide = false, CastShadow = false, Transparency = 0.3 })
			end
		elseif biome == "swamp" then
			local h = 10 + (i % 5) * 3
			part({ Name = "CypressSil", Parent = midFolder, Size = Vector3.new(2.2 + (i % 2), h, 2.2),
				CFrame = CFrame.new(x, h / 2 + 1, laneZ - 30), Color = Color3.fromRGB(25, 35, 22), Material = Enum.Material.Wood, CanCollide = false, CastShadow = false, Transparency = 0.18 })
			if i % 2 == 0 then
				part({ Name = "KneeRoot", Parent = midFolder, Size = Vector3.new(4, 2, 4),
					CFrame = CFrame.new(x + 3, 1.2, laneZ - 28), Color = Color3.fromRGB(40, 50, 30), CanCollide = false, CastShadow = false, Transparency = 0.3 })
			end
		else
			-- facility / offshore: towers, tanks, cranes
			local kind = i % 3
			if kind == 0 then
				part({ Name = "Tank", Parent = midFolder, Size = Vector3.new(8, 10 + (i % 4) * 2, 8),
					CFrame = CFrame.new(x, 6, laneZ - 32), Color = Color3.fromRGB(40, 45, 55), Material = Enum.Material.Metal, CanCollide = false, CastShadow = false, Transparency = 0.2 })
			elseif kind == 1 then
				part({ Name = "CraneArm", Parent = midFolder, Size = Vector3.new(18, 1.2, 1.2),
					CFrame = CFrame.new(x, 14, laneZ - 30), Color = Color3.fromRGB(255, 160, 40), Material = Enum.Material.Metal, CanCollide = false, CastShadow = false, Transparency = 0.25 })
				part({ Name = "CraneMast", Parent = midFolder, Size = Vector3.new(1.5, 16, 1.5),
					CFrame = CFrame.new(x - 6, 8, laneZ - 30), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal, CanCollide = false, CastShadow = false, Transparency = 0.25 })
			else
				part({ Name = "Stack", Parent = midFolder, Size = Vector3.new(3, 16 + (i % 3) * 3, 3),
					CFrame = CFrame.new(x, 10, laneZ - 31), Color = Color3.fromRGB(50, 50, 60), Material = Enum.Material.Metal, CanCollide = false, CastShadow = false, Transparency = 0.22 })
			end
		end
	end
	-- Layer 3 near backdrop
	part({
		Name = "BackDrop",
		Parent = folder,
		Size = Vector3.new(length + 50, 34, 2),
		CFrame = CFrame.new(length / 2, 15, laneZ - 16),
		Color = stage.fogColor:Lerp(stage.groundColor, 0.15),
		CanCollide = false,
		Transparency = 0.4,
		CastShadow = false,
	})
end

local function makeHazard(world: Folder, kind: string, x: number, laneZ: number, accent: Color3)
	local h = part({
		Name = "Hazard_" .. kind,
		Parent = world,
		Size = Vector3.new(7, 0.3, 5),
		CFrame = CFrame.new(x, 0.2, laneZ),
		CanCollide = false,
		Transparency = 0.35,
	})
	h:SetAttribute("Hazard", kind)
	if kind == "oilSlick" or kind == "sandSlow" or kind == "slushPuddle" then
		h.Color = Color3.fromRGB(25, 30, 25)
		h.Material = Enum.Material.Mud
		h.Size = Vector3.new(9, 0.25, 5)
	elseif kind == "fryerOil" then
		h.Color = Color3.fromRGB(180, 120, 30)
		h.Material = Enum.Material.Glass
		h.Transparency = 0.4
	elseif kind == "fireCone" then
		h.Color = Color3.fromRGB(255, 100, 20)
		h.Material = Enum.Material.Neon
		h.Size = Vector3.new(6, 0.2, 8)
		h.Transparency = 0.5
		local att = Instance.new("Attachment")
		att.Parent = h
		local pe = Instance.new("ParticleEmitter")
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 200, 60), Color3.fromRGB(255, 60, 10))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
		pe.Lifetime = NumberRange.new(0.3, 0.6)
		pe.Rate = 8
		pe.Speed = NumberRange.new(2, 5)
		pe.LightEmission = 0.6
		pe.Parent = att
	elseif kind == "hoaCone" then
		h.Size = Vector3.new(1.4, 2.2, 1.4)
		h.CFrame = CFrame.new(x, 1.2, laneZ + 2)
		h.Color = Color3.fromRGB(255, 120, 20)
		h.Material = Enum.Material.SmoothPlastic
		h.Transparency = 0
		h.CanCollide = false
		label(h, "HOA", Color3.fromRGB(255, 220, 80), 2)
	elseif kind == "redTide" then
		h.Color = Color3.fromRGB(180, 40, 70)
		h.Material = Enum.Material.Mud
		h.Size = Vector3.new(10, 0.3, 6)
		h.Transparency = 0.3
	elseif kind == "canalWater" then
		h.Color = Color3.fromRGB(40, 120, 140)
		h.Material = Enum.Material.Glass
		h.Size = Vector3.new(12, 0.4, 8)
		h.Transparency = 0.45
		h:SetAttribute("JumpPad", true)
	elseif kind == "windPush" then
		h.Color = Color3.fromRGB(180, 220, 255)
		h.Material = Enum.Material.ForceField
		h.Size = Vector3.new(14, 6, 6)
		h.CFrame = CFrame.new(x, 3, laneZ)
		h.Transparency = 0.7
		h:SetAttribute("WindDir", -1)
	end
	return h
end

function WorldBuilder._Platforms(world: Folder, stage: any, laneZ: number, length: number)
	local n = stage.platformLedges or 0
	if n <= 0 then
		return
	end
	for i = 1, n do
		local x = length * (0.3 + 0.25 * i / (n + 1))
		local h = 4 + (i % 2) * 2
		part({
			Name = "Ledge",
			Parent = world,
			Size = Vector3.new(10, 1, 6),
			CFrame = CFrame.new(x, h, laneZ),
			Color = stage.accentColor:Lerp(stage.groundColor, 0.5),
			Material = if stage.biome == "facility" or stage.biome == "offshore" then Enum.Material.Metal else Enum.Material.Wood,
		})
	end
end

function WorldBuilder._SetPiece(world: Folder, stage: any, laneZ: number, length: number)
	local sp = stage.setPiece or ""
	local mid = length * 0.5
	local arenaX = length * 0.78

	if sp == "collapsingPier" then
		for i = 1, 5 do
			local px = length * 0.55 + i * 8
			part({ Name = "PierPlank", Parent = world, Size = Vector3.new(7, 0.6, 5),
				CFrame = CFrame.new(px, 0.8 + (i % 2) * 0.15, laneZ), Color = Color3.fromRGB(120, 90, 50), Material = Enum.Material.Wood })
			part({ Name = "PierPost", Parent = world, Size = Vector3.new(0.8, 4, 0.8),
				CFrame = CFrame.new(px, 2, laneZ - 3), Color = Color3.fromRGB(90, 70, 40), Material = Enum.Material.Wood, CanCollide = false })
		end
		local light = part({ Name = "PierLamp", Parent = world, Size = Vector3.new(1.5, 1.5, 1.5),
			CFrame = CFrame.new(length - 18, 6, laneZ), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.Neon, CanCollide = false, Shape = Enum.PartType.Ball })
		local pl = Instance.new("PointLight")
		pl.Brightness = 2
		pl.Range = 24
		pl.Color = Color3.fromRGB(255, 200, 100)
		pl.Parent = light
	elseif sp == "fryerOil" then
		for i = 1, 3 do
			makeHazard(world, "fryerOil", 40 + i * 45, laneZ, stage.accentColor)
		end
		part({ Name = "Fryer", Parent = world, Size = Vector3.new(4, 3, 3),
			CFrame = CFrame.new(mid, 2, laneZ - 6), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal, CanCollide = false })
		label(part({ Name = "CartSign", Parent = world, Size = Vector3.new(6, 3, 0.4),
			CFrame = CFrame.new(mid + 20, 5, laneZ - 8), Color = Color3.fromRGB(220, 40, 40), CanCollide = false }), "MUSTARD ZONE", Color3.fromRGB(255, 220, 80))
	elseif sp == "neonCanopy" then
		part({ Name = "Canopy", Parent = world, Size = Vector3.new(40, 0.8, 16),
			CFrame = CFrame.new(mid, 9, laneZ), Color = Color3.fromRGB(255, 200, 40), Material = Enum.Material.Neon, CanCollide = false })
		for i = 1, 4 do
			part({ Name = "Pump", Parent = world, Size = Vector3.new(2.2, 5, 2.2),
				CFrame = CFrame.new(mid - 15 + i * 10, 2.5, laneZ - 5), Color = Color3.fromRGB(200, 40, 40), Material = Enum.Material.Metal, CanCollide = false })
		end
		local neon = part({ Name = "OpenSign", Parent = world, Size = Vector3.new(10, 3, 0.5),
			CFrame = CFrame.new(mid, 12, laneZ - 7), Color = Color3.fromRGB(255, 60, 100), Material = Enum.Material.Neon, CanCollide = false })
		label(neon, "OPEN 24HRS", Color3.fromRGB(255, 255, 200))
	elseif sp == "parkingArena" then
		-- mini-arena framing for HOA Hydra
		part({ Name = "ArenaFloor", Parent = world, Size = Vector3.new(36, 0.4, 16),
			CFrame = CFrame.new(arenaX, 0.25, laneZ), Color = Color3.fromRGB(50, 50, 55), Material = Enum.Material.Asphalt })
		for _, side in { -1, 1 } do
			part({ Name = "ArenaPost", Parent = world, Size = Vector3.new(1, 8, 1),
				CFrame = CFrame.new(arenaX + side * 16, 4, laneZ - 6), Color = stage.accentColor, Material = Enum.Material.Neon, CanCollide = false })
		end
		local spot = part({ Name = "Spotlight", Parent = world, Size = Vector3.new(2, 1, 2),
			CFrame = CFrame.new(arenaX, 12, laneZ - 8), Color = Color3.fromRGB(255, 255, 220), Material = Enum.Material.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 3
		pl.Range = 40
		pl.Color = Color3.fromRGB(255, 240, 200)
		pl.Parent = spot
	elseif sp == "driveThruLane" then
		part({ Name = "MenuBoard", Parent = world, Size = Vector3.new(1, 8, 6),
			CFrame = CFrame.new(mid, 4, laneZ - 7), Color = Color3.fromRGB(20, 20, 25), CanCollide = false })
		label(part({ Name = "Speaker", Parent = world, Size = Vector3.new(2, 3, 2),
			CFrame = CFrame.new(mid + 8, 2, laneZ - 4), Color = Color3.fromRGB(70, 70, 80), CanCollide = false }), "ORDER HERE", Color3.fromRGB(255, 200, 80))
		part({ Name = "Window", Parent = world, Size = Vector3.new(4, 4, 1),
			CFrame = CFrame.new(length * 0.72, 3, laneZ - 6), Color = Color3.fromRGB(100, 180, 220), Material = Enum.Material.Glass, CanCollide = false })
		-- arena for gator
		part({ Name = "ArenaFloor", Parent = world, Size = Vector3.new(32, 0.35, 14),
			CFrame = CFrame.new(arenaX, 0.2, laneZ), Color = Color3.fromRGB(70, 80, 55) })
		local spot = part({ Name = "Spotlight", Parent = world, Size = Vector3.new(2, 1, 2),
			CFrame = CFrame.new(arenaX, 11, laneZ - 6), Color = Color3.fromRGB(255, 200, 80), Material = Enum.Material.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 2.5
		pl.Range = 36
		pl.Parent = spot
	elseif sp == "canalPads" then
		for i = 1, 4 do
			local x = 30 + i * 45
			makeHazard(world, "canalWater", x, laneZ, stage.accentColor)
			part({ Name = "JumpPad", Parent = world, Size = Vector3.new(5, 0.6, 5),
				CFrame = CFrame.new(x + 8, 0.4, laneZ), Color = Color3.fromRGB(80, 220, 180), Material = Enum.Material.Neon })
				:SetAttribute("JumpPad", true)
		end
	elseif sp == "cypressCanopy" then
		for i = 1, 6 do
			local x = 25 + i * 35
			part({ Name = "Cypress", Parent = world, Size = Vector3.new(3, 18, 3),
				CFrame = CFrame.new(x, 9, laneZ - 8), Color = Color3.fromRGB(45, 35, 22), Material = Enum.Material.Wood, CanCollide = false })
			part({ Name = "Canopy", Parent = world, Size = Vector3.new(12, 2, 10),
				CFrame = CFrame.new(x, 17, laneZ - 6), Color = Color3.fromRGB(30, 70, 35), CanCollide = false, Transparency = 0.15 })
			part({ Name = "Moss", Parent = world, Size = Vector3.new(1, 6, 1),
				CFrame = CFrame.new(x + 2, 12, laneZ - 5), Color = Color3.fromRGB(60, 100, 40), CanCollide = false, Transparency = 0.3 })
		end
	elseif sp == "sludgeFlats" then
		for i = 1, 5 do
			makeHazard(world, "oilSlick", 35 + i * 40, laneZ, stage.accentColor)
		end
		part({ Name = "BarrelStack", Parent = world, Size = Vector3.new(4, 4, 4),
			CFrame = CFrame.new(mid, 2.5, laneZ - 6), Color = Color3.fromRGB(40, 50, 40), Material = Enum.Material.Metal, CanCollide = false })
	elseif sp == "corkboardShack" then
		part({ Name = "Shack", Parent = world, Size = Vector3.new(14, 8, 8),
			CFrame = CFrame.new(mid, 4, laneZ - 5), Color = Color3.fromRGB(100, 80, 50), Material = Enum.Material.Wood, CanCollide = false })
		local board = part({ Name = "Corkboard", Parent = world, Size = Vector3.new(10, 6, 0.4),
			CFrame = CFrame.new(mid, 5, laneZ - 1), Color = Color3.fromRGB(180, 140, 80), CanCollide = false })
		label(board, "COLLARS → GULFGULP → NESTS", Color3.fromRGB(40, 20, 10), 3)
	elseif sp == "turtleNests" then
		for i = 1, 5 do
			local x = 40 + i * 35
			local nest = part({ Name = "Nest", Parent = world, Size = Vector3.new(4, 0.8, 4),
				CFrame = CFrame.new(x, 0.5, laneZ + 3), Color = Color3.fromRGB(160, 120, 70), Material = Enum.Material.Sand, CanCollide = false })
			label(nest, "NEST", Color3.fromRGB(100, 255, 180), 2)
			local heart = Instance.new("Attachment")
			heart.Parent = nest
			local pe = Instance.new("ParticleEmitter")
			pe.Color = ColorSequence.new(Color3.fromRGB(255, 120, 160))
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
			pe.Lifetime = NumberRange.new(0.8, 1.2)
			pe.Rate = 2
			pe.Speed = NumberRange.new(1, 2)
			pe.Parent = heart
		end
		makeHazard(world, "redTide", mid, laneZ, stage.accentColor)
	elseif sp == "corpGate" then
		part({ Name = "GateL", Parent = world, Size = Vector3.new(3, 14, 8),
			CFrame = CFrame.new(30, 7, laneZ - 2), Color = Color3.fromRGB(50, 55, 65), Material = Enum.Material.Metal, CanCollide = false })
		part({ Name = "GateR", Parent = world, Size = Vector3.new(3, 14, 8),
			CFrame = CFrame.new(42, 7, laneZ - 2), Color = Color3.fromRGB(50, 55, 65), Material = Enum.Material.Metal, CanCollide = false })
		local sign = part({ Name = "GGSign", Parent = world, Size = Vector3.new(16, 5, 0.5),
			CFrame = CFrame.new(36, 12, laneZ - 4), Color = Color3.fromRGB(20, 40, 80), Material = Enum.Material.Metal, CanCollide = false })
		label(sign, "GulfGulp Energy™ — AUTHORIZED ONLY", Color3.fromRGB(255, 180, 40))
	elseif sp == "labConveyor" then
		for i = 1, 6 do
			local x = 40 + i * 30
			part({ Name = "Belt", Parent = world, Size = Vector3.new(20, 0.8, 4),
				CFrame = CFrame.new(x, 3, laneZ - 5), Color = Color3.fromRGB(60, 60, 70), Material = Enum.Material.Metal, CanCollide = false })
			part({ Name = "Sample", Parent = world, Size = Vector3.new(2, 2, 2),
				CFrame = CFrame.new(x, 4.5, laneZ - 5), Color = Color3.fromRGB(80, 220, 120), Material = Enum.Material.Neon, CanCollide = false })
		end
		local file = part({ Name = "LabFile", Parent = world, Size = Vector3.new(8, 5, 0.4),
			CFrame = CFrame.new(mid, 8, laneZ - 10), Color = Color3.fromRGB(240, 240, 230), CanCollide = false })
		label(file, "FILE: engineered gators to guard spills", Color3.fromRGB(180, 40, 40), 3)
	elseif sp == "pipeMaze" then
		for i = 1, 5 do
			local x = 35 + i * 40
			local y = 3 + (i % 3) * 2.5
			part({ Name = "PipeH", Parent = world, Size = Vector3.new(18, 2, 2),
				CFrame = CFrame.new(x, y, laneZ - 4), Color = Color3.fromRGB(90, 90, 100), Material = Enum.Material.Metal, CanCollide = false })
			part({ Name = "PipePlatform", Parent = world, Size = Vector3.new(8, 1, 5),
				CFrame = CFrame.new(x + 5, y - 1.5, laneZ), Color = Color3.fromRGB(70, 75, 85), Material = Enum.Material.Metal })
		end
		-- miniboss arena
		part({ Name = "ArenaFloor", Parent = world, Size = Vector3.new(34, 0.4, 14),
			CFrame = CFrame.new(arenaX, 0.25, laneZ), Color = Color3.fromRGB(40, 42, 50), Material = Enum.Material.Metal })
		local spot = part({ Name = "Spotlight", Parent = world, Size = Vector3.new(2, 1, 2),
			CFrame = CFrame.new(arenaX, 12, laneZ - 6), Color = Color3.fromRGB(255, 160, 40), Material = Enum.Material.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 3
		pl.Range = 40
		pl.Color = Color3.fromRGB(255, 160, 60)
		pl.Parent = spot
	elseif sp == "loadingDock" then
		part({ Name = "Dock", Parent = world, Size = Vector3.new(50, 1.5, 12),
			CFrame = CFrame.new(mid, 1, laneZ), Color = Color3.fromRGB(70, 75, 85), Material = Enum.Material.Metal })
		part({ Name = "Crane", Parent = world, Size = Vector3.new(2, 18, 2),
			CFrame = CFrame.new(mid + 20, 10, laneZ - 6), Color = Color3.fromRGB(255, 160, 40), Material = Enum.Material.Metal, CanCollide = false })
	elseif sp == "bargeGaps" then
		-- segmented decks with gaps
		for i = 1, 5 do
			local x = 25 + i * 42
			part({ Name = "Deck", Parent = world, Size = Vector3.new(28, 1.2, 10),
				CFrame = CFrame.new(x, 0.8, laneZ), Color = Color3.fromRGB(60, 75, 90), Material = Enum.Material.Metal })
			-- water in gap (visual)
			part({ Name = "GapWater", Parent = world, Size = Vector3.new(10, 0.3, 10),
				CFrame = CFrame.new(x + 19, 0.2, laneZ), Color = Color3.fromRGB(30, 80, 110), Material = Enum.Material.Glass, CanCollide = false, Transparency = 0.4 })
		end
	elseif sp == "platformApproach" then
		part({ Name = "Walkway", Parent = world, Size = Vector3.new(length * 0.6, 1, 8),
			CFrame = CFrame.new(length * 0.45, 1, laneZ), Color = Color3.fromRGB(50, 55, 65), Material = Enum.Material.Metal })
		local flare = part({ Name = "RigFlare", Parent = world, Size = Vector3.new(3, 8, 3),
			CFrame = CFrame.new(length - 20, 8, laneZ - 4), Color = Color3.fromRGB(255, 120, 20), Material = Enum.Material.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 4
		pl.Range = 50
		pl.Color = Color3.fromRGB(255, 140, 40)
		pl.Parent = flare
	elseif sp == "helipadWind" then
		local pad = part({ Name = "Helipad", Parent = world, Size = Vector3.new(28, 0.5, 28),
			CFrame = CFrame.new(mid, 0.3, laneZ), Color = Color3.fromRGB(50, 52, 58), Material = Enum.Material.Concrete })
		part({ Name = "HMark", Parent = world, Size = Vector3.new(10, 0.2, 2),
			CFrame = CFrame.new(mid, 0.6, laneZ), Color = Color3.fromRGB(255, 220, 40), Material = Enum.Material.Neon, CanCollide = false })
		makeHazard(world, "windPush", mid + 20, laneZ, stage.accentColor)
		makeHazard(world, "windPush", mid - 10, laneZ, stage.accentColor)
	elseif sp == "spillfatherArena" then
		part({ Name = "ArenaFloor", Parent = world, Size = Vector3.new(50, 0.5, 18),
			CFrame = CFrame.new(arenaX, 0.3, laneZ), Color = Color3.fromRGB(30, 32, 40), Material = Enum.Material.Metal })
		for i = 1, 4 do
			part({ Name = "Pillar", Parent = world, Size = Vector3.new(2, 12, 2),
				CFrame = CFrame.new(arenaX - 20 + i * 12, 6, laneZ - 7), Color = Color3.fromRGB(255, 140, 20), Material = Enum.Material.Neon, CanCollide = false })
		end
		local spot = part({ Name = "BossSpot", Parent = world, Size = Vector3.new(3, 1, 3),
			CFrame = CFrame.new(arenaX, 14, laneZ), Color = Color3.fromRGB(255, 180, 60), Material = Enum.Material.Neon, CanCollide = false })
		local pl = Instance.new("PointLight")
		pl.Brightness = 4
		pl.Range = 55
		pl.Color = Color3.fromRGB(255, 150, 40)
		pl.Parent = spot
		for i = 1, 3 do
			local nest = part({ Name = "FinalNest", Parent = world, Size = Vector3.new(3.5, 0.7, 3.5),
				CFrame = CFrame.new(40 + i * 25, 0.5, laneZ + 4), Color = Color3.fromRGB(140, 110, 60), Material = Enum.Material.Sand, CanCollide = false })
			label(nest, "SAVE", Color3.fromRGB(100, 255, 180), 2)
		end
	end

	-- Generic hazards from stage.hazards list (scattered)
	local hazards = stage.hazards or {}
	for i, hk in hazards do
		if hk ~= "windPush" and hk ~= "canalWater" then -- those placed by set pieces
			local x = length * (0.2 + 0.15 * i)
			makeHazard(world, hk, x, laneZ, stage.accentColor)
		end
	end
end

function WorldBuilder._Decor(world: Folder, stage: any, laneZ: number, length: number)
	-- Sparse unique props — not 4 identical cubes
	local theme = stage.propTheme
	local rng = Random.new(#stage.id * 17 + stage.index * 91)
	local count = math.floor(length / 55)
	for i = 1, count do
		local x = 25 + i * 55 + rng:NextNumber(-6, 6)
		if theme == "beach" or theme == "turtle" then
			part({ Name = "Palm", Parent = world, Size = Vector3.new(1.3, 13, 1.3),
				CFrame = CFrame.new(x, 6.5, laneZ - 9), Color = Color3.fromRGB(110, 70, 40), Material = Enum.Material.Wood, CanCollide = false })
			part({ Name = "Frond", Parent = world, Size = Vector3.new(9, 1.2, 9),
				CFrame = CFrame.new(x, 13.5, laneZ - 9), Color = Color3.fromRGB(40, 140, 60), CanCollide = false })
			if i % 2 == 0 then
				part({ Name = "Cooler", Parent = world, Size = Vector3.new(2.5, 2, 2),
					CFrame = CFrame.new(x + 5, 1.1, laneZ + 3), Color = Color3.fromRGB(40, 120, 200), CanCollide = false })
			end
		elseif theme == "gas" then
			part({ Name = "Dumpster", Parent = world, Size = Vector3.new(4, 3, 3),
				CFrame = CFrame.new(x, 1.6, laneZ - 7), Color = Color3.fromRGB(40, 100, 50), Material = Enum.Material.Metal, CanCollide = false })
		elseif theme == "drive" then
			part({ Name = "Cone", Parent = world, Size = Vector3.new(1.2, 2, 1.2),
				CFrame = CFrame.new(x, 1.1, laneZ + 3), Color = Color3.fromRGB(255, 120, 20), CanCollide = false })
		elseif theme == "swamp" then
			part({ Name = "Stump", Parent = world, Size = Vector3.new(3, 2, 3),
				CFrame = CFrame.new(x, 1.1, laneZ - 7), Color = Color3.fromRGB(60, 45, 30), Material = Enum.Material.Wood, CanCollide = false })
		elseif theme == "rig" then
			part({ Name = "Valve", Parent = world, Size = Vector3.new(2, 2, 1.5),
				CFrame = CFrame.new(x, 2, laneZ - 7), Color = Color3.fromRGB(200, 60, 40), Material = Enum.Material.Metal, CanCollide = false })
			part({ Name = "Warning", Parent = world, Size = Vector3.new(2.5, 2.5, 0.3),
				CFrame = CFrame.new(x, 7, laneZ - 6), Color = Color3.fromRGB(255, 180, 0), Material = Enum.Material.Neon, CanCollide = false })
		end
	end
end

function WorldBuilder._BuildHub(world: Folder, stage: any, laneZ: number, deaths: number?)
	-- Phase 2: bonfire hero kit — cylinder logs + layered ColorSequence flame
	local base = part({
		Name = "Bonfire",
		Parent = world,
		Size = Vector3.new(5.2, 1.1, 5.2),
		CFrame = CFrame.new(20, 0.55, laneZ),
		Color = Color3.fromRGB(55, 35, 18),
		Material = Enum.Material.Wood,
	})
	addSpecialMesh(base, Enum.MeshType.Cylinder, Vector3.new(1, 0.35, 1))
	for i = 1, 5 do
		local a = (i / 5) * math.pi * 2
		local log = part({
			Name = "Log",
			Parent = world,
			Size = Vector3.new(3.6, 0.75, 0.75),
			CFrame = CFrame.new(20 + math.cos(a) * 1.45, 1.0, laneZ + math.sin(a) * 1.45) * CFrame.Angles(0, a, math.rad(18)),
			Color = Color3.fromRGB(90, 58, 28),
			Material = Enum.Material.Wood,
			CanCollide = false,
		})
		addSpecialMesh(log, Enum.MeshType.Cylinder, Vector3.new(1, 1, 1))
	end
	local _ember = part({
		Name = "EmberBed",
		Parent = world,
		Size = Vector3.new(2.4, 0.5, 2.4),
		CFrame = CFrame.new(20, 1.35, laneZ),
		Color = Color3.fromRGB(255, 90, 20),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Shape = Enum.PartType.Cylinder,
	})
	local flame = part({
		Name = "Flame",
		Parent = world,
		Size = Vector3.new(2.8, 4.4, 2.8),
		CFrame = CFrame.new(20, 3.3, laneZ),
		Color = Color3.fromRGB(255, 120, 30),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
	})
	addSpecialMesh(flame, Enum.MeshType.Sphere, Vector3.new(0.85, 1.25, 0.85))
	flame:SetAttribute("Interact", "StartRun")
	label(flame, "🔥 Press E · Start Run", Color3.fromRGB(255, 200, 80))
	proximityPrompt(flame, {
		ActionText = "Start Run",
		ObjectText = "Bonfire",
		Action = "StartRun",
		MaxActivationDistance = 12,
	})
	local att = Instance.new("Attachment")
	att.Parent = flame
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 230, 120)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 120, 30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 30, 20)),
	})
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 1) })
	pe.Lifetime = NumberRange.new(0.5, 1.0)
	pe.Rate = 36
	pe.Speed = NumberRange.new(3, 9)
	pe.LightEmission = 0.85
	pe.Parent = att
	local spark = Instance.new("ParticleEmitter")
	spark.Name = "Sparks"
	spark.Color = ColorSequence.new(Color3.fromRGB(255, 220, 80), Color3.fromRGB(255, 80, 20))
	spark.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
	spark.Lifetime = NumberRange.new(0.35, 0.7)
	spark.Rate = 10
	spark.Speed = NumberRange.new(4, 11)
	spark.SpreadAngle = Vector2.new(40, 40)
	spark.LightEmission = 1
	spark.Parent = att
	local pl = Instance.new("PointLight")
	pl.Brightness = 2.8
	pl.Range = 32
	pl.Color = Color3.fromRGB(255, 140, 40)
	pl.Parent = flame
	task.spawn(function()
		while flame.Parent do
			local t = TweenService:Create(flame, TweenInfo.new(0.35, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = Vector3.new(2.4 + math.random() * 0.9, 3.6 + math.random() * 1.4, 2.4 + math.random() * 0.9),
			})
			t:Play()
			if pl.Parent then
				pl.Brightness = 2.2 + math.random() * 1.3
			end
			t.Completed:Wait()
		end
	end)

	-- Lawn chairs
	for _, ox in { -6, 6 } do
		part({ Name = "ChairSeat", Parent = world, Size = Vector3.new(2.2, 0.3, 2),
			CFrame = CFrame.new(20 + ox, 1.2, laneZ + 4), Color = Color3.fromRGB(40, 140, 200), CanCollide = false })
		part({ Name = "ChairBack", Parent = world, Size = Vector3.new(2.2, 2, 0.3),
			CFrame = CFrame.new(20 + ox, 2.2, laneZ + 5), Color = Color3.fromRGB(40, 140, 200), CanCollide = false })
	end
	-- Cooler
	local cooler = part({ Name = "Cooler", Parent = world, Size = Vector3.new(3, 2.2, 2),
		CFrame = CFrame.new(14, 1.2, laneZ + 2), Color = Color3.fromRGB(30, 100, 180), Material = Enum.Material.SmoothPlastic, CanCollide = false })
	label(cooler, "Florida Dew cooler\n(empty… for now)", Color3.fromRGB(180, 255, 200), 2)

	-- Newspaper stand
	local stand = part({ Name = "NewsStand", Parent = world, Size = Vector3.new(4, 5, 2),
		CFrame = CFrame.new(8, 2.6, laneZ - 3), Color = Color3.fromRGB(140, 100, 60), Material = Enum.Material.Wood, CanCollide = false })
	label(stand, "THE DAILY SWAMP", Color3.fromRGB(255, 240, 200), 3)

	-- Phase 2: Captain Steve pelican kit — SpecialMesh spheres/wedges, neon beak, feather fluff
	local steveModel = Instance.new("Model")
	steveModel.Name = "CaptainSteveModel"
	steveModel:SetAttribute("ArtKit", "InEngine_v2")
	steveModel.Parent = world
	local body = part({
		Name = "CaptainSteve",
		Parent = steveModel,
		Size = Vector3.new(2.9, 3.4, 2.5),
		CFrame = CFrame.new(32, 2.1, laneZ - 2),
		Color = Color3.fromRGB(248, 248, 240),
		Material = Enum.Material.SmoothPlastic,
	})
	addSpecialMesh(body, Enum.MeshType.Sphere, Vector3.new(0.95, 1.15, 0.9))
	body:SetAttribute("Interact", "CaptainSteve")
	local _head = part({
		Name = "Head",
		Parent = steveModel,
		Size = Vector3.new(1.8, 1.8, 1.8),
		Shape = Enum.PartType.Ball,
		CFrame = CFrame.new(32.6, 4.0, laneZ - 2),
		Color = Color3.fromRGB(250, 250, 245),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	local beak = part({
		Name = "Beak",
		Parent = steveModel,
		Size = Vector3.new(3.4, 0.75, 0.95),
		CFrame = CFrame.new(34.5, 2.7, laneZ - 2),
		Color = Color3.fromRGB(255, 150, 35),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	addSpecialMesh(beak, Enum.MeshType.Wedge, Vector3.new(1.2, 0.7, 0.9))
	local pouch = part({
		Name = "Pouch",
		Parent = steveModel,
		Size = Vector3.new(1.9, 1.5, 1.3),
		CFrame = CFrame.new(33.6, 1.45, laneZ - 2),
		Color = Color3.fromRGB(255, 185, 90),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	addSpecialMesh(pouch, Enum.MeshType.Sphere, Vector3.new(1, 0.85, 1))
	local wingL = part({
		Name = "WingL",
		Parent = steveModel,
		Size = Vector3.new(0.45, 2.6, 3.6),
		CFrame = CFrame.new(32, 2.3, laneZ - 4.1),
		Color = Color3.fromRGB(235, 235, 228),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	addSpecialMesh(wingL, Enum.MeshType.Wedge, Vector3.new(0.6, 1.1, 1.2))
	local wingR = part({
		Name = "WingR",
		Parent = steveModel,
		Size = Vector3.new(0.45, 2.6, 3.6),
		CFrame = CFrame.new(32, 2.3, laneZ + 0.3),
		Color = Color3.fromRGB(235, 235, 228),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
	})
	addSpecialMesh(wingR, Enum.MeshType.Wedge, Vector3.new(0.6, 1.1, 1.2))
	part({
		Name = "Eye",
		Parent = steveModel,
		Size = Vector3.new(0.5, 0.5, 0.5),
		Shape = Enum.PartType.Ball,
		CFrame = CFrame.new(33.3, 4.15, laneZ - 2.65),
		Color = Color3.fromRGB(20, 20, 20),
		Material = Enum.Material.Glass,
		CanCollide = false,
	})
	local fluff = Instance.new("Attachment")
	fluff.Parent = body
	local peSteve = Instance.new("ParticleEmitter")
	peSteve.Name = "FeatherFluff"
	peSteve.Color = ColorSequence.new(Color3.fromRGB(255, 255, 245), Color3.fromRGB(255, 200, 120))
	peSteve.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0) })
	peSteve.Lifetime = NumberRange.new(0.6, 1.1)
	peSteve.Rate = 3
	peSteve.Speed = NumberRange.new(0.2, 0.8)
	peSteve.Parent = fluff
	label(body, "Captain Steve\nPress E · Talk", Color3.fromRGB(255, 240, 180))
	proximityPrompt(body, {
		ActionText = "Talk",
		ObjectText = "Captain Steve",
		Action = "TalkCaptainSteve",
		MaxActivationDistance = 12,
	})

	local board = part({
		Name = "HeadlineBoard",
		Parent = world,
		Size = Vector3.new(18, 7, 0.4),
		CFrame = CFrame.new(20, 10, laneZ - 12),
		Color = Color3.fromRGB(30, 30, 35),
		CanCollide = false,
	})
	local headline = Story.HubHeadline(deaths or 0)
	label(board, headline, Color3.fromRGB(255, 220, 120), 0)
end

function WorldBuilder._BuildGround(world: Folder, stage: any, laneZ: number, length: number, groundMat: Enum.Material)
	local biome = stage.biome or "beach"
	local idx = stage.index or 0
	-- Early stages: continuous slab with subtle height steps (teach footing)
	-- Mid/late: real gaps + raised shelves so jump matters
	local segs = if idx <= 3 then 3 elseif idx <= 8 then 5 elseif idx <= 14 then 6 else 7
	local gapChance = if idx <= 4 then 0 elseif idx <= 10 then 0.35 else 0.55
	local cursor = -10
	local segLen = (length + 30) / segs
	local rng = Random.new((#stage.id) * 31 + idx * 97)
	for i = 1, segs do
		local isGap = (i > 1 and i < segs and idx >= 5 and rng:NextNumber() < gapChance and (biome == "swamp" or biome == "offshore" or biome == "facility" or stage.setPiece == "bargeGaps" or stage.setPiece == "canalPads" or stage.setPiece == "pipeMaze"))
		local hOff = 0
		if biome == "swamp" then
			hOff = (i % 3) * 0.35
		elseif biome == "facility" or biome == "offshore" then
			hOff = (i % 2) * 0.6
		elseif biome == "town" then
			hOff = if i % 4 == 0 then 0.4 else 0
		elseif biome == "beach" then
			hOff = math.sin(i * 1.2) * 0.25
		end
		local thisLen = segLen * (0.85 + rng:NextNumber() * 0.25)
		if isGap then
			-- visual water/void under gap (no collide) + small landing lip after
			local gapW = math.clamp(6 + idx * 0.25, 6, 12)
			part({
				Name = "GapHazard",
				Parent = world,
				Size = Vector3.new(gapW, 0.4, 16),
				CFrame = CFrame.new(cursor + gapW / 2, -0.5 + hOff, laneZ),
				Color = if biome == "offshore" or biome == "swamp" then Color3.fromRGB(30, 70, 90) else Color3.fromRGB(20, 20, 25),
				Material = Enum.Material.Glass,
				CanCollide = false,
				Transparency = 0.45,
			})
			cursor += gapW
			-- landing platform
			part({
				Name = "GroundSeg",
				Parent = world,
				Size = Vector3.new(thisLen * 0.55, 2, 28),
				CFrame = CFrame.new(cursor + thisLen * 0.275, -1 + hOff + 0.5, laneZ),
				Color = stage.groundColor:Lerp(stage.accentColor, 0.08),
				Material = groundMat,
			})
			cursor += thisLen * 0.55
		else
			local y = -1 + hOff
			-- Raised shelf mid-lane for mid/late (jump up)
			if idx >= 6 and i == math.floor(segs / 2) then
				part({
					Name = "GroundShelf",
					Parent = world,
					Size = Vector3.new(thisLen * 0.7, 2, 18),
					CFrame = CFrame.new(cursor + thisLen * 0.35, y + 2.2, laneZ),
					Color = stage.groundColor:Lerp(Color3.new(0, 0, 0), 0.1),
					Material = groundMat,
				})
			end
			part({
				Name = "Ground",
				Parent = world,
				Size = Vector3.new(thisLen, 2, 28),
				CFrame = CFrame.new(cursor + thisLen / 2, y, laneZ),
				Color = stage.groundColor,
				Material = groundMat,
			})
			cursor += thisLen
		end
	end
	-- Phase 1: stages 1–3 omit SafetyFloor (soft checkpoint respawn in GameService).
	-- Later stages keep a recovery pad so void falls are not rage-quits.
	local idx = stage.index or 0
	if idx < 1 or idx > 3 then
		part({
			Name = "SafetyFloor",
			Parent = world,
			Size = Vector3.new(length + 80, 1, 40),
			CFrame = CFrame.new(length / 2, -8, laneZ),
			Color = Color3.fromRGB(15, 15, 20),
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.5,
		})
	end
end

function WorldBuilder._MidRoomGate(world: Folder, stage: any, laneZ: number, length: number)
	if (stage.index or 0) < 3 then
		return
	end
	local x = length * 0.48
	local gate = part({
		Name = "MidGate",
		Parent = world,
		Size = Vector3.new(2.5, 10, 12),
		CFrame = CFrame.new(x, 5, laneZ),
		Color = stage.accentColor,
		Material = Enum.Material.ForceField,
		CanCollide = true,
		Transparency = 0.35,
	})
	gate:SetAttribute("Locked", true)
	label(gate, "CLEAR THE POCKET", stage.accentColor, 6)
	-- framing posts
	for _, side in { -1, 1 } do
		part({
			Name = "GatePost",
			Parent = world,
			Size = Vector3.new(1.2, 12, 1.2),
			CFrame = CFrame.new(x, 6, laneZ + side * 6),
			Color = stage.accentColor:Lerp(Color3.new(0, 0, 0), 0.3),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
	end
end

function WorldBuilder.BuildStage(stageId: string, deaths: number?): Folder
	local stage = Stages.Get(stageId)
	assert(stage, "unknown stage " .. tostring(stageId))
	local world = WorldBuilder.Clear()
	local laneZ = Constants.LANE_Z
	local length = stage.length

	WorldBuilder.ApplyLighting(stage)

	local groundMat = Enum.Material.Sand
	if stage.biome == "facility" or stage.biome == "offshore" then
		groundMat = Enum.Material.Metal
	elseif stage.biome == "swamp" then
		groundMat = Enum.Material.Mud
	elseif stage.biome == "town" then
		groundMat = Enum.Material.Asphalt
	elseif stage.biome == "beach" then
		groundMat = Enum.Material.Sand
	end

	-- Segmented ground: distinct heights per biome; mid/late gaps make jump matter
	WorldBuilder._BuildGround(world, stage, laneZ, length, groundMat)

	WorldBuilder._Parallax(world, stage, laneZ, length)

	part({
		Name = "LeftWall",
		Parent = world,
		Size = Vector3.new(2, 20, 20),
		CFrame = CFrame.new(-8, 8, laneZ),
		Transparency = 1,
	})
	part({
		Name = "RightWall",
		Parent = world,
		Size = Vector3.new(2, 20, 20),
		CFrame = CFrame.new(length + 12, 8, laneZ),
		Transparency = 1,
	})

	part({
		Name = "SpawnPad",
		Parent = world,
		Size = Vector3.new(8, 0.5, 8),
		CFrame = CFrame.new(Constants.SPAWN_X, 0.25, laneZ),
		Color = stage.accentColor,
		Material = Enum.Material.Neon,
	})

	if stage.isHub then
		WorldBuilder._BuildHub(world, stage, laneZ, deaths)
	else
		WorldBuilder._Decor(world, stage, laneZ, length)
		WorldBuilder._SetPiece(world, stage, laneZ, length)
		WorldBuilder._Platforms(world, stage, laneZ, length)
		WorldBuilder._MidRoomGate(world, stage, laneZ, length)
	end

	if stage.coldOnePickup then
		local can = part({
			Name = "ColdOne",
			Parent = world,
			Size = Vector3.new(1.2, 2, 1.2),
			CFrame = CFrame.new(length * 0.42, 1.2, laneZ),
			Color = Color3.fromRGB(40, 180, 80),
			Material = Enum.Material.Neon,
			Shape = Enum.PartType.Cylinder,
		})
		can:SetAttribute("Pickup", "ColdOne")
		label(can, "Florida Dew — walk over to pick up", Color3.fromRGB(180, 255, 180))
	end

	if not stage.isHub then
		local gate = part({
			Name = "StageGate",
			Parent = world,
			Size = Vector3.new(3, 12, 14),
			CFrame = CFrame.new(length - 6, 6, laneZ),
			Color = stage.accentColor,
			Material = Enum.Material.ForceField,
			CanCollide = false,
		})
		label(gate, stage.goalLabel or "→ NEXT", stage.accentColor)
		-- goal light
		local glow = part({
			Name = "GoalLight",
			Parent = world,
			Size = Vector3.new(2, 2, 2),
			CFrame = CFrame.new(length - 6, 14, laneZ),
			Color = stage.accentColor,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Shape = Enum.PartType.Ball,
		})
		local gpl = Instance.new("PointLight")
		gpl.Brightness = 2
		gpl.Range = 30
		gpl.Color = stage.accentColor
		gpl.Parent = glow
	end

	local sounds = Instance.new("Folder")
	sounds.Name = "StageSounds"
	sounds.Parent = world
	-- Phase 0 audio smoke: engine/default library IDs (audible placeholders)
	local SOUND_IDS = {
		SFX_Swing = "rbxasset://sounds/switch.wav",
		SFX_Hit = "rbxasset://sounds/impact_water.mp3",
		SFX_CrabClick = "rbxasset://sounds/switch.wav",
		SFX_GatorHiss = "rbxasset://sounds/action_footsteps_plastic.mp3",
		SFX_DraftSting = "rbxasset://sounds/electronicpingshort.wav",
		SFX_BossIntro = "rbxasset://sounds/swoosh.wav",
		SFX_Footstep = "rbxasset://sounds/action_footsteps_plastic.mp3",
		SFX_Splash = "rbxasset://sounds/impact_water.mp3",
		SFX_Flame = "rbxasset://sounds/swoosh.wav",
		SFX_UIClick = "rbxasset://sounds/switch.wav",
	}
	for name, soundId in SOUND_IDS do
		local s = Instance.new("Sound")
		s.Name = name
		s.SoundId = soundId
		s.Volume = 0.45
		s.RollOffMaxDistance = 80
		s.Parent = sounds
	end

	world:SetAttribute("StageId", stageId)
	world:SetAttribute("StageLength", length)
	world:SetAttribute("Biome", stage.biome or "beach")
	world:SetAttribute("SetPiece", stage.setPiece or "")
	world:SetAttribute("StoryBeat", stage.storyBeat or "")
	return world
end

function WorldBuilder.GetSpawnCFrame(_stageId: string): CFrame
	return CFrame.new(Constants.SPAWN_X, 4, Constants.LANE_Z)
end

return WorldBuilder
