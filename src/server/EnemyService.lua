--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared:WaitForChild("Enemies"))
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))

local EnemyService = {}
EnemyService._alive = {} :: { [Model]: boolean }
EnemyService._onKilled = nil :: ((Player, string, Model) -> ())?
EnemyService._onTurtleRescued = nil :: ((Player, Model) -> ())?

local function makeEnemyModel(def: any, position: Vector3): Model
	local model = Instance.new("Model")
	model.Name = def.id

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = def.size
	root.Color = def.color
	root.Material = Enum.Material.SmoothPlastic
	root.Anchored = true
	root.CanCollide = true
	root.CFrame = CFrame.new(position)
	root.Parent = model

	-- Accent detail for distinctive silhouettes
	local accent = Instance.new("Part")
	accent.Name = "Accent"
	accent.Anchored = true
	accent.CanCollide = false
	accent.Material = Enum.Material.Neon
	accent.Color = def.accent
	accent.Parent = model

	if def.shape == "crab" then
		accent.Size = Vector3.new(def.size.X * 1.4, 0.6, 0.6)
		accent.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.3, 0)
		-- claws
		for _, side in { -1, 1 } do
			local claw = Instance.new("Part")
			claw.Name = "Claw"
			claw.Size = Vector3.new(1.2, 1.2, 2)
			claw.Color = def.color
			claw.Anchored = true
			claw.CanCollide = false
			claw.CFrame = root.CFrame * CFrame.new(side * def.size.X * 0.7, 0, -def.size.Z * 0.4)
			claw.Parent = model
		end
	elseif def.shape == "gator" then
		accent.Size = Vector3.new(def.size.X * 0.5, 0.5, def.size.Z * 0.8)
		accent.CFrame = root.CFrame * CFrame.new(def.size.X * 0.35, 0.2, 0)
		-- radio collar for oil / drive-thru gators
		if def.id == "OilGator" or def.id == "DriveThruGator" then
			local collar = Instance.new("Part")
			collar.Name = "RadioCollar"
			collar.Size = Vector3.new(1.2, 0.4, 1.2)
			collar.Color = Color3.fromRGB(255, 200, 40)
			collar.Material = Enum.Material.Neon
			collar.Anchored = true
			collar.CanCollide = false
			collar.CFrame = root.CFrame * CFrame.new(-def.size.X * 0.25, def.size.Y * 0.35, 0)
			collar.Parent = model
			local bb = Instance.new("BillboardGui")
			bb.Size = UDim2.fromOffset(80, 20)
			bb.StudsOffset = Vector3.new(0, 3, 0)
			bb.Parent = collar
			local t = Instance.new("TextLabel")
			t.Size = UDim2.fromScale(1, 1)
			t.BackgroundTransparency = 1
			t.Text = "📡 GULFGULP"
			t.TextColor3 = Color3.fromRGB(255, 220, 80)
			t.TextScaled = true
			t.Font = Enum.Font.GothamBold
			t.Parent = bb
		end
		-- sludge armor tint
		if def.id == "OilGator" then
			root.Material = Enum.Material.Mud
		end
	elseif def.shape == "lizard" then
		accent.Size = Vector3.new(1.5, 1.5, 1.5)
		accent.Shape = Enum.PartType.Ball
		accent.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.6, -def.size.Z * 0.2)
		-- flame crest
		local crest = Instance.new("Part")
		crest.Name = "FlameCrest"
		crest.Size = Vector3.new(0.6, 2, 2)
		crest.Color = Color3.fromRGB(255, 140, 20)
		crest.Material = Enum.Material.Neon
		crest.Anchored = true
		crest.CanCollide = false
		crest.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.7, 0)
		crest.Parent = model
	elseif def.shape == "snake" then
		accent.Size = Vector3.new(def.size.X * 0.8, 0.4, 0.4)
		accent.CFrame = root.CFrame * CFrame.new(0, 0.3, 0)
	elseif def.shape == "slime" then
		root.Shape = Enum.PartType.Ball
		accent.Size = Vector3.new(1, 1, 1)
		accent.Shape = Enum.PartType.Ball
		accent.CFrame = root.CFrame * CFrame.new(0.5, 0.5, 0.5)
	elseif def.shape == "boss" then
		accent.Size = Vector3.new(4, 4, 2)
		accent.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.2, -1)
		local crown = Instance.new("Part")
		crown.Name = "Crown"
		crown.Size = Vector3.new(6, 2, 2)
		crown.Color = Color3.fromRGB(255, 180, 0)
		crown.Material = Enum.Material.Neon
		crown.Anchored = true
		crown.CanCollide = false
		crown.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.55, 0)
		crown.Parent = model
	else
		accent.Size = Vector3.new(1.2, 1.2, 1.2)
		accent.CFrame = root.CFrame * CFrame.new(0, def.size.Y * 0.55, -0.5)
	end

	local hum = Instance.new("Humanoid")
	hum.MaxHealth = def.hp
	hum.Health = def.hp
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.Parent = model

	model.PrimaryPart = root
	model:SetAttribute("EnemyId", def.id)
	model:SetAttribute("IsAlly", def.isAlly)
	model:SetAttribute("IsBoss", def.isBoss)
	model:SetAttribute("IsMiniboss", def.isMiniboss)
	model:SetAttribute("Damage", def.damage)
	model:SetAttribute("Speed", def.speed)
	model:SetAttribute("Telegraph", def.telegraph)
	model:SetAttribute("AttackCooldown", def.attackCooldown)
	model:SetAttribute("Facing", 1)

	-- Nameplate
	local bb = Instance.new("BillboardGui")
	bb.Name = "NamePlate"
	bb.Size = UDim2.fromOffset(160, 36)
	bb.StudsOffset = Vector3.new(0, def.size.Y * 0.5 + 2, 0)
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
	hpLbl.Text = string.format("%d / %d", def.hp, def.hp)
	hpLbl.TextColor3 = Color3.fromRGB(200, 255, 200)
	hpLbl.TextScaled = true
	hpLbl.Font = Enum.Font.Gotham
	hpLbl.Parent = bb

	model.Parent = Workspace:WaitForChild("GameWorld")
	return model
end

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
	local model = makeEnemyModel(def, pos)
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

function EnemyService.ApplyDamage(model: Model, amount: number, attacker: Player?): boolean
	if not EnemyService._alive[model] then
		return false
	end
	if model:GetAttribute("IsAlly") then
		return false -- never harm turtles
	end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return false
	end
	hum.Health = math.max(0, hum.Health - amount)
	updateNameplate(model)

	-- flash
	local root = model.PrimaryPart
	if root then
		local old = root.Color
		root.Color = Color3.new(1, 1, 1)
		task.delay(0.08, function()
			if root.Parent then
				root.Color = old
			end
		end)
		Remotes.Get("DamageNumber"):FireAllClients(root.Position, math.floor(amount), false)
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

	-- cartoon poof
	local puff = Instance.new("Part")
	puff.Shape = Enum.PartType.Ball
	puff.Size = Vector3.new(2, 2, 2)
	puff.Color = Color3.fromRGB(255, 255, 255)
	puff.Material = Enum.Material.Neon
	puff.Anchored = true
	puff.CanCollide = false
	puff.CFrame = CFrame.new(pos)
	puff.Parent = Workspace
	TweenService:Create(puff, TweenInfo.new(0.35), { Size = Vector3.new(8, 8, 8), Transparency = 1 }):Play()
	Debris:AddItem(puff, 0.4)

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
		local heart = Instance.new("Part")
		heart.Shape = Enum.PartType.Ball
		heart.Size = Vector3.new(1, 1, 1)
		heart.Color = Color3.fromRGB(255, 100, 140)
		heart.Material = Enum.Material.Neon
		heart.Anchored = true
		heart.CanCollide = false
		heart.CFrame = root.CFrame
		heart.Parent = Workspace
		TweenService:Create(heart, TweenInfo.new(0.6), {
			CFrame = root.CFrame + Vector3.new(0, 6, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(heart, 0.7)
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

function EnemyService.StartAI()
	RunService.Heartbeat:Connect(function(dt)
		for model in EnemyService._alive do
			if not model.Parent or model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			local hum = model:FindFirstChildOfClass("Humanoid")
			if not root or not hum or hum.Health <= 0 then
				continue
			end
			if telegraphing[model] then
				continue
			end

			-- find nearest player character
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

			local speed = (model:GetAttribute("Speed") :: number) or 8
			local facing = if targetPos.X >= root.Position.X then 1 else -1
			model:SetAttribute("Facing", facing)

			local attackRange = if model:GetAttribute("IsBoss") then 14 else 8
			if nearestDist > attackRange then
				local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
				local newPos = root.Position + dir * speed * dt
				newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
				local cf = CFrame.new(newPos) * CFrame.Angles(0, if facing > 0 then 0 else math.pi, 0)
				model:PivotTo(cf)
			else
				local now = os.clock()
				local cd = (model:GetAttribute("AttackCooldown") :: number) or 1.5
				local last = lastAttack[model] or 0
				if now - last >= cd then
					lastAttack[model] = now
					telegraphing[model] = true
					task.spawn(function()
						EnemyService._TelegraphAttack(model, nearest :: Player)
						telegraphing[model] = nil
					end)
				end
			end
		end
	end)
end

function EnemyService._TelegraphAttack(model: Model, target: Player)
	local root = model.PrimaryPart
	if not root then
		return
	end
	local tele = (model:GetAttribute("Telegraph") :: number) or 0.5
	local dmg = (model:GetAttribute("Damage") :: number) or 8

	-- red telegraph zone
	local zone = Instance.new("Part")
	zone.Name = "Telegraph"
	zone.Anchored = true
	zone.CanCollide = false
	zone.Material = Enum.Material.Neon
	zone.Color = Color3.fromRGB(255, 60, 60)
	zone.Transparency = 0.55
	local facing = (model:GetAttribute("Facing") :: number) or 1
	local width = if model:GetAttribute("IsBoss") then 16 else 9
	zone.Size = Vector3.new(width, 0.4, 6)
	zone.CFrame = CFrame.new(root.Position + Vector3.new(facing * width * 0.5, -root.Size.Y * 0.45, 0))
	zone.Parent = Workspace
	Debris:AddItem(zone, tele + 0.15)

	task.wait(tele)
	if not model.Parent or not EnemyService._alive[model] then
		return
	end

	-- hit check — server authoritative
	local char = target.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		local invuln = char:GetAttribute("IFrame")
		if invuln then
			return
		end
		local inZone = math.abs(hrp.Position.X - zone.Position.X) < width * 0.55
			and math.abs(hrp.Position.Z - Constants.LANE_Z) < 5
		if inZone then
			-- GameService applies damage via callback attribute event
			Remotes.Get("CombatEvent"):FireClient(target, { kind = "hit", damage = dmg, source = model:GetAttribute("EnemyId") })
			-- also set attribute for server GameService listener
			target:SetAttribute("PendingDamage", dmg)
			target:SetAttribute("PendingDamageAt", os.clock())
		end
	end
end

return EnemyService
