--!strict

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Enemies = require(Shared:WaitForChild("Enemies"))
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Util = require(Shared:WaitForChild("Util"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local Balance = require(Shared:WaitForChild("Balance"))
local EnemyFactory = require(script.Parent:WaitForChild("EnemyFactory"))
local Geometry = require(Shared:WaitForChild("CombatGeometry"))
local CharacterGeometry = require(Shared:WaitForChild('CharacterGeometry'))
local HazardService = require(script.Parent:WaitForChild("HazardService"))
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))
local MovementRules = require(script.Parent:WaitForChild('EnemyMovementRules'))

local EnemyService = {}
EnemyService._alive = {} :: { [Model]: boolean }
EnemyService._onKilled = nil :: ((Player, string, Model) -> ())?
EnemyService._onTurtleRescued = nil :: ((Player, Model) -> ())?
EnemyService._onPlayerHit = nil :: ((Player, number, string?) -> ())?
EnemyService._stageIndex = 1
EnemyService._rescueDebounceUntil = {} :: { [Model]: number }

local generation = 0
local function pivotFacing(model: Model, position: Vector3, facing: number)
	local axis = (model:GetAttribute('VisualForwardAxis') :: string?) or '+X'
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, MovementRules.FacingYaw(facing, axis), 0))
	model:SetAttribute('VisualFacing', facing)
end
local spawnQueue: { { enemyId: string, x: number } } = {}
local lastAttack: { [Model]: number } = {}
local telegraphing: { [Model]: boolean } = {}
local chargeDir: { [Model]: number } = {}
local burrowCD: { [Model]: number } = {}
local activeTelegraphs: { [Part]: boolean } = {}
local aiStarted = false

local function acquireTelegraph(): Part
	local zone = Instance.new("Part")
	zone.Name = "Telegraph"
	zone.Anchored = true
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	zone.Parent = Workspace:FindFirstChild("GameWorld") or Workspace
	activeTelegraphs[zone] = true
	return zone
end

local function releaseTelegraph(zone: Part, lifetime: number)
	task.delay(lifetime, function()
		activeTelegraphs[zone] = nil
		zone:Destroy()
	end)
end

function EnemyService.GetGeneration(): number
	return generation
end

function EnemyService.GetPendingCount(): number
	return #spawnQueue
end

function EnemyService.GetOutstandingCount(): number
	return EnemyService.CountHostile() + #spawnQueue
end

local function eligible(player: Player): boolean
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return player.Parent == Players and player:GetAttribute("RunActive") == true and hum ~= nil and hum.Health > 0
end

function EnemyService.SetStageContext(stageIndex: number)
	EnemyService._stageIndex = stageIndex or 1
end

function EnemyService.SetCallbacks(onKilled, onTurtleRescued)
	EnemyService._onKilled = onKilled
	EnemyService._onTurtleRescued = onTurtleRescued
end

-- N2: server-memory hit path — replaces client-trusted damage bus
function EnemyService.SetOnPlayerHit(cb: ((Player, number, string?) -> ())?)
	EnemyService._onPlayerHit = cb
end

function EnemyService.Clear()
	generation += 1
	table.clear(spawnQueue)
	for model in EnemyService._alive do
		model:Destroy()
	end
	for zone in activeTelegraphs do zone:Destroy() end
	table.clear(activeTelegraphs)
	table.clear(EnemyService._alive)
	table.clear(lastAttack)
	table.clear(telegraphing)
	table.clear(chargeDir)
	table.clear(burrowCD)
	table.clear(EnemyService._rescueDebounceUntil)
end

function EnemyService.Spawn(enemyId: string, x: number): Model?
	local def = Enemies.Get(enemyId)
	if not def then
		warn("Unknown enemy", enemyId)
		return nil
	end
	if not def.isAlly and EnemyService.CountHostile() >= Balance.MaxHostiles(EnemyService._stageIndex) then
		table.insert(spawnQueue, { enemyId = enemyId, x = x })
		return nil
	end
	-- Clamp at realization, including queued demand after the gate state changes.
	if not def.isAlly then x = CombatService.ClampEnemySpawnX(x, def.size) end
	local pos = Vector3.new(x, def.size.Y * 0.5 + 0.5, Constants.LANE_Z)
	local model = EnemyFactory.Build(def, pos)
	model:SetAttribute("SpawnGeneration", generation)
	model:SetAttribute("BaseY", pos.Y)

	if not def.isAlly then
		local hum = model:FindFirstChildOfClass("Humanoid")
		if hum then
			local hpM = Balance.EnemyHpMult(EnemyService._stageIndex)
			local dmgM = Balance.EnemyDmgMult(EnemyService._stageIndex)
			if def.isMiniboss then
				hpM = hpM * Balance.MinibossHpMult(EnemyService._stageIndex)
			end
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
			pp.GamepadKeyCode = Enum.KeyCode.ButtonL1
			pp.HoldDuration = 0
			pp.ClickablePrompt = true
			pp.RequiresLineOfSight = false
			pp.MaxActivationDistance = 12
			pp:SetAttribute("FM_Action", "RescueTurtle")
			pp.Parent = root
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

function EnemyService.UpdateSpillfatherSlickRing(phase: number)
	local world = Workspace:FindFirstChild("GameWorld")
	local ring = world and world:FindFirstChild("SpillfatherSlickRing")
	if not ring then
		return
	end
	ring:SetAttribute("Phase", phase)
	for _, segment in ring:GetChildren() do
		if segment:IsA("BasePart") then
			segment:SetAttribute("HazardEnabled", phase >= 2)
			segment:SetAttribute("HazardPeriod", if phase >= 3 then 2.4 else 3.2)
			segment:SetAttribute("HazardDuty", if phase >= 3 then 0.45 else 0.3)
			segment.Transparency = if phase >= 2 then 0.4 else 0.85
		end
	end
end

export type DamageResult = { accepted: boolean, damageApplied: number, killed: boolean }

function EnemyService.CanDamage(model: Model): boolean
	local hum = model:FindFirstChildOfClass("Humanoid")
	return EnemyService._alive[model] == true and model.Parent ~= nil and not model:GetAttribute("IsAlly") and hum ~= nil and hum.Health > 0
end

function EnemyService.ApplyDamage(model: Model, amount: number, attacker: Player?, knockback: number?, heavy: boolean?): DamageResult
	local rejected = { accepted = false, damageApplied = 0, killed = false }
	if not EnemyService.CanDamage(model) then return rejected end
	local hum = model:FindFirstChildOfClass("Humanoid") :: Humanoid
	local applied = Geometry.Damage(hum.Health, amount)
	if applied <= 0 then return rejected end

	local hyperUntil = model:GetAttribute("HyperArmorUntil")
	local hyper = typeof(hyperUntil) == "number" and os.clock() < hyperUntil
	if not hyper then

		model:SetAttribute("FlinchUntil", os.clock() + Constants.FLINCH_TIME)
		model:SetAttribute("AttackRevision", ((model:GetAttribute("AttackRevision") :: number?) or 0) + 1)
	end
	hum.Health = math.max(0, hum.Health - applied)
	local killed = hum.Health <= 0
	if killed then
		local deathPosition = if model.PrimaryPart then model.PrimaryPart.Position else Vector3.zero
		EnemyService._Poof(model, attacker)
		if attacker and attacker.Parent == Players then
			Remotes.Get("DamageNumber"):FireClient(attacker, deathPosition, math.floor(applied), false)
			Remotes.Get("CombatEvent"):FireClient(attacker, { kind = "hitConnect", pos = deathPosition, amount = 0.6, heavy = heavy == true })
		end
		return { accepted = true, damageApplied = applied, killed = true }
	end
	updateNameplate(model)
	EnemyFactory.HitFlash(model)

	local root = model.PrimaryPart
	if root then
		Remotes.Get("DamageNumber"):FireAllClients(root.Position, math.floor(applied), false)
		local shakeAmt = if heavy then 0.85 elseif amount > 20 then 0.65 else 0.4
		if attacker and attacker.Parent == Players then Remotes.Get("CombatEvent"):FireClient(attacker, {
			kind = "hitConnect",
			pos = root.Position,
			amount = shakeAmt,
			heavy = heavy == true,
			hitstop = if heavy then Constants.HITSTOP_HEAVY else Constants.HITSTOP,
		}) end

		local kb = knockback or 0
		if kb > 0 and not hyper then
			CombatService.ApplyKnockback(model, attacker, kb, heavy)
		end
	end

	-- Death is committed before optional phase changes, so a lethal threshold hit
	-- cannot leave a zero-health hostile waiting at a gate.
	if model:GetAttribute("EnemyId") == "Spillfather" and model:GetAttribute("IsBoss") then
		local maxHp = model:GetAttribute("MaxHp") :: number?
		if maxHp and maxHp > 0 then
			local phase = (model:GetAttribute("BossPhase") :: number?) or 1
			local nextPhase = Geometry.BossPhase(hum.Health, maxHp)
			if nextPhase > phase then
				model:SetAttribute("BossPhase", nextPhase)
				model:SetAttribute("HyperArmorUntil", os.clock() + Constants.HYPER_ARMOR_DURATION)
				Remotes.Get("CombatEvent"):FireAllClients({ kind = "shake", amount = 1.0 })
				EnemyService.UpdateSpillfatherSlickRing(nextPhase)
			end
		end
	end

	return { accepted = true, damageApplied = applied, killed = false }
end

function EnemyService._Poof(model: Model, attacker: Player?)
	if not EnemyService._alive[model] then
		return
	end
	EnemyService._alive[model] = nil
	lastAttack[model] = nil
	telegraphing[model] = nil
	chargeDir[model] = nil
	burrowCD[model] = nil
	local enemyId = model:GetAttribute("EnemyId") :: string
	local root = model.PrimaryPart
	local pos = if root then root.Position else Vector3.zero
	local color = if root then root.Color else Color3.new(1, 1, 1)
	if attacker and EnemyService._onKilled then
		local callback = EnemyService._onKilled
		local ok, err = pcall(function() callback(attacker, enemyId, model); return true end)
		if not ok then warn("Enemy completion callback failed:", err) end
	end
	model:Destroy()
	EnemyFactory.DeathPoof(pos, color)
end

function EnemyService.TryRescue(player: Player, model: Model): boolean
	if not eligible(player) or not EnemyService._alive[model] then return false end
	local playerRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	local root = model.PrimaryPart
	if not playerRoot or not root or (playerRoot.Position - root.Position).Magnitude > 12
		or not CombatService.HasLineOfSight(playerRoot.Position, root.Position, player) then return false end
	if not model:GetAttribute("IsAlly") then
		return false
	end
	if model:GetAttribute("Rescued") then
		return false
	end
	local untilT = EnemyService._rescueDebounceUntil[model]
	if typeof(untilT) == "number" and os.clock() < untilT then
		return false
	end
	EnemyService._rescueDebounceUntil[model] = os.clock() + Constants.RESCUE_DEBOUNCE
	model:SetAttribute("Rescued", true)
	local pos = root.Position

	model:SetAttribute("RescuePosX", pos.X)
	model:SetAttribute("RescuePosY", pos.Y)
	model:SetAttribute("RescuePosZ", pos.Z)
	EnemyService._alive[model] = nil
	if EnemyService._onTurtleRescued then
		local callback = EnemyService._onTurtleRescued
		local ok, err = pcall(function() callback(player, model); return true end)
		if not ok then warn("Turtle rescue callback failed:", err) end
	end
	EnemyService._rescueDebounceUntil[model] = nil
	model:Destroy()
	EnemyFactory.DeathPoof(pos, Color3.fromRGB(255, 120, 160))
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

local function spawnSummon(near: Model)
	local root = near.PrimaryPart
	if not root or EnemyService.GetOutstandingCount() >= Balance.MaxHostiles(EnemyService._stageIndex) then
		return
	end
	EnemyService.Spawn("Cottonmouth", root.Position.X + 6)
end

local function leavePuddle(pos: Vector3)
	HazardService.Spawn("oilSlick", Vector3.new(pos.X, 0.2, Constants.LANE_Z), Vector3.new(8, 0.25, 5), 6)
end

function EnemyService.StartAI()
	if aiStarted then return end
	aiStarted = true
	local accumulated = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulated += dt
		if accumulated < 1 / 30 then return end
		dt = math.min(accumulated, 0.1)
		accumulated = 0
		while #spawnQueue > 0 and EnemyService.CountHostile() < Balance.MaxHostiles(EnemyService._stageIndex) do
			local request = table.remove(spawnQueue, 1)
			if not request then break end
			EnemyService.Spawn(request.enemyId, request.x)
		end
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
				if model.Parent then
					EnemyFactory.Animate(model, dt, false, false)
				end
				continue
			end
			if telegraphing[model] then
				EnemyFactory.Animate(model, dt, false, true)
				continue
			end

			local flinchUntil = model:GetAttribute("FlinchUntil")
			if typeof(flinchUntil) == "number" and os.clock() < flinchUntil then
				EnemyFactory.Animate(model, dt, false, false)
				continue
			end

			local rootedUntil = model:GetAttribute("RootedUntil")
			if typeof(rootedUntil) == "number" and os.clock() < rootedUntil then
				EnemyFactory.Animate(model, dt, false, false)
				continue
			end

			local nearest: Player? = nil
			local nearestDist = 1e9
			local targetPos = root.Position
			for _, plr in Players:GetPlayers() do
				local char = plr.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp and eligible(plr) then
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
			local enemyId = model:GetAttribute("EnemyId")
			local attackRange = if model:GetAttribute("IsBoss") then 10 elseif behavior == "firearc" then 10
				elseif behavior == "summoner" or behavior == "burrower" or enemyId == "DroneSpotter" then 3.5 else 6

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
					newPos = CombatService.SweepEnemy(model, newPos)
					pivotFacing(model, newPos, cd)
				end
			elseif behavior == "burrower" then
				local now = os.clock()
				local last = burrowCD[model] or 0
				if now - last > 3 and nearestDist < 18 then
					burrowCD[model] = now

					local nx = targetPos.X - facing * 5
					local burrowPosition = CombatService.SweepEnemy(model, Vector3.new(nx, root.Position.Y, Constants.LANE_Z))
					pivotFacing(model, burrowPosition, facing)
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
					newPos = CombatService.SweepEnemy(model, newPos)
					pivotFacing(model, newPos, facing)
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
					newPos = CombatService.SweepEnemy(model, newPos)
					pivotFacing(model, newPos, facing)
				end
			elseif behavior == "scuttle" then

				if nearestDist > attackRange then
					moving = true
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * dt
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)

					newPos = CombatService.SweepEnemy(model, newPos)
					pivotFacing(model, newPos, facing)
				end
			else
				if nearestDist > attackRange then
					moving = true
					local dir = Util.SafeUnit(Vector3.new(targetPos.X - root.Position.X, 0, 0))
					local newPos = root.Position + dir * speed * dt
					newPos = Vector3.new(newPos.X, root.Position.Y, Constants.LANE_Z)
					newPos = CombatService.SweepEnemy(model, newPos)
					pivotFacing(model, newPos, facing)
				end
			end

			if not moving and model:GetAttribute('VisualFacing') ~= facing then pivotFacing(model, root.Position, facing) end
			EnemyFactory.Animate(model, dt, moving, false)

			if nearestDist <= attackRange then
				local now = os.clock()
				local cd = (model:GetAttribute("AttackCooldown") :: number) or 1.5
				local last = lastAttack[model] or 0
				if now - last >= cd then
					lastAttack[model] = now
					telegraphing[model] = true
					local attackGeneration = generation
					task.spawn(function()
						local ok, err = pcall(function()
							EnemyService._TelegraphAttack(model, nearest :: Player, behavior)
							return true
						end)
						if not ok then warn("Enemy attack failed:", err) end
						if attackGeneration == generation then telegraphing[model] = nil end
					end)
				end
			end
		end
	end)
end

function EnemyService._TelegraphAttack(model: Model, target: Player, behavior: string)
	local attackGeneration = generation
	local attackRevision = model:GetAttribute("AttackRevision")
	local targetCharacter = target.Character
	local function current(): boolean
		return generation == attackGeneration and EnemyService._alive[model] == true and model.Parent ~= nil
			and model:GetAttribute("AttackRevision") == attackRevision and eligible(target) and target.Character == targetCharacter
	end
	local root = model.PrimaryPart
	if not root or not current() then
		return
	end
	local tele = (model:GetAttribute("Telegraph") :: number) or 0.5
	local dmg = (model:GetAttribute("Damage") :: number) or 8
	local facing = (model:GetAttribute("Facing") :: number) or 1
	pivotFacing(model, root.Position, facing)
	local enemyId = (model:GetAttribute("EnemyId") :: string) or ""
	local phase = (model:GetAttribute("BossPhase") :: number?) or 1

	local stageIdx = EnemyService._stageIndex or 1
	if stageIdx <= 2 then
		tele = tele * 1.2
	elseif stageIdx == 3 then
		tele = tele * 1.08
	elseif stageIdx >= 17 then
		-- N5 late acts: denser (shorter) readable telegraphs — never softlock empty MidGate
		tele = math.max(0.30, tele * 0.82)
	elseif stageIdx >= 13 then
		tele = math.max(0.32, tele * 0.90)
	end

	if phase >= 2 then
		tele = math.max(0.28, tele * (if phase >= 3 then 0.7 else 0.85))
	end

	local tcAttr = model:GetAttribute("TelegraphColor")
	local teleColor = if typeof(tcAttr) == "Color3" then tcAttr else Color3.fromRGB(255, 60, 60)

	local zones: { Part } = {}
	local function addZone(size: Vector3, cf: CFrame, color: Color3?, trans: number?): Part
		local zone = acquireTelegraph()
		zone.Name = "Telegraph"
		zone.Anchored = true
		zone.CanCollide = false
		zone.Material = Enum.Material.Neon
		zone.Color = color or teleColor
		zone.Transparency = trans or 0.5
		zone.Size = size
		zone.CFrame = cf
		zone:SetAttribute("TelegraphStripe", false)

		zone:SetAttribute("AttackVolume", true)
		zone.Parent = Workspace:FindFirstChild("GameWorld") or Workspace
		releaseTelegraph(zone, tele + 0.2)
		table.insert(zones, zone)
		return zone
	end

	local width = if model:GetAttribute("IsBoss") then 16 elseif behavior == "firearc" then 14 else 9
	local primary: Part? = nil

	if behavior == "firearc" or enemyId == "FireLizard" or enemyId == "EmberSkink" or enemyId == "RigWelder" then

		width = 12 + phase * 2
		primary = addZone(Vector3.new(width, 0.35, 10), CFrame.new(root.Position.X + facing * width * 0.4, 0.25, Constants.LANE_Z), Color3.fromRGB(255, 100, 20), 0.45)

		addZone(Vector3.new(2, 0.5, 2), CFrame.new(root.Position.X + facing * 3, 0.4, Constants.LANE_Z), Color3.fromRGB(255, 220, 60), 0.3)
	elseif enemyId == "SelfieZombie" or (behavior == "spitter" and enemyId == "SelfieZombie") then

		width = 11
		primary = addZone(Vector3.new(width * 0.55, 0.4, 12), CFrame.new(root.Position + Vector3.new(facing * width * 0.35, -root.Size.Y * 0.3, 0)), Color3.fromRGB(180, 240, 255), 0.4)
		addZone(Vector3.new(3, 3, 0.4), CFrame.new(root.Position + Vector3.new(facing * 2, 1.5, 0)), Color3.fromRGB(255, 255, 255), 0.2)
	elseif enemyId == "CondoKaren" then

		primary = addZone(Vector3.new(14, 0.3, 14), CFrame.new(root.Position.X, 0.25, Constants.LANE_Z), Color3.fromRGB(255, 80, 120), 0.65)
		addZone(Vector3.new(10, 0.4, 5), CFrame.new(root.Position + Vector3.new(facing * 5, -root.Size.Y * 0.35, 0)), Color3.fromRGB(200, 40, 80), 0.45)
		width = 12
	elseif enemyId == "DroneSpotter" then

		width = 8
		primary = addZone(Vector3.new(8, 0.25, 8), CFrame.new(root.Position.X, 0.2, Constants.LANE_Z), Color3.fromRGB(100, 255, 180), 0.4)

		addZone(Vector3.new(6, 0.35, 5), CFrame.new(root.Position.X, 0.3, Constants.LANE_Z), Color3.fromRGB(255, 80, 80), 0.5)
	elseif behavior == "burrower" or enemyId == "BurrowSnake" then

		width = 7
		primary = addZone(Vector3.new(7, 0.3, 7), CFrame.new(root.Position.X, 0.2, Constants.LANE_Z), Color3.fromRGB(180, 140, 80), 0.4)
	elseif behavior == "scuttle" or enemyId == "BeachCrab" or enemyId == "OffshoreCrab" or enemyId == "CrabKingBoss" or enemyId == "HermitCrab" then

		width = 8
		primary = addZone(Vector3.new(7, 0.4, 5), CFrame.new(root.Position + Vector3.new(facing * 4, -root.Size.Y * 0.3, 0)), Color3.fromRGB(255, 120, 80), 0.45)
		addZone(Vector3.new(5, 0.35, 4), CFrame.new(root.Position + Vector3.new(facing * 6.5, -root.Size.Y * 0.3, 0.5)), Color3.fromRGB(255, 180, 100), 0.55)
	elseif behavior == "puddle" or enemyId == "OilGator" or enemyId == "OilPuddleLayer" then

		width = 10
		primary = addZone(Vector3.new(10, 0.3, 6), CFrame.new(root.Position.X + facing * 4, 0.2, Constants.LANE_Z), Color3.fromRGB(40, 50, 30), 0.4)
	elseif behavior == "summoner" then
		width = 10
		primary = addZone(Vector3.new(10, 0.35, 10), CFrame.new(root.Position.X, 0.25, Constants.LANE_Z), Color3.fromRGB(180, 80, 255), 0.5)
	elseif model:GetAttribute("IsBoss") and enemyId == "Spillfather" then

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

	local elapsed = 0
	while elapsed < tele do
		local step = task.wait(0.05)
		elapsed += step
		if not current() then
			for _, zone in zones do zone:Destroy() end
			return
		end
		EnemyFactory.Animate(model, step, false, true)
	end
	if not current() then
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

	-- Delayed attacks resolve against the accepted position, including corrections.
	MovementAuthority.Validate(target)
	local char = target.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and char then
		if CombatService.HasIFrames(target) then
			return
		end
		local hit = false
		for _, zone in zones do
			local localPosition = zone.CFrame:PointToObjectSpace(hrp.Position)
			local half = zone.Size * 0.5
			local feet = hrp.Position.Y - CharacterGeometry.FeetDistance(char,hrp,hum)
			if zone.Parent and math.abs(localPosition.X) <= half.X + hrp.Size.X * 0.35
				and math.abs(localPosition.Z) <= half.Z + hrp.Size.Z * 0.35
				and feet <= zone.Position.Y + half.Y + 0.25 and hrp.Position.Y + hrp.Size.Y * 0.5 >= zone.Position.Y - half.Y
				and CombatService.HasLineOfSight(root.Position, hrp.Position, target) then
				hit = true
				break
			end
		end

		if hit and char and enemyId == "CondoKaren" then
			char:SetAttribute("EnvironmentalSlowUntil", os.clock() + 1.4)
		end
		if hit then
			local finalDmg = dmg
			if enemyId == "Spillfather" and phase >= 3 then
				finalDmg = math.floor(dmg * 1.15)
			end
			Remotes.Get("CombatEvent"):FireClient(target, { kind = "hit", damage = finalDmg, source = enemyId })
			if EnemyService._onPlayerHit then
				EnemyService._onPlayerHit(target, finalDmg, enemyId)
			end
		end
	end
end

CombatService.SetEnemyProvider({
	GetGeneration = EnemyService.GetGeneration,
	GetAlive = EnemyService.GetAlive,
	CanDamage = EnemyService.CanDamage,
})

return EnemyService
