--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CombatService = {}

export type MovesetHit = {
	recovery: number,
	rangeMul: number,
	knockMul: number,
	dmgMul: number,
	label: string,
}

local iframesUntil: { [Player]: number } = {}
local attackReadyAt: { [Player]: number } = {}
local skillReadyAt: { [Player]: number } = {}
local swapReadyAt: { [Player]: number } = {}
local shieldAbsorb: { [Player]: number } = {}

local ATTACK_RECOVERY = Constants.ATTACK_RECOVERY
local POINT_BLANK = 2.5

local MOVESETS: { [string]: { MovesetHit } } = {
	BeachBurnout = {
		{ recovery = 0.16, rangeMul = 1.00, knockMul = 0.95, dmgMul = 0.95, label = "jab" },
		{ recovery = 0.18, rangeMul = 1.08, knockMul = 1.05, dmgMul = 1.05, label = "cross" },
		{ recovery = 0.26, rangeMul = 1.22, knockMul = 1.35, dmgMul = 1.38, label = "shuffle" },
	},
	CrabKing = {
		{ recovery = 0.22, rangeMul = 0.92, knockMul = 1.25, dmgMul = 1.12, label = "pinch" },
		{ recovery = 0.24, rangeMul = 1.00, knockMul = 1.40, dmgMul = 1.18, label = "sideways" },
		{ recovery = 0.34, rangeMul = 1.18, knockMul = 1.85, dmgMul = 1.55, label = "royal" },
	},
	GatorHauler = {
		{ recovery = 0.24, rangeMul = 0.95, knockMul = 1.30, dmgMul = 1.15, label = "clamp" },
		{ recovery = 0.26, rangeMul = 1.05, knockMul = 1.45, dmgMul = 1.22, label = "drag" },
		{ recovery = 0.36, rangeMul = 1.20, knockMul = 1.90, dmgMul = 1.50, label = "slam" },
	},
	SnakeCharmer = {
		{ recovery = 0.14, rangeMul = 1.05, knockMul = 0.85, dmgMul = 0.90, label = "flick" },
		{ recovery = 0.16, rangeMul = 1.12, knockMul = 0.95, dmgMul = 1.00, label = "coil" },
		{ recovery = 0.22, rangeMul = 1.28, knockMul = 1.15, dmgMul = 1.28, label = "strike" },
	},
	GolfCartBandit = {
		{ recovery = 0.12, rangeMul = 0.95, knockMul = 1.10, dmgMul = 0.88, label = "tap" },
		{ recovery = 0.14, rangeMul = 1.00, knockMul = 1.20, dmgMul = 0.95, label = "scrape" },
		{ recovery = 0.20, rangeMul = 1.15, knockMul = 1.55, dmgMul = 1.25, label = "bumper" },
	},
	FireworksEnthusiast = {
		{ recovery = 0.18, rangeMul = 1.00, knockMul = 0.90, dmgMul = 1.00, label = "spark" },
		{ recovery = 0.20, rangeMul = 1.10, knockMul = 1.00, dmgMul = 1.10, label = "roman" },
		{ recovery = 0.30, rangeMul = 1.25, knockMul = 1.40, dmgMul = 1.42, label = "finale" },
	},
	LizardBreath = {
		{ recovery = 0.20, rangeMul = 1.05, knockMul = 1.00, dmgMul = 1.08, label = "hiss" },
		{ recovery = 0.22, rangeMul = 1.12, knockMul = 1.10, dmgMul = 1.15, label = "exhale" },
		{ recovery = 0.32, rangeMul = 1.30, knockMul = 1.35, dmgMul = 1.45, label = "burn" },
	},
	TurtlePaladin = {
		{ recovery = 0.20, rangeMul = 0.95, knockMul = 1.15, dmgMul = 1.05, label = "shell" },
		{ recovery = 0.22, rangeMul = 1.00, knockMul = 1.25, dmgMul = 1.12, label = "smite" },
		{ recovery = 0.30, rangeMul = 1.15, knockMul = 1.50, dmgMul = 1.40, label = "sanctuary" },
	},
}

local DEFAULT_MOVESET: { MovesetHit } = {
	{ recovery = 0.20, rangeMul = 1.0, knockMul = 1.0, dmgMul = 1.0, label = "hit1" },
	{ recovery = 0.22, rangeMul = 1.05, knockMul = 1.1, dmgMul = 1.1, label = "hit2" },
	{ recovery = 0.28, rangeMul = 1.2, knockMul = 1.35, dmgMul = 1.35, label = "hit3" },
}

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

function CombatService.MarkAttack(player: Player, recovery: number?)
	attackReadyAt[player] = os.clock() + (recovery or ATTACK_RECOVERY)
end

function CombatService.CanSkill(player: Player): boolean
	local t = skillReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return true
end

function CombatService.MarkSkill(player: Player, cooldown: number)
	skillReadyAt[player] = os.clock() + math.max(0, cooldown)
end

function CombatService.CanSwap(player: Player): boolean
	local t = swapReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return true
end

function CombatService.MarkSwap(player: Player, cooldown: number)
	swapReadyAt[player] = os.clock() + math.max(0, cooldown)
end

function CombatService.GetMovesetHit(personaId: string, comboIndex: number): MovesetHit
	local set = MOVESETS[personaId] or DEFAULT_MOVESET
	local idx = math.clamp(comboIndex, 1, 3)
	return set[idx] or DEFAULT_MOVESET[idx]
end

function CombatService.LaneKnockback(originX: number, targetPos: Vector3, strength: number): Vector3
	local dir = if targetPos.X >= originX then 1 else -1
	local kb = math.clamp(strength or Constants.KNOCKBACK_BASE, 0, 24)
	return Vector3.new(targetPos.X + dir * kb, targetPos.Y, Constants.LANE_Z)
end

function CombatService.InLaneMelee(attackerX: number, facing: number, targetX: number, range: number): boolean
	local dx = targetX - attackerX
	local adx = math.abs(dx)
	if adx <= POINT_BLANK then
		return true
	end
	if adx > range then
		return false
	end
	return math.sign(dx + 0.001) == facing
end

function CombatService.InLaneRange(attackerX: number, facing: number, targetX: number, range: number, requireFacing: boolean?): boolean
	if requireFacing == false then
		return math.abs(targetX - attackerX) <= range
	end
	return CombatService.InLaneMelee(attackerX, facing, targetX, range)
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

	local np = root.Position + Vector3.new(dir * kb, lift, 0)
	np = Vector3.new(np.X, math.max(root.Position.Y, np.Y), Constants.LANE_Z)
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
	local kind = opts.kind
	local facing = if opts.facing >= 0 then 1 else -1
	local speed = if kind == "thrown" then Constants.PROJECTILE_SPEED_THROWN else Constants.PROJECTILE_SPEED_RANGED
	local maxDist = math.clamp(opts.range, 8, 40)
	local lifetime = maxDist / speed + 0.35

	local part = Instance.new("Part")
	part.Name = if kind == "thrown" then "FM_ThrownProj" else "FM_RangedProj"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.Material = Enum.Material.Neon
	part.Color = projectileColor(opts.vfx, kind)
	if kind == "thrown" then
		part.Size = Vector3.new(1.4, 0.55, 0.55)
		part.Shape = Enum.PartType.Block
	else
		part.Size = Vector3.new(1.8, 0.45, 0.45)
		part.Shape = Enum.PartType.Block
	end
	local y0 = opts.origin.Y + (if kind == "thrown" then 2.2 else 1.4)
	part.CFrame = CFrame.new(opts.origin.X, y0, Constants.LANE_Z)
	part.Transparency = 0.05
	part.Parent = Workspace

	local hitSet: { [Model]: boolean } = {}
	local traveled = 0
	local t0 = os.clock()
	local x0 = opts.origin.X
	local conn: RBXScriptConnection?

	conn = RunService.Heartbeat:Connect(function(dt)
		if not part.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		traveled += speed * dt
		local x = x0 + facing * traveled
		local y = y0
		if kind == "thrown" then

			local u = math.clamp(traveled / maxDist, 0, 1)
			y = y0 + math.sin(u * math.pi) * 6 - u * u * 2.5
		end
		part.CFrame = CFrame.new(x, y, Constants.LANE_Z)

		local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
		for _, model in EnemyService.GetAlive() do
			if hitSet[model] then
				continue
			end
			if opts.filterAlly ~= false and model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			if math.abs(root.Position.Z - Constants.LANE_Z) > 6 then
				continue
			end
			local dx = math.abs(root.Position.X - x)
			local dy = math.abs(root.Position.Y - y)
			if dx < 3.2 and dy < 4.5 then
				hitSet[model] = true
				opts.onHit(model, opts.damage, opts.knockback, opts.heavy == true)
				if kind == "ranged" then

				end
				if kind == "thrown" then
					part:Destroy()
					if conn then
						conn:Disconnect()
					end
					return
				end
			end
		end

		if traveled >= maxDist or (os.clock() - t0) > lifetime then
			part:Destroy()
			if conn then
				conn:Disconnect()
			end
		end
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
})
	local part = Instance.new("Part")
	part.Name = "FM_SummonCoil"
	part.Anchored = true
	part.CanCollide = false
	part.Material = Enum.Material.ForceField
	part.Color = opts.color or Color3.fromRGB(120, 255, 140)
	part.Size = Vector3.new(opts.radius * 2, 3, 4)
	part.Transparency = 0.35
	local x = opts.origin.X + opts.facing * 6
	part.CFrame = CFrame.new(x, opts.origin.Y + 1, Constants.LANE_Z)
	part.Parent = Workspace

	local deadline = os.clock() + opts.duration
	local lastTick = 0
	local conn: RBXScriptConnection?
	conn = RunService.Heartbeat:Connect(function()
		if not part.Parent or os.clock() > deadline then
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
		local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and math.abs(root.Position.X - part.Position.X) < opts.radius and math.abs(root.Position.Z - Constants.LANE_Z) < 6 then
				opts.onHit(model, opts.damage, opts.knockback, false)
			end
		end
	end)
	Debris:AddItem(part, opts.duration + 0.2)
end

Players.PlayerRemoving:Connect(function(player)
	iframesUntil[player] = nil
	attackReadyAt[player] = nil
	skillReadyAt[player] = nil
	swapReadyAt[player] = nil
	shieldAbsorb[player] = nil
end)

return CombatService
