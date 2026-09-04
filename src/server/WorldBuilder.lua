--!strict
--[[ Builds 2.5D stages with parallax layers + biome lighting profiles. ]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))
local Stages = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Stages"))

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

local function label(parent: Instance, text: string, color: Color3?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 40)
	bb.StudsOffset = Vector3.new(0, 4, 0)
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
end

local function clearEffects()
	for _, name in { "FM_Atmosphere", "FM_CC", "FM_Bloom", "FM_DoF" } do
		local e = Lighting:FindFirstChild(name)
		if e then
			e:Destroy()
		end
	end
end

function WorldBuilder.ApplyLighting(stage: any)
	clearEffects()
	Lighting.ClockTime = stage.clockTime
	Lighting.FogColor = stage.fogColor
	Lighting.FogStart = 90
	Lighting.FogEnd = 320
	Lighting.OutdoorAmbient = stage.groundColor:Lerp(Color3.new(0.5, 0.5, 0.5), 0.4)
	Lighting.Ambient = stage.fogColor:Lerp(Color3.new(0.3, 0.3, 0.3), 0.5)
	Lighting.Brightness = 2.2

	local atmo = Instance.new("Atmosphere")
	atmo.Name = "FM_Atmosphere"
	atmo.Density = if stage.biome == "swamp" then 0.4 elseif stage.biome == "facility" then 0.28 else 0.22
	atmo.Offset = 0.1
	atmo.Color = stage.fogColor
	atmo.Decay = stage.fogColor:Lerp(Color3.fromRGB(20, 20, 30), 0.5)
	atmo.Glare = if stage.biome == "beach" then 0.2 else 0.08
	atmo.Haze = if stage.biome == "swamp" then 2.2 else 1.2
	atmo.Parent = Lighting

	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FM_CC"
	cc.Saturation = if stage.biome == "facility" then -0.05 elseif stage.biome == "swamp" then 0.1 else 0.15
	cc.Contrast = 0.08
	cc.TintColor = if stage.biome == "offshore" then Color3.fromRGB(240, 245, 255)
		elseif stage.biome == "swamp" then Color3.fromRGB(230, 255, 230)
		elseif stage.hangover then Color3.fromRGB(255, 240, 220)
		else Color3.fromRGB(255, 255, 255)
	cc.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "FM_Bloom"
	bloom.Intensity = 0.35
	bloom.Size = 18
	bloom.Threshold = 1.1
	bloom.Parent = Lighting

	local dof = Instance.new("DepthOfFieldEffect")
	dof.Name = "FM_DoF"
	dof.FarIntensity = 0.12
	dof.NearIntensity = 0.05
	dof.FocusDistance = 40
	dof.InFocusRadius = 30
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
	-- far sky band
	part({
		Name = "SkyFar",
		Parent = folder,
		Size = Vector3.new(length + 80, 50, 1),
		CFrame = CFrame.new(length / 2, 22, laneZ - 48),
		Color = stage.fogColor:Lerp(Color3.fromRGB(255, 200, 140), 0.15),
		CanCollide = false,
		CastShadow = false,
		Transparency = 0.15,
	})
	-- mid hills / city silhouette
	for i = 1, math.floor(length / 40) + 2 do
		local x = (i - 1) * 40 + 10
		local h = 8 + (i % 5) * 3
		part({
			Name = "MidSilhouette",
			Parent = folder,
			Size = Vector3.new(18 + (i % 3) * 4, h, 2),
			CFrame = CFrame.new(x, h / 2 + 1, laneZ - 28),
			Color = stage.fogColor:Lerp(stage.groundColor, 0.35):Lerp(Color3.new(0, 0, 0), 0.25),
			CanCollide = false,
			CastShadow = false,
			Transparency = 0.25,
		})
	end
	-- near backdrop wall (soft)
	part({
		Name = "BackDrop",
		Parent = folder,
		Size = Vector3.new(length + 40, 36, 2),
		CFrame = CFrame.new(length / 2, 16, laneZ - 16),
		Color = stage.fogColor,
		CanCollide = false,
		Transparency = 0.35,
		CastShadow = false,
	})
end

function WorldBuilder.BuildStage(stageId: string): Folder
	local stage = Stages.Get(stageId)
	assert(stage, "unknown stage " .. tostring(stageId))
	local world = WorldBuilder.Clear()
	local laneZ = Constants.LANE_Z
	local length = stage.length

	WorldBuilder.ApplyLighting(stage)

	part({
		Name = "Ground",
		Parent = world,
		Size = Vector3.new(length + 40, 2, 28),
		CFrame = CFrame.new(length / 2, -1, laneZ),
		Color = stage.groundColor,
		Material = if stage.biome == "facility" or stage.biome == "offshore" then Enum.Material.Metal else Enum.Material.Sand,
	})

	WorldBuilder._Parallax(world, stage, laneZ, length)

	-- NO front/side Z fences — MovementController locks lane (avoids jitter)
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

	WorldBuilder._Decor(world, stage, laneZ, length)

	if stage.isHub then
		WorldBuilder._BuildHub(world, stage, laneZ)
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
		label(can, "Florida Dew\n(The Cold One)", Color3.fromRGB(180, 255, 180))
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
		label(gate, "→ NEXT HEADLINE", stage.accentColor)
	end

	-- Audio hooks (placeholder Sounds with clear names)
	local sounds = Instance.new("Folder")
	sounds.Name = "StageSounds"
	sounds.Parent = world
	for _, name in { "SFX_Swing", "SFX_Hit", "SFX_CrabClick", "SFX_GatorHiss", "SFX_DraftSting", "SFX_BossIntro", "SFX_Footstep", "SFX_Splash", "SFX_Flame" } do
		local s = Instance.new("Sound")
		s.Name = name
		s.Volume = 0.4
		s.RollOffMaxDistance = 80
		s.Parent = sounds
	end

	world:SetAttribute("StageId", stageId)
	world:SetAttribute("StageLength", length)
	world:SetAttribute("Biome", stage.biome or "beach")
	return world
end

function WorldBuilder._Decor(world: Folder, stage: any, laneZ: number, length: number)
	local theme = stage.propTheme
	local rng = Random.new(#stage.id * 17 + stage.index * 91)
	for i = 1, math.floor(length / 28) do
		local x = 20 + i * 28 + rng:NextNumber(-4, 4)
		if theme == "beach" or theme == "turtle" then
			part({
				Name = "Palm",
				Parent = world,
				Size = Vector3.new(1.2, 12, 1.2),
				CFrame = CFrame.new(x, 6, laneZ - 8),
				Color = Color3.fromRGB(110, 70, 40),
				Material = Enum.Material.Wood,
				CanCollide = false,
			})
			part({
				Name = "Frond",
				Parent = world,
				Size = Vector3.new(8, 1, 8),
				CFrame = CFrame.new(x, 12.5, laneZ - 8),
				Color = Color3.fromRGB(40, 140, 60),
				CanCollide = false,
			})
			if theme == "turtle" and i % 2 == 0 then
				part({
					Name = "TideLine",
					Parent = world,
					Size = Vector3.new(10, 0.2, 4),
					CFrame = CFrame.new(x, 0.15, laneZ + 5),
					Color = Color3.fromRGB(180, 60, 80),
					Material = Enum.Material.Mud,
					CanCollide = false,
					Transparency = 0.3,
				})
			end
		elseif theme == "gas" then
			part({
				Name = "Pump",
				Parent = world,
				Size = Vector3.new(2, 6, 2),
				CFrame = CFrame.new(x, 3, laneZ - 7),
				Color = Color3.fromRGB(220, 40, 40),
				Material = Enum.Material.Metal,
				CanCollide = false,
			})
			part({
				Name = "Canopy",
				Parent = world,
				Size = Vector3.new(14, 0.6, 10),
				CFrame = CFrame.new(x, 7, laneZ - 5),
				Color = Color3.fromRGB(255, 200, 40),
				CanCollide = false,
			})
		elseif theme == "drive" then
			part({
				Name = "MenuBoard",
				Parent = world,
				Size = Vector3.new(0.6, 5, 4),
				CFrame = CFrame.new(x, 3, laneZ - 7),
				Color = Color3.fromRGB(30, 30, 30),
				CanCollide = false,
			})
			label(part({
				Name = "Speaker",
				Parent = world,
				Size = Vector3.new(1.5, 2, 1.5),
				CFrame = CFrame.new(x + 3, 1.5, laneZ - 5),
				Color = Color3.fromRGB(80, 80, 80),
				CanCollide = false,
			}), "ORDER HERE", Color3.fromRGB(255, 200, 80))
		elseif theme == "swamp" then
			part({
				Name = "Cypress",
				Parent = world,
				Size = Vector3.new(2.5, 14, 2.5),
				CFrame = CFrame.new(x, 7, laneZ - 9),
				Color = Color3.fromRGB(50, 40, 25),
				Material = Enum.Material.Wood,
				CanCollide = false,
			})
			part({
				Name = "SludgePool",
				Parent = world,
				Size = Vector3.new(8, 0.3, 6),
				CFrame = CFrame.new(x + 5, 0.2, laneZ + 4),
				Color = Color3.fromRGB(30, 45, 25),
				Material = Enum.Material.Mud,
				CanCollide = false,
			})
		elseif theme == "rig" then
			part({
				Name = "Pipe",
				Parent = world,
				Size = Vector3.new(10, 1.5, 1.5),
				CFrame = CFrame.new(x, 4, laneZ - 8),
				Color = Color3.fromRGB(90, 90, 100),
				Material = Enum.Material.Metal,
				CanCollide = false,
			})
			part({
				Name = "Warning",
				Parent = world,
				Size = Vector3.new(3, 3, 0.4),
				CFrame = CFrame.new(x, 8, laneZ - 7),
				Color = Color3.fromRGB(255, 180, 0),
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
		end
	end

	if theme == "turtle" or theme == "rig" or theme == "drive" then
		local sign = part({
			Name = "GulfGulpSign",
			Parent = world,
			Size = Vector3.new(12, 4, 0.5),
			CFrame = CFrame.new(length * 0.5, 10, laneZ - 12),
			Color = Color3.fromRGB(20, 40, 80),
			Material = Enum.Material.Metal,
			CanCollide = false,
		})
		label(sign, "GulfGulp Energy™", Color3.fromRGB(255, 180, 40))
	end
end

function WorldBuilder._BuildHub(world: Folder, stage: any, laneZ: number)
	part({
		Name = "Bonfire",
		Parent = world,
		Size = Vector3.new(5, 1, 5),
		CFrame = CFrame.new(20, 0.5, laneZ),
		Color = Color3.fromRGB(60, 40, 20),
		Material = Enum.Material.Wood,
	})
	local flame = part({
		Name = "Flame",
		Parent = world,
		Size = Vector3.new(3, 4, 3),
		CFrame = CFrame.new(20, 3, laneZ),
		Color = Color3.fromRGB(255, 120, 30),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Shape = Enum.PartType.Ball,
	})
	flame:SetAttribute("Interact", "StartRun")
	label(flame, "🔥 TOUCH TO BEGIN", Color3.fromRGB(255, 200, 80))
	local att = Instance.new("Attachment")
	att.Parent = flame
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 180, 40), Color3.fromRGB(255, 60, 20))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.4, 0.8)
	pe.Rate = 20
	pe.Speed = NumberRange.new(3, 7)
	pe.LightEmission = 0.7
	pe.Parent = att

	local steve = part({
		Name = "CaptainSteve",
		Parent = world,
		Size = Vector3.new(3, 4, 3),
		CFrame = CFrame.new(32, 2.2, laneZ - 2),
		Color = Color3.fromRGB(240, 240, 230),
		Material = Enum.Material.SmoothPlastic,
	})
	steve:SetAttribute("Interact", "CaptainSteve")
	part({
		Name = "Beak",
		Parent = world,
		Size = Vector3.new(2.5, 0.8, 0.8),
		CFrame = CFrame.new(34.2, 3, laneZ - 2),
		Color = Color3.fromRGB(255, 160, 40),
		CanCollide = false,
	})
	label(steve, "Captain Steve\n(Pelican Upgrades)", Color3.fromRGB(255, 240, 180))

	local board = part({
		Name = "HeadlineBoard",
		Parent = world,
		Size = Vector3.new(16, 6, 0.4),
		CFrame = CFrame.new(20, 9, laneZ - 12),
		Color = Color3.fromRGB(30, 30, 35),
		CanCollide = false,
	})
	label(board, stage.headline, Color3.fromRGB(255, 220, 120))

	task.spawn(function()
		while flame.Parent do
			local t = TweenService:Create(flame, TweenInfo.new(0.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = Vector3.new(2.6 + math.random() * 0.8, 3.5 + math.random() * 1.2, 2.6 + math.random() * 0.8),
			})
			t:Play()
			t.Completed:Wait()
		end
	end)
end

function WorldBuilder.GetSpawnCFrame(stageId: string): CFrame
	local y = 4
	return CFrame.new(Constants.SPAWN_X, y, Constants.LANE_Z)
end

return WorldBuilder
