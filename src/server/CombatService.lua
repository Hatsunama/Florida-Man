--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Geometry = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CombatGeometry"))

local Movesets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Movesets"))
local EnemyMovementRules = require(script.Parent:WaitForChild("EnemyMovementRules"))

local CombatService = {}
type EnemyProvider = { GetGeneration: () -> number, GetAlive: () -> { Model }, CanDamage: (Model) -> boolean }
local enemyProvider: EnemyProvider? = nil

function CombatService.SetEnemyProvider(provider: EnemyProvider)
	enemyProvider = provider
end

export type MovesetHit = Movesets.MovesetHit

local iframesUntil: { [Player]: number } = {}
local attackReadyAt: { [Player]: number } = {}
local cancelOpenAt: { [Player]: number } = {}
local skillReadyAt: { [Player]: number } = {}
local swapReadyAt: { [Player]: number } = {}
local dodgeReadyAt: { [Player]: number } = {}
local shieldAbsorb: { [Player]: number } = {}

local ATTACK_RECOVERY = Constants.ATTACK_RECOVERY

function CombatService.SetIFrames(player: Player, duration: number)
	local untilT = os.clock() + math.max(0, duration)
	local prev = iframesUntil[player] or 0
	iframesUntil[player] = math.max(prev, untilT)
end

function CombatService.HasIFrames(player: Player): boolean
	local t = iframesUntil[player]
	if not t then
		return false
	end
	if os.clock() < t then
		return true
	end
	iframesUntil[player] = nil
	return false
end

function CombatService.ClearIFrames(player: Player)
	iframesUntil[player] = nil
end

function CombatService.SetShieldAbsorb(player: Player, amount: number)
	shieldAbsorb[player] = math.max(shieldAbsorb[player] or 0, amount)
end

function CombatService.GetShieldAbsorb(player: Player): number
	return shieldAbsorb[player] or 0
end

function CombatService.ClearShieldAbsorb(player: Player)
	shieldAbsorb[player] = nil
end

function CombatService.ConsumeShieldAbsorb(player: Player, amount: number): number
	local left = shieldAbsorb[player] or 0
	if left <= 0 then
		return amount
	end
	if left >= amount then
		shieldAbsorb[player] = left - amount
		return 0
	end
	shieldAbsorb[player] = nil
	return amount - left
end

function CombatService.CanAttack(player: Player): boolean
	local t = attackReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return true
end

function CombatService.MarkAttack(player: Player, recovery: number?, cancelAfter: number?)
	local now = os.clock()
	local rec = recovery or ATTACK_RECOVERY
	attackReadyAt[player] = now + rec
	local ca = cancelAfter
	if typeof(ca) ~= "number" then
		ca = math.min(rec * 0.5, math.max(0.06, rec - 0.04))
	end
	cancelOpenAt[player] = now + math.clamp(ca :: number, 0.05, rec)
end

function CombatService.GetAttackReadyAt(player: Player): number
	return attackReadyAt[player] or 0
end

function CombatService.GetCancelOpenAt(player: Player): number
	return cancelOpenAt[player] or 0
end

function CombatService.InCancelWindow(player: Player): boolean
	local now = os.clock()
	local ready = attackReadyAt[player]
	local open = cancelOpenAt[player]
	if not ready or not open then
		return false
	end
	return now >= open and now < ready
end

function CombatService.CanSkill(player: Player): boolean
	local t = skillReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return CombatService.CanAttack(player) or CombatService.InCancelWindow(player)
end

function CombatService.MarkSkill(player: Player, cooldown: number)
	skillReadyAt[player] = os.clock() + math.max(0, cooldown)
end

function CombatService.CanSwap(player: Player): boolean
	local t = swapReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return CombatService.CanAttack(player) or CombatService.InCancelWindow(player)
end

function CombatService.GetSkillReadyAt(player: Player): number
	return skillReadyAt[player] or 0
end

function CombatService.GetSwapReadyAt(player: Player): number
	return swapReadyAt[player] or 0
end

function CombatService.GetDodgeReadyAt(player: Player): number
	return dodgeReadyAt[player] or 0
end

function CombatService.CanDodge(player: Player): boolean
	return os.clock() >= (dodgeReadyAt[player] or 0) and (CombatService.CanAttack(player) or CombatService.InCancelWindow(player))
end

function CombatService.MarkDodge(player: Player, cooldown: number)
	dodgeReadyAt[player] = os.clock() + cooldown
end

function CombatService.ResetPlayer(player: Player)
	iframesUntil[player], attackReadyAt[player], cancelOpenAt[player] = nil, nil, nil
	skillReadyAt[player], swapReadyAt[player], dodgeReadyAt[player], shieldAbsorb[player] = nil, nil, nil, nil
end

function CombatService.ResolveFacing(player: Player, intent: number?, fallback: number?): number
	if typeof(intent) == "number" and (intent == 1 or intent == -1) then return intent end
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if root then
		if math.abs(root.AssemblyLinearVelocity.X) > 0.5 then return if root.AssemblyLinearVelocity.X > 0 then 1 else -1 end
		if math.abs(root.CFrame.LookVector.X) > 0.1 then return if root.CFrame.LookVector.X > 0 then 1 else -1 end
	end
	return if fallback == -1 then -1 else 1
end

local function obstacleParams(attacker: Player?): RaycastParams
	local excluded: { Instance } = {}
	for _, player in Players:GetPlayers() do if player.Character then table.insert(excluded, player.Character) end end
	local world = Workspace:FindFirstChild("GameWorld")
	if world then
		for _, child in world:GetChildren() do
			if child:IsA("Model") and child:GetAttribute("EnemyId") then table.insert(excluded, child) end
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = excluded
	params.RespectCanCollide = true
	params.IgnoreWater = true
	return params
end

function CombatService.HasLineOfSight(origin: Vector3, destination: Vector3, attacker: Player?): boolean
	local delta = destination - origin
	if delta.Magnitude < 0.01 then return true end
	return Workspace:Raycast(origin, delta, obstacleParams(attacker)) == nil
end

function CombatService.InHitVolume(origin: Vector3, facing: number, root: BasePart, range: number, height: number, attacker: Player?, bothDirections: boolean?): boolean
	local delta = root.Position - origin
	local half = root.Size * 0.5
	-- Presentation yaw rotates non-square roots; use their world-space extents.
	local right, up, look = root.CFrame.RightVector, root.CFrame.UpVector, root.CFrame.LookVector
	half = Vector3.new(
		math.abs(right.X)*half.X+math.abs(up.X)*half.Y+math.abs(look.X)*half.Z,
		math.abs(right.Y)*half.X+math.abs(up.Y)*half.Y+math.abs(look.Y)*half.Z,
		math.abs(right.Z)*half.X+math.abs(up.Z)*half.Y+math.abs(look.Z)*half.Z)
	return math.abs(delta.X) <= range + half.X and (bothDirections == true or delta.X * facing >= -half.X)
		and math.abs(delta.Y) <= height + half.Y and math.abs(delta.Z) <= 2 + half.Z
		and CombatService.HasLineOfSight(origin, root.Position, attacker)
end

function CombatService.SweepDash(player: Player, root: BasePart, distance: number): Vector3
	local direction = Vector3.new(distance, 0, 0)
	local hit = Workspace:Blockcast(root.CFrame, root.Size * 0.9, direction, obstacleParams(player))
	local actual = if hit then math.max(0, hit.Distance - 0.2) * math.sign(distance) else distance
	local world = Workspace:FindFirstChild("GameWorld")
	local stageLength = world and world:GetAttribute("StageLength")
	local x = root.Position.X + actual
	if typeof(stageLength) == "number" then x = math.clamp(x, Constants.SPAWN_X, stageLength - 6) end
	return Vector3.new(x, root.Position.Y, Constants.LANE_Z)
end

function CombatService.ClampEnemySpawnX(x: number, size: Vector3): number
	local world = Workspace:FindFirstChild("GameWorld")
	local length = world and world:GetAttribute("StageLength")
	if typeof(length) ~= "number" then return x end
	local gate = world and world:FindFirstChild("MidGate")
	local gateLeft: number? = nil
	if gate and gate:IsA("BasePart") and gate.CanCollide and gate:GetAttribute("Locked") == true then
		gateLeft = gate.Position.X - gate.Size.X * 0.5
	end
	return EnemyMovementRules.ClampX(x, length, math.max(size.X, size.Z) * 0.5, gateLeft)
end

-- Anchored AI needs the same world collision contract as a physical body.
-- A conservative horizontal footprint covers turning; shortened height leaves
-- floor clearance without ignoring actual walls, platforms, or closed gates.
function CombatService.SweepEnemy(model: Model, destination: Vector3): Vector3
	local root = model.PrimaryPart
	if not root then return destination end
	local target = Vector3.new(CombatService.ClampEnemySpawnX(destination.X, root.Size), destination.Y, Constants.LANE_Z)
	local delta = target - root.Position
	if delta.Magnitude < 0.001 then return root.Position end
	local width = math.max(root.Size.X, root.Size.Z)
	local size = Vector3.new(width, root.Size.Y * 0.9, width)
	local hit = Workspace:Blockcast(CFrame.new(root.Position), size, delta, obstacleParams(nil))
	return if hit then root.Position + delta.Unit * math.max(0, hit.Distance - 0.15) else target
end

function CombatService.MarkSwap(player: Player, cooldown: number)
	swapReadyAt[player] = os.clock() + math.max(0, cooldown)
end

function CombatService.GetMovesetHit(personaId: string, comboIndex: number): MovesetHit
	return Movesets.Get(personaId, comboIndex)
end

function CombatService.LaneKnockback(originX: number, targetPos: Vector3, strength: number): Vector3
	local dir = if targetPos.X >= originX then 1 else -1
	local kb = math.clamp(strength or Constants.KNOCKBACK_BASE, 0, 24)
	return Vector3.new(targetPos.X + dir * kb, targetPos.Y, Constants.LANE_Z)
end

function CombatService.ApplyKnockback(model: Model, attacker: Player?, strength: number?, heavy: boolean?)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local kb = math.clamp(strength or 4, 0, 28)
	local dir = 1
	if attacker and attacker.Character then
		local hrp = attacker.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			dir = if root.Position.X >= hrp.Position.X then 1 else -1
		end
	end
	local lift = if heavy then 0.6 else 0.25

	if not root.Anchored then
		local impulse = Vector3.new(dir * kb * 12, lift * 18, 0)
		root:ApplyImpulse(impulse * math.max(root.AssemblyMass, 1) * 0.35)

		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, v.Y, 0)
		return
	end

	local np = CombatService.SweepEnemy(model, root.Position + Vector3.new(dir * kb, 0, 0))
	model:PivotTo(CFrame.new(np) * (root.CFrame - root.Position))
end

export type ProjectileOpts = {
	origin: Vector3,
	facing: number,
	range: number,
	damage: number,
	knockback: number,
	heavy: boolean?,
	kind: string,
	vfx: string?,
	attacker: Player,
	onHit: (model: Model, damage: number, knock: number, heavy: boolean) -> (),
	isCurrent: (() -> boolean)?,
	filterAlly: boolean?,
}

local function projectileColor(vfx: string?, kind: string): Color3
	if kind == "thrown" then
		if vfx == "dart" then
			return Color3.fromRGB(180, 255, 120)
		elseif vfx == "rocket" then
			return Color3.fromRGB(255, 100, 60)
		elseif vfx == "cone" then
			return Color3.fromRGB(255, 140, 40)
		end
		return Color3.fromRGB(200, 220, 255)
	end

	if vfx == "firework" then
		return Color3.fromRGB(255, 80, 160)
	elseif vfx == "foam" then
		return Color3.fromRGB(220, 240, 255)
	elseif vfx == "hose" then
		return Color3.fromRGB(80, 60, 40)
	elseif vfx == "net" then
		return Color3.fromRGB(180, 220, 160)
	elseif vfx == "balloon" then
		return Color3.fromRGB(80, 160, 255)
	end
	return Color3.fromRGB(255, 200, 80)
end

function CombatService.SpawnProjectile(opts: ProjectileOpts)
	local EnemyService = enemyProvider
	assert(EnemyService, "Enemy provider must be bound before spawning attacks")
	local generation = EnemyService.GetGeneration()
	local kind = opts.kind
	local facing = if opts.facing >= 0 then 1 else -1
	local speed = if kind == "thrown" then Constants.PROJECTILE_SPEED_THROWN else Constants.PROJECTILE_SPEED_RANGED
	local maxDist = math.clamp(opts.range, 1, 60)
	local lifetime = maxDist / speed + 0.35
	local part = Instance.new("Part")
	part.Name = if kind == "thrown" then "FM_ThrownProj" else "FM_RangedProj"
	part.Anchored, part.CanCollide, part.CanQuery, part.CanTouch = true, false, false, false
	part.Material, part.Color = Enum.Material.Neon, projectileColor(opts.vfx, kind)
	part.Size = Vector3.new(1.2, 0.55, 0.55)
	local y0 = opts.origin.Y
	local function position(distance: number): Vector3
		local u = math.clamp(distance / maxDist, 0, 1)
		local y = y0
		if kind == "thrown" then y += math.sin(u * math.pi) * Constants.THROW_ARC_HEIGHT - u * u * 2.8 end
		return Vector3.new(opts.origin.X + facing * distance, y, opts.origin.Z)
	end
	part.Position = position(0)
	part.Parent = Workspace:FindFirstChild("GameWorld") or Workspace
	local hitSet: { [Model]: boolean } = {}
	local pierceLeft = if kind == "ranged" then Constants.RANGED_PIERCE_HITS else 1
	local traveled = 0
	local t0 = os.clock()
	local conn: RBXScriptConnection?
	local function finish()
		part:Destroy()
		if conn then conn:Disconnect() end
	end
	conn = RunService.Heartbeat:Connect(function(dt)
		if not part.Parent or generation ~= EnemyService.GetGeneration() or (opts.isCurrent and not opts.isCurrent()) then finish(); return end
		local nextDistance = math.min(maxDist, traveled + speed * dt)
		-- Subdivide curved trajectories, then sweep each segment. Hitches cannot tunnel
		-- through a target or reverse the near-to-far order of piercing hits.
		while traveled < nextDistance do
			local step = math.min(nextDistance, traveled + 2)
			local a, b = position(traveled), position(step)
			local obstacle = Workspace:Raycast(a, b - a, obstacleParams(opts.attacker))
			local limit = if obstacle then obstacle.Distance / math.max(0.001, (b - a).Magnitude) else 1
			local candidates: { { model: Model, fraction: number } } = {}
			for _, model in EnemyService.GetAlive() do
				local root = model.PrimaryPart
				if root and not hitSet[model] and EnemyService.CanDamage(model) then
					local la, lb = root.CFrame:PointToObjectSpace(a), root.CFrame:PointToObjectSpace(b)
					local h = root.Size * 0.5 + Vector3.new(0.6, 0.3, 0.3)
					local fraction = Geometry.SegmentBox(la.X, la.Y, la.Z, lb.X, lb.Y, lb.Z, 0, 0, 0, h.X, h.Y, h.Z)
					if fraction and fraction <= limit then table.insert(candidates, { model = model, fraction = fraction }) end
				end
			end
			table.sort(candidates, function(left, right) return left.fraction < right.fraction end)
			for _, candidate in candidates do
				hitSet[candidate.model] = true
				opts.onHit(candidate.model, opts.damage, opts.knockback, opts.heavy == true)
				pierceLeft -= 1
				if pierceLeft <= 0 or generation ~= EnemyService.GetGeneration() or (opts.isCurrent and not opts.isCurrent()) then finish(); return end
			end
			if obstacle then finish(); return end
			traveled = step
			part.Position = b
		end
		if traveled >= maxDist or os.clock() - t0 > lifetime then finish() end
	end)
	Debris:AddItem(part, lifetime + 0.5)
end

function CombatService.SpawnLingeringHitbox(opts: {
	origin: Vector3,
	facing: number,
	duration: number,
	radius: number,
	damage: number,
	knockback: number,
	tick: number,
	attacker: Player,
	onHit: (model: Model, damage: number, knock: number, heavy: boolean) -> (),
	color: Color3?,
	height: number?,
	isCurrent: (() -> boolean)?,
})
	local EnemyService = enemyProvider
	assert(EnemyService, "Enemy provider must be bound before spawning attacks")
	local generation = EnemyService.GetGeneration()
	local part = Instance.new("Part")
	part.Name = "FM_SummonCoil"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Material = Enum.Material.ForceField
	part.Color = opts.color or Color3.fromRGB(120, 255, 140)
	part.Size = Vector3.new(opts.radius * 2, opts.height or 3, 4)
	part.Transparency = 0.35
	local x = opts.origin.X + opts.facing * 6
	part.CFrame = CFrame.new(x, opts.origin.Y, Constants.LANE_Z)
	part.Parent = Workspace:FindFirstChild("GameWorld") or Workspace

	local deadline = os.clock() + opts.duration
	local lastTick = 0
	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		if not part.Parent or os.clock() > deadline or generation ~= EnemyService.GetGeneration() or (opts.isCurrent and not opts.isCurrent()) then
			if part.Parent then
				part:Destroy()
			end
			if conn then
				conn:Disconnect()
			end
			return
		end
		if os.clock() - lastTick < opts.tick then
			return
		end
		lastTick = os.clock()
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and CombatService.InHitVolume(part.Position, opts.facing, root, part.Size.X * 0.5, part.Size.Y * 0.5, opts.attacker, true) then
				opts.onHit(model, opts.damage, opts.knockback, false)
			end
		end
	end)
	Debris:AddItem(part, opts.duration + 0.2)
end

Players.PlayerRemoving:Connect(function(player)
	CombatService.ResetPlayer(player)
end)

return CombatService
