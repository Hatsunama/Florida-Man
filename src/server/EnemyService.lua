--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared:WaitForChild("Enemies"))
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local EnemyFactory = require(script.Parent:WaitForChild("EnemyFactory"))

local EnemyService = {}
EnemyService._alive = {} :: { [Model]: boolean }
EnemyService._onKilled = nil :: ((Player, string, Model) -> ())?
EnemyService._onTurtleRescued = nil :: ((Player, Model) -> ())?

function EnemyService.SetCallbacks(onKilled, onTurtleRescued)
	EnemyService._onKilled = onKilled
	EnemyService._onTurtleRescued = onTurtleRescued
end

function EnemyService.Clear()
	for model in EnemyService._alive do
		if model and model.Parent then
			model:Destroy()
		end
	end
	table.clear(EnemyService._alive)
end

function EnemyService.Spawn(enemyId: string, x: number): Model?
	local def = Enemies.Get(enemyId)
	if not def then
		warn("Unknown enemy", enemyId)
		return nil
	end
	local pos = Vector3.new(x, def.size.Y * 0.5 + 0.5, Constants.LANE_Z)
	local model = EnemyFactory.Build(def, pos)
	model.Parent = Workspace:WaitForChild("GameWorld")
	EnemyService._alive[model] = true
	return model
end

function EnemyService.SpawnTurtle(x: number): Model?
	local model = EnemyService.Spawn("RescueTurtle", x)
	if model then
		model:SetAttribute("Rescued", false)
	end
	return model
end

local function updateNameplate(model: Model)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = model.PrimaryPart
	if not hum or not root then
		return
	end
	local bb = root:FindFirstChild("NamePlate")
	if bb then
		local hp = bb:FindFirstChild("HP")
		if hp and hp:IsA("TextLabel") then
			hp.Text = string.format("%d / %d", math.max(0, math.floor(hum.Health)), math.floor(hum.MaxHealth))
		end
	end
end

function EnemyService.ApplyDamage(model: Model, amount: number, attacker: Player?, knockback: number?): boolean
	if not EnemyService._alive[model] then
		return false
	end
	if model:GetAttribute("IsAlly") then
		return false
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	hum.Health = math.max(0, hum.Health - amount)
	updateNameplate(model)
	EnemyFactory.HitFlash(model)

	local root = model.PrimaryPart
	if root then
		Remotes.Get("DamageNumber"):FireAllClients(root.Position, math.floor(amount), false)
		Remotes.Get("CombatEvent"):FireAllClients({ kind = "shake", amount = if amount > 20 then 0.7 else 0.35 })
		-- knockback along lane only
		local kb = knockback or 4
		if attacker and attacker.Character then
			local hrp = attacker.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local dir = if root.Position.X >= hrp.Position.X then 1 else -1
				local np = root.Position + Vector3.new(dir * kb, 0, 0)
				np = Vector3.new(np.X, root.Position.Y, Constants.LANE_Z)
				model:PivotTo(CFrame.new(np) * (root.CFrame - root.Position))
			end
		end
	end

	if hum.Health <= 0 then
		EnemyService._Poof(model, attacker)
		return true
	end
	return false
end

function EnemyService._Poof(model: Model, attacker: Player?)
	EnemyService._alive[model] = nil
	local enemyId = model:GetAttribute("EnemyId") :: string
	local root = model.PrimaryPart
	local pos = if root then root.Position else Vector3.zero
	local color = if root then root.Color else Color3.new(1, 1, 1)
	EnemyFactory.DeathPoof(pos, color)
	model:Destroy()
	if attacker and EnemyService._onKilled then
		EnemyService._onKilled(attacker, enemyId, model)
	end
end

function EnemyService.TryRescue(player: Player, model: Model): boolean
	if not model:GetAttribute("IsAlly") then
		return false
	end
	if model:GetAttribute("Rescued") then
		return false
	end
	model:SetAttribute("Rescued", true)
	local root = model.PrimaryPart
	if root then
		EnemyFactory.DeathPoof(root.Position, Color3.fromRGB(255, 120, 160))
	end
	EnemyService._alive[model] = nil
	model:Destroy()
	if EnemyService._onTurtleRescued then
		EnemyService._onTurtleRescued(player, model)
	end
	return true
end

function EnemyService.GetAlive(): { Model }
	local out = {}
	for m in EnemyService._alive do
		if m.Parent then
			table.insert(out, m)
		end
	end
	return out
end

function EnemyService.CountHostile(): number
	local n = 0
	for m in EnemyService._alive do
		if m.Parent and not m:GetAttribute("IsAlly") then
			n += 1
		end
	end
	return n
end

local lastAttack: { [Model]: number } = {}
local telegraphing: { [Model]: boolean } = {}
local chargeDir: { [Model]: number } = {}
local burrowCD: { [Model]: number } = {}

local function spawnSummon(near: Model)
	local root = near.PrimaryPart
	if not root then
		return
	end
	EnemyService.Spawn("Cottonmouth", root.Position.X + 6)
end

local function leavePuddle(pos: Vector3)
	local puddle = Instance.new("Part")
	puddle.Name = "OilSlick"
	puddle.Anchored = true
	puddle.CanCollide = false
	puddle.Size = Vector3.new(8, 0.25, 5)
	puddle.Color = Color3.fromRGB(20, 25, 20)
	puddle.Material = Enum.Material.Mud
	puddle.Transparency = 0.25
	puddle.CFrame = CFrame.new(pos.X, 0.2, Constants.LANE_Z)
	puddle.Parent = Workspace:FindFirstChild("GameWorld") or Workspace
	Debris:AddItem(puddle, 6)
end

function EnemyService.StartAI()
	RunService.Heartbeat:Connect(function(dt)
		for model in EnemyService._alive do
			if not model.Parent then
				continue
			end
			local root = model.PrimaryPart
			local hum = model:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.Health <= 0 then
				continue
			end

			if model:GetAttribute("IsAlly") then
				-- turtles idle bob
				EnemyFactory.Animate(model, dt, false, false)
				continue
			end
			if telegraphing[model] then
				EnemyFactory.Animate(model, dt, false, true)
				continue
			end

			local nearest: Player? = nil
			local nearestDist = 1e9
			local targetPos = root.Position
			for _, plr in Players:GetPlayers() do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					local d = (hrp.Position - root.Position).Magnitude
					if d < nearestDist then
						nearestDist = d
						nearest = plr
						targetPos = hrp.Position
					end
				end
			end
			if not nearest then
				continue
			end

			local behavior = (model:GetAttribute("Behavior") :: string) or "chase"
			local speed = (model:GetAttribute("Speed") :: number) or 8
			local facing = if targetPos.X >= root.Position.X then 1 else -1
			model:SetAttribute("Facing", facing)

			local moving = false
			local attackRange = if model:GetAttribute("IsBoss") then 14 elseif behavior == "spitter" or behavior == "firearc" then 16 else 8

			if behavior == "charger" then
				local cd = chargeDir[model]
				if not cd or nearestDist > 20 then
					chargeDir[model] = facing
					cd = facing
				end
				if nearestDist > 5 then
					moving = true
					local newPos = root.Position + Vector3.new(cd * speed * 1.6 * dt, 0, 0)
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
					model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, if cd > 0 then 0 else math.pi, 0))
				end
			elseif behavior == "burrower" then
				local now = os.clock()
				local last = burrowCD[model] or 0
				if now - last > 3 and nearestDist < 18 then
					burrowCD[model] = now
					-- blink closer
					local nx = targetPos.X - facing * 5
					model:PivotTo(CFrame.new(nx, root.Position.Y, Constants.LANE_Z))
					root.Transparency = 0.7
					task.delay(0.25, function()
						if root.Parent then
							root.Transparency = 0
						end
					end)
				elseif nearestDist > attackRange then
					moving = true
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * dt
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
					model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, if facing > 0 then 0 else math.pi, 0))
				end
			elseif behavior == "hopper" then
				if nearestDist > attackRange then
					moving = true
					local hop = math.abs(math.sin(os.clock() * 6)) * 1.5
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * 1.2 * dt
					newPos = Vector3.new(newPos.X, (model:GetAttribute("BaseY") :: number?) or root.Position.Y + hop * 0.02, Constants.LANE_Z)
					if not model:GetAttribute("BaseY") then
						model:SetAttribute("BaseY", root.Position.Y)
					end
					local by = model:GetAttribute("BaseY") :: number
					newPos = Vector3.new(newPos.X, by + hop, Constants.LANE_Z)
					model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, if facing > 0 then 0 else math.pi, 0))
				end
			elseif behavior == "scuttle" then
				-- sideways crab approach
				if nearestDist > attackRange then
					moving = true
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * dt
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
					-- face camera-ish with sideways swagger
					model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, if facing > 0 then -math.pi / 2 else math.pi / 2, 0))
				end
			else
				if nearestDist > attackRange then
					moving = true
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * dt
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
					model:PivotTo(CFrame.new(newPos) * CFrame.Angles(0, if facing > 0 then 0 else math.pi, 0))
				end
			end

			EnemyFactory.Animate(model, dt, moving, false)

			if nearestDist <= attackRange then
				local now = os.clock()
				local cd = (model:GetAttribute("AttackCooldown") :: number) or 1.5
				local last = lastAttack[model] or 0
				if now - last >= cd then
					lastAttack[model] = now
					telegraphing[model] = true
					task.spawn(function()
						EnemyService._TelegraphAttack(model, nearest :: Player, behavior)
						telegraphing[model] = nil
					end)
				end
			end
		end
	end)
end

function EnemyService._TelegraphAttack(model: Model, target: Player, behavior: string)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local tele = (model:GetAttribute("Telegraph") :: number) or 0.5
	local dmg = (model:GetAttribute("Damage") :: number) or 8
	local facing = (model:GetAttribute("Facing") :: number) or 1
	local width = if model:GetAttribute("IsBoss") then 16 elseif behavior == "firearc" then 14 else 9

	local zone = Instance.new("Part")
	zone.Name = "Telegraph"
	zone.Anchored = true
	zone.CanCollide = false
	zone.Material = Enum.Material.Neon
	zone.Color = if behavior == "firearc" then Color3.fromRGB(255, 140, 40) else Color3.fromRGB(255, 60, 60)
	zone.Transparency = 0.55
	zone.Size = Vector3.new(width, 0.4, 6)
	zone.CFrame = CFrame.new(root.Position + Vector3.new(facing * width * 0.5, -root.Size.Y * 0.35, 0))
	zone.Parent = Workspace
	Debris:AddItem(zone, tele + 0.15)

	-- claw snap / attack telegraph anim (pulse so Motor6Ds actually read)
	local elapsed = 0
	while elapsed < tele do
		local step = task.wait(0.05)
		elapsed += step
		if not model.Parent then
			return
		end
		EnemyFactory.Animate(model, step, false, true)
	end
	if not model.Parent or not EnemyService._alive[model] then
		return
	end

	if behavior == "summoner" then
		spawnSummon(model)
	elseif behavior == "puddle" then
		leavePuddle(root.Position + Vector3.new(facing * 4, 0, 0))
	end

	local char = target.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		if char:GetAttribute("IFrame") then
			return
		end
		local inZone = math.abs(hrp.Position.X - zone.Position.X) < width * 0.55
			and math.abs(hrp.Position.Z - Constants.LANE_Z) < 5
		if inZone then
			Remotes.Get("CombatEvent"):FireClient(target, { kind = "hit", damage = dmg, source = model:GetAttribute("EnemyId") })
			target:SetAttribute("PendingDamage", dmg)
			target:SetAttribute("PendingDamageAt", os.clock())
		end
	end
end

return EnemyService
