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
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local Balance = require(Shared:WaitForChild("Balance"))
local EnemyFactory = require(script.Parent:WaitForChild("EnemyFactory"))

local EnemyService = {}
EnemyService._alive = {} :: { [Model]: boolean }
EnemyService._onKilled = nil :: ((Player, string, Model) -> ())?
EnemyService._onTurtleRescued = nil :: ((Player, Model) -> ())?
EnemyService._stageIndex = 1

function EnemyService.SetStageContext(stageIndex: number)
	EnemyService._stageIndex = stageIndex or 1
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
	local model = EnemyFactory.Build(def, pos)
	-- Apply stage scaling (allies/turtles skip)
	if not def.isAlly then
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			local hpM = Balance.EnemyHpMult(EnemyService._stageIndex)
			local dmgM = Balance.EnemyDmgMult(EnemyService._stageIndex)
			hum.MaxHealth = math.floor(def.hp * hpM)
			hum.Health = hum.MaxHealth
			local scaled = math.floor(def.damage * dmgM + 0.5)
			model:SetAttribute("ScaledDamage", scaled)
			model:SetAttribute("Damage", scaled)
			model:SetAttribute("MaxHp", hum.MaxHealth)
			if def.isBoss or def.isMiniboss then
				model:SetAttribute("BossPhase", 1)
			end
		end
	end
	model.Parent = Workspace:WaitForChild("GameWorld")
	EnemyService._alive[model] = true
	return model
end

function EnemyService.SpawnTurtle(x: number): Model?
	local model = EnemyService.Spawn("RescueTurtle", x)
	if model then
		model:SetAttribute("Rescued", false)
		local root = model.PrimaryPart
		if root then
			local pp = Instance.new("ProximityPrompt")
			pp.ActionText = "Rescue"
			pp.ObjectText = "Baby Turtle"
			pp.KeyboardKeyCode = Enum.KeyCode.E
			pp.HoldDuration = 0
			pp.ClickablePrompt = true
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 10
			pp:SetAttribute("FM_Action", "RescueTurtle")
			pp.Parent = root
			local bb = root:FindFirstChildOfClass("BillboardGui")
			if not bb then
				-- nameplate already exists from factory; add rescue hint via attribute
			end
			root:SetAttribute("RescueHint", "Press E · Rescue")
		end
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

function EnemyService.ApplyDamage(model: Model, amount: number, attacker: Player?, knockback: number?, heavy: boolean?): boolean
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
	-- Hyper armor during boss phase transition: skip flinch (still take damage)
	local hyperUntil = model:GetAttribute("HyperArmorUntil")
	local hyper = typeof(hyperUntil) == "number" and os.clock() < hyperUntil
	if not hyper then
		-- Flinch: brief AI pause so every hit reads
		model:SetAttribute("FlinchUntil", os.clock() + Constants.FLINCH_TIME)
	end
	hum.Health = math.max(0, hum.Health - amount)
	updateNameplate(model)
	EnemyFactory.HitFlash(model)

	local root = model.PrimaryPart
	if root then
		Remotes.Get("DamageNumber"):FireAllClients(root.Position, math.floor(amount), false)
		local shakeAmt = if heavy then 0.85 elseif amount > 20 then 0.65 else 0.4
		Remotes.Get("CombatEvent"):FireAllClients({
			kind = "hitConnect",
			pos = root.Position,
			amount = shakeAmt,
			heavy = heavy == true,
			hitstop = if heavy then Constants.HITSTOP_HEAVY else Constants.HITSTOP,
		})
		-- Knockback owned by CombatService (ALV impulse preferred; PivotTo for Anchored kits)
		local kb = knockback or 0
		if kb > 0 and not hyper then
			CombatService.ApplyKnockback(model, attacker, kb, heavy)
		end
	end

	-- Boss phase transitions (Spillfather / minibosses) + brief hyper armor
	if model:GetAttribute("IsBoss") or model:GetAttribute("IsMiniboss") then
		local maxHp = model:GetAttribute("MaxHp") :: number?
		if maxHp and maxHp > 0 then
			local pct = hum.Health / maxHp
			local phase = (model:GetAttribute("BossPhase") :: number?) or 1
			if pct <= 0.66 and phase < 2 then
				model:SetAttribute("BossPhase", 2)
				model:SetAttribute("HyperArmorUntil", os.clock() + Constants.HYPER_ARMOR_DURATION)
				Remotes.Get("CombatEvent"):FireAllClients({ kind = "shake", amount = 1.0 })
				EnemyService.UpdateSpillfatherSlickRing(2)
			elseif pct <= 0.33 and phase < 3 then
				model:SetAttribute("BossPhase", 3)
				model:SetAttribute("HyperArmorUntil", os.clock() + Constants.HYPER_ARMOR_DURATION)
				Remotes.Get("CombatEvent"):FireAllClients({ kind = "shake", amount = 1.2 })
				EnemyService.UpdateSpillfatherSlickRing(3)
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
	local pos = if root then root.Position else Vector3.new(0, 4, Constants.LANE_Z)
	EnemyFactory.DeathPoof(pos, Color3.fromRGB(255, 120, 160))
	-- stash pos for cinematic Focus after Destroy
	model:SetAttribute("RescuePosX", pos.X)
	model:SetAttribute("RescuePosY", pos.Y)
	model:SetAttribute("RescuePosZ", pos.Z)
	EnemyService._alive[model] = nil
	if EnemyService._onTurtleRescued then
		EnemyService._onTurtleRescued(player, model)
	end
	model:Destroy()
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
			-- Hit flinch: freeze briefly so knockback + flash read
			local flinchUntil = model:GetAttribute("FlinchUntil")
			if typeof(flinchUntil) == "number" and os.clock() < flinchUntil then
				EnemyFactory.Animate(model, dt, false, false)
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
					-- Live Bait (aggro): enemies treat you as closer / more interesting
					if char:GetAttribute("AggroPull") == true then
						d *= 0.72
					end
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
	local enemyId = (model:GetAttribute("EnemyId") :: string) or ""
	local phase = (model:GetAttribute("BossPhase") :: number?) or 1
	-- Phase 1 teach band: stretch telegraphs on stages 1–2 so dodge is readable
	local stageIdx = EnemyService._stageIndex or 1
	if stageIdx <= 2 then
		tele = tele * 1.2
	elseif stageIdx == 3 then
		tele = tele * 1.08
	end
	-- Boss Phase 2–3: slightly faster telegraphs, wider zones (pattern change, not sponge)
	if phase >= 2 then
		tele = math.max(0.28, tele * (if phase >= 3 then 0.7 else 0.85))
	end

	local tcAttr = model:GetAttribute("TelegraphColor")
	local teleColor = if typeof(tcAttr) == "Color3" then tcAttr else Color3.fromRGB(255, 60, 60)

	local zones: { Part } = {}
	local function addZone(size: Vector3, cf: CFrame, color: Color3?, trans: number?): Part
		local zone = Instance.new("Part")
		zone.Name = "Telegraph"
		zone.Anchored = true
		zone.CanCollide = false
		zone.Material = Enum.Material.Neon
		zone.Color = color or teleColor
		zone.Transparency = trans or 0.5
		zone.Size = size
		zone.CFrame = cf
		zone.Parent = Workspace
		Debris:AddItem(zone, tele + 0.2)
		table.insert(zones, zone)
		return zone
	end

	local width = if model:GetAttribute("IsBoss") then 16 elseif behavior == "firearc" then 14 else 9
	local primary: Part? = nil

	-- UNIQUE telegraphs by folklore role
	if behavior == "firearc" or enemyId == "FireLizard" or enemyId == "EmberSkink" or enemyId == "RigWelder" then
		-- GROUND fire cone: wedge telegraph then breath
		width = 12 + phase * 2
		primary = addZone(Vector3.new(width, 0.35, 10), CFrame.new(root.Position.X + facing * width * 0.4, 0.25, Constants.LANE_Z), Color3.fromRGB(255, 100, 20), 0.45)
		-- cone tip marker
		addZone(Vector3.new(2, 0.5, 2), CFrame.new(root.Position.X + facing * 3, 0.4, Constants.LANE_Z), Color3.fromRGB(255, 220, 60), 0.3)
	elseif enemyId == "SelfieZombie" or (behavior == "spitter" and enemyId == "SelfieZombie") then
		-- Flash stun CONE (wide short)
		width = 11
		primary = addZone(Vector3.new(width * 0.55, 0.4, 12), CFrame.new(root.Position + Vector3.new(facing * width * 0.35, -root.Size.Y * 0.3, 0)), Color3.fromRGB(180, 240, 255), 0.4)
		addZone(Vector3.new(3, 3, 0.4), CFrame.new(root.Position + Vector3.new(facing * 2, 1.5, 0)), Color3.fromRGB(255, 255, 255), 0.2)
	elseif enemyId == "CondoKaren" then
		-- Slow aura ring + clipboard swipe lane
		primary = addZone(Vector3.new(14, 0.3, 14), CFrame.new(root.Position.X, 0.25, Constants.LANE_Z), Color3.fromRGB(255, 80, 120), 0.65)
		addZone(Vector3.new(10, 0.4, 5), CFrame.new(root.Position + Vector3.new(facing * 5, -root.Size.Y * 0.35, 0)), Color3.fromRGB(200, 40, 80), 0.45)
		width = 12
	elseif enemyId == "DroneSpotter" then
		-- Mark circle then dive
		width = 8
		primary = addZone(Vector3.new(8, 0.25, 8), CFrame.new(root.Position.X, 0.2, Constants.LANE_Z), Color3.fromRGB(100, 255, 180), 0.4)
		-- dive lane
		addZone(Vector3.new(6, 0.35, 5), CFrame.new(root.Position.X, 0.3, Constants.LANE_Z), Color3.fromRGB(255, 80, 80), 0.5)
	elseif behavior == "burrower" or enemyId == "BurrowSnake" then
		-- Dirt ring then pop
		width = 7
		primary = addZone(Vector3.new(7, 0.3, 7), CFrame.new(root.Position.X, 0.2, Constants.LANE_Z), Color3.fromRGB(180, 140, 80), 0.4)
	elseif behavior == "scuttle" or enemyId == "BeachCrab" or enemyId == "OffshoreCrab" or enemyId == "CrabKingBoss" or enemyId == "HermitCrab" then
		-- Pinch combo: two short telegraphs (left then right)
		width = 8
		primary = addZone(Vector3.new(7, 0.4, 5), CFrame.new(root.Position + Vector3.new(facing * 4, -root.Size.Y * 0.3, 0)), Color3.fromRGB(255, 120, 80), 0.45)
		addZone(Vector3.new(5, 0.35, 4), CFrame.new(root.Position + Vector3.new(facing * 6.5, -root.Size.Y * 0.3, 0.5)), Color3.fromRGB(255, 180, 100), 0.55)
	elseif behavior == "puddle" or enemyId == "OilGator" or enemyId == "OilPuddleLayer" then
		-- Sludge puddle leave-behind telegraph
		width = 10
		primary = addZone(Vector3.new(10, 0.3, 6), CFrame.new(root.Position.X + facing * 4, 0.2, Constants.LANE_Z), Color3.fromRGB(40, 50, 30), 0.4)
	elseif behavior == "summoner" then
		width = 10
		primary = addZone(Vector3.new(10, 0.35, 10), CFrame.new(root.Position.X, 0.25, Constants.LANE_Z), Color3.fromRGB(180, 80, 255), 0.5)
	elseif model:GetAttribute("IsBoss") and enemyId == "Spillfather" then
		-- Phase patterns: 1 slam lane, 2 double slam + summon, 3 arena slick ring
		if phase <= 1 then
			width = 16
			primary = addZone(Vector3.new(16, 0.45, 8), CFrame.new(root.Position + Vector3.new(facing * 8, -1, 0)), Color3.fromRGB(255, 120, 0), 0.4)
		elseif phase == 2 then
			width = 18
			primary = addZone(Vector3.new(14, 0.45, 7), CFrame.new(root.Position + Vector3.new(facing * 7, -1, 0)), Color3.fromRGB(255, 100, 0), 0.4)
			addZone(Vector3.new(14, 0.45, 7), CFrame.new(root.Position + Vector3.new(-facing * 7, -1, 0)), Color3.fromRGB(255, 160, 40), 0.5)
		else
			width = 22
			primary = addZone(Vector3.new(22, 0.4, 14), CFrame.new(root.Position.X, 0.25, Constants.LANE_Z), Color3.fromRGB(255, 80, 20), 0.45)
			addZone(Vector3.new(10, 0.35, 10), CFrame.new(root.Position.X, 0.3, Constants.LANE_Z), Color3.fromRGB(40, 40, 30), 0.35)
		end
	else
		primary = addZone(Vector3.new(width, 0.4, 6), CFrame.new(root.Position + Vector3.new(facing * width * 0.5, -root.Size.Y * 0.35, 0)), teleColor, 0.5)
	end

	if not primary then
		primary = zones[1]
	end

	-- claw snap / attack telegraph anim
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

	if behavior == "summoner" or (enemyId == "Spillfather" and phase >= 2) then
		spawnSummon(model)
		if enemyId == "Spillfather" and phase >= 3 then
			spawnSummon(model)
		end
	end
	if behavior == "puddle" or enemyId == "OilGator" or (enemyId == "Spillfather" and phase >= 3) then
		leavePuddle(root.Position + Vector3.new(facing * 4, 0, 0))
		if enemyId == "Spillfather" and phase >= 3 then
			leavePuddle(root.Position + Vector3.new(-facing * 6, 0, 0))
			leavePuddle(root.Position)
		end
	end

	local char = target.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		if CombatService.HasIFrames(target) then
			return
		end
		local hit = false
		for _, zone in zones do
			if zone.Parent and math.abs(hrp.Position.X - zone.Position.X) < math.max(zone.Size.X, zone.Size.Z) * 0.55
				and math.abs(hrp.Position.Z - Constants.LANE_Z) < 5 then
				hit = true
				break
			end
		end
		-- Karen slow aura: soft damage + attribute flag
		if hit and enemyId == "CondoKaren" then
			char:SetAttribute("SlowUntil", os.clock() + 1.4)
		end
		if hit then
			local finalDmg = dmg
			if enemyId == "Spillfather" and phase >= 3 then
				finalDmg = math.floor(dmg * 1.15)
			end
			Remotes.Get("CombatEvent"):FireClient(target, { kind = "hit", damage = finalDmg, source = enemyId })
			target:SetAttribute("PendingDamage", finalDmg)
			target:SetAttribute("PendingDamageAt", os.clock())
		end
	end
end

return EnemyService
