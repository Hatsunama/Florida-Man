--!strict
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Definitions = require(Shared:WaitForChild("HazardDefinitions"))
local CharacterGeometry = require(Shared:WaitForChild("CharacterGeometry"))
local HazardRules = require(Shared:WaitForChild("HazardRules"))
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))

local HazardService = {}
export type HazardCtx = { runActive: boolean, stageId: string, stageIndex: number, checkpointX: number, moveSpeed: number }
local registered: { [BasePart]: boolean } = {}
local currentWorld: Instance? = nil
local connections: { RBXScriptConnection } = {}
local function register(instance: Instance)
	if instance:IsA("BasePart") and (instance:GetAttribute("Hazard") or instance:GetAttribute("JumpPad") or instance:GetAttribute("ConveyorMove")) then
		registered[instance] = true
	end
end

local function bindWorld(world: Instance)
	if currentWorld == world then return end
	for _, connection in connections do connection:Disconnect() end
	table.clear(connections)
	table.clear(registered)
	currentWorld = world
	for _, instance in world:GetDescendants() do register(instance) end
	table.insert(connections, world.DescendantAdded:Connect(function(instance)
		task.defer(function() if instance:IsDescendantOf(world) then register(instance) end end)
	end))
	table.insert(connections, world.DescendantRemoving:Connect(function(instance)
		if instance:IsA("BasePart") then registered[instance] = nil end
	end))
end

function HazardService.Spawn(kind: string, position: Vector3, size: Vector3, lifetime: number): BasePart?
	local world = Workspace:FindFirstChild("GameWorld")
	if not world or not Definitions[kind] then return nil end
	local hazard = Instance.new("Part")
	hazard.Name = "Hazard_" .. kind
	hazard.Anchored, hazard.CanCollide, hazard.CanQuery, hazard.CanTouch = true, false, false, false
	hazard.Size, hazard.Position = size, position
	hazard.Color = Color3.fromRGB(35, 50, 30)
	hazard.Material, hazard.Transparency = Enum.Material.Mud, 0.25
	hazard:SetAttribute("Hazard", kind)
	hazard.Parent = world
	register(hazard)
	Debris:AddItem(hazard, lifetime)
	return hazard
end

local function impulse(player: Player, char: Model, y: number)
	MovementAuthority.AllowImpulse(player, y)
	char:SetAttribute("ImpulseY", y)
	char:SetAttribute("ImpulseRevision", ((char:GetAttribute("ImpulseRevision") :: number?) or 0) + 1)
end

local function overlap(part: BasePart, hrp: BasePart, hum: Humanoid): boolean
	local localPos = part.CFrame:PointToObjectSpace(hrp.Position)
	local half = part.Size * 0.5
	local feet = hrp.Position.Y - CharacterGeometry.FeetDistance(hum.Parent :: Model,hrp,hum)
	local top = hrp.Position.Y + hrp.Size.Y * 0.5
	return math.abs(localPos.X) <= half.X + hrp.Size.X * 0.35
		and math.abs(localPos.Z) <= half.Z + hrp.Size.Z * 0.35
		and feet <= part.Position.Y + half.Y + 0.25 and top >= part.Position.Y - half.Y
end

local function safeSupportAt(world: Instance, char: Model, hrp: BasePart, hum: Humanoid, position: Vector3): Vector3?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	params.RespectCanCollide = true
	local standing = CharacterGeometry.FeetDistance(char,hrp,hum)
	local support: Vector3? = nil
	for _, offset in { -0.8, 0.8 } do
		local result = Workspace:Raycast(position + Vector3.new(offset, 0, 0), Vector3.new(0, -(standing + 0.35), 0), params)
		if not result or result.Normal.Y < 0.8 or not result.Instance:IsDescendantOf(world) or result.Instance:GetAttribute("Hazard") or result.Instance:GetAttribute("EnemyHitbox") then return nil end
		support = Vector3.new(position.X, result.Position.Y + standing + 0.1, Constants.LANE_Z)
	end
	local clear = OverlapParams.new()
	clear.FilterType = Enum.RaycastFilterType.Exclude
	clear.FilterDescendantsInstances = { char }
	clear.RespectCanCollide = true
	local height = standing + hrp.Size.Y * 0.5 - 0.2
	local center = (support :: Vector3) + Vector3.new(0, (hrp.Size.Y * 0.5 - standing) * 0.5, 0)
	if #Workspace:GetPartBoundsInBox(CFrame.new(center), Vector3.new(math.max(2, hrp.Size.X), height, math.max(2, hrp.Size.Z)), clear) > 0 then return nil end
	for hazard in registered do
		local localPos = hazard.CFrame:PointToObjectSpace(support :: Vector3)
		if hazard:GetAttribute("Hazard") and math.abs(localPos.X) < hazard.Size.X * 0.5 + hrp.Size.X
			and math.abs(localPos.Z) < hazard.Size.Z * 0.5 + hrp.Size.Z
			and math.abs(localPos.Y) < hazard.Size.Y * 0.5 + standing then return nil end
	end
	return support
end

local function softFall(player: Player, char: Model, hrp: BasePart, toast: ((Player, string) -> ())?, reason: string)
	local now = os.clock()
	if now - ((char:GetAttribute("LastSoftFallAt") :: number?) or -10) < 1 then return end
	char:SetAttribute("LastSoftFallAt", now)
	char:SetAttribute("WaterSince", nil)
	local x = (char:GetAttribute("LastSolidX") :: number?) or Constants.SPAWN_X
	local y = (char:GetAttribute("LastSolidY") :: number?) or 5
	local world = Workspace:FindFirstChild("GameWorld")
	local hum = char:FindFirstChildOfClass("Humanoid")
	local supported = if world and hum then safeSupportAt(world, char, hrp, hum, Vector3.new(x, y, Constants.LANE_Z)) else nil
	if supported then x, y = supported.X, supported.Y else x, y = Constants.SPAWN_X, 5 end
	MovementAuthority.Reset(player, CFrame.new(x, y, Constants.LANE_Z))
	hrp.AssemblyLinearVelocity = Vector3.zero
	char:SetAttribute("ExternalVelocityX", 0)
	char:SetAttribute("ExternalVelocityY", 0)
	char:SetAttribute("ExternalMotionUntil", 0)
	CombatService.SetIFrames(player, 0.6)
	local count = (char:GetAttribute("SoftFallToasts") :: number?) or 0
	if toast and count < Constants.SOFT_FALL_TOAST_MAX then
		char:SetAttribute("SoftFallToasts", count + 1)
		toast(player, reason)
	end
end

function HazardService.Tick(player: Player, ctx: HazardCtx, applyDamage: (Player, number) -> (), toast: ((Player, string) -> ())?)
	local world = Workspace:FindFirstChild("GameWorld")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not world or not char or not hrp or not hum then return end
	bindWorld(world)
	-- A rejected pose is corrected; it must not buy a hazard-free simulation step.
	if hum.Health > 0 then MovementAuthority.Validate(player) end
	if not ctx.runActive or hum.Health <= 0 then
		char:SetAttribute("ExternalMotionUntil", 0)
		return
	end
	local stageKey = tostring(player:GetAttribute("SessionGeneration")) .. ":" .. ctx.stageId
	if char:GetAttribute("SafeStageKey") ~= stageKey then
		char:SetAttribute("SafeStageKey", stageKey)
		char:SetAttribute("LastSolidX", nil)
		char:SetAttribute("LastSolidY", nil)
		char:SetAttribute("WaterSince", nil)
	end
	local now = os.clock()
	local effects = HazardRules.New()
	local onPad, padBoost = false, 0
	local oilResist = char:GetAttribute("OilResist") == true
	for hazard in registered do
		if not hazard.Parent then registered[hazard] = nil; continue end
		if hazard:GetAttribute("ConveyorMove") then
			local origin = (hazard:GetAttribute("ConveyorOriginX") :: number?) or hazard.Position.X
			local amplitude = (hazard:GetAttribute("ConveyorAmp") :: number?) or 6
			local speed = (hazard:GetAttribute("ConveyorSpeed") :: number?) or 1.2
			hazard.Position = Vector3.new(origin + math.sin(now * speed) * amplitude, hazard.Position.Y, hazard.Position.Z)
		end
		local kind = hazard:GetAttribute("Hazard")
		local def = if typeof(kind) == "string" then Definitions[kind] else nil
		if def then
			local period = (hazard:GetAttribute("HazardPeriod") :: number?) or def.period
			local duty = (hazard:GetAttribute("HazardDuty") :: number?) or def.duty or 0.5
			local active = hazard:GetAttribute("HazardEnabled") ~= false and (not period or now % period < period * duty)
			hazard:SetAttribute("HazardActive", active)
			if period then hazard.Transparency = if active then 0.2 else 0.72 end
			if not active or not overlap(hazard, hrp, hum) then continue end
			local direction = 1
			if kind == "conveyor" then
				local phase = math.floor(now / Constants.CONVEYOR_FLIP_PERIOD) % 2
				direction = if phase == 0 then 1 else -1
				hazard:SetAttribute("ConveyorDir", direction)
				hazard.Color = if direction > 0 then Color3.fromRGB(70, 100, 150) else Color3.fromRGB(150, 100, 70)
			elseif kind == "windPush" then
				direction = (hazard:GetAttribute("WindDir") :: number?) or -1
			end
			HazardRules.Add(effects, def, oilResist, direction)
		elseif hazard:GetAttribute("JumpPad") and overlap(hazard, hrp, hum) then
			onPad = true
			padBoost = math.max(padBoost, (hazard:GetAttribute("PadBoost") :: number?) or 52)
		end
	end
	if effects.oilSlow then
		char:SetAttribute("OilSlowUntil", math.max((char:GetAttribute("OilSlowUntil") :: number?) or 0, now + (if oilResist then 0.35 else 0.8)))
	end
	if effects.environmentSlow then
		char:SetAttribute("EnvironmentalSlowUntil", math.max((char:GetAttribute("EnvironmentalSlowUntil") :: number?) or 0, now + 0.8))
	end
	local damageReady = effects.damage > 0 and not CombatService.HasIFrames(player)
		and now - ((char:GetAttribute("LastHazardAt") :: number?) or -10) >= 0.8
	local impulseY = if damageReady then effects.impulseY else 0
	if onPad and hrp.AssemblyLinearVelocity.Y < 10 and now - ((char:GetAttribute("LastPadAt") :: number?) or -10) > 0.6 then
		char:SetAttribute("LastPadAt", now)
		impulseY = math.max(impulseY, padBoost)
	end
	if impulseY > 0 then impulse(player, char, impulseY) end
	if damageReady then
		char:SetAttribute("LastHazardAt", now)
		applyDamage(player, effects.damage)
		if player.Character ~= char or hum.Health <= 0 or player:GetAttribute("RunActive") == false then return end
	end
	local velocityX, velocityY = math.clamp(effects.velocityX, -18, 18), math.clamp(effects.velocityY, -8, 8)
	MovementAuthority.SetExternal(player, velocityX, velocityY, 0.2)
	char:SetAttribute("ExternalVelocityX", math.clamp(velocityX, -18, 18))
	char:SetAttribute("ExternalVelocityY", math.clamp(velocityY, -8, 8))
	char:SetAttribute("ExternalMotionUntil", Workspace:GetServerTimeNow() + 0.2)
	if effects.water and not onPad then
		local since = char:GetAttribute("WaterSince")
		if typeof(since) ~= "number" then char:SetAttribute("WaterSince", now)
		elseif now - since >= Constants.WATER_TIMEOUT then softFall(player, char, hrp, toast, "Deep water — use the pads to cross.") end
	else char:SetAttribute("WaterSince", nil) end
	local support = if math.abs(hrp.AssemblyLinearVelocity.Y) <= 2 then safeSupportAt(world, char, hrp, hum, hrp.Position) else nil
	if support then
		char:SetAttribute("LastSolidX", support.X)
		char:SetAttribute("LastSolidY", support.Y)
		ctx.checkpointX = support.X
	end
	if hrp.Position.Y < -2 then softFall(player, char, hrp, toast, "Back on safe ground.") end
end

function HazardService.GetRegisteredCount(): number
	local count=0
	for object in registered do if object.Parent then count+=1 end end
	return count
end

return HazardService
