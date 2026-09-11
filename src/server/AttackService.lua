--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Geometry = require(Shared:WaitForChild("CombatGeometry"))
local CharacterGeometry = require(Shared:WaitForChild('CharacterGeometry'))

local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))

local AttackService = {}

local function isFireEnemy(model: Model): boolean
	local behavior = model:GetAttribute("Behavior")
	if behavior == "firearc" then
		return true
	end
	local eid = model:GetAttribute("EnemyId")
	return eid == "FireLizard" or eid == "EmberSkink" or eid == "RigWelder" or eid == "Spillfather"
end

local function applyWeaponSecondary(model: Model, weapon: any, baseDamage: number): number
	local dmg = baseDamage
	local effect = weapon.secondaryEffect
	if effect == "foamFire" and isFireEnemy(model) then
		dmg *= Constants.FOAM_FIRE_MULT
	end
	return dmg
end

local function applyOnHitSpecials(player: Player, s: RunContext.RunState, model: Model, baseDamage: number): number
	local dmg = baseDamage
	local rng = RunContext.GetRng()

	if s.emberUntil > 0 and os.clock() < s.emberUntil then
		dmg *= Constants.EMBER_DAMAGE_MULT
	end

	if RunContext.HasItemSpecial(s, "paperCut") and rng:NextNumber() < (0.18 + s.luck * 0.25) then
		dmg *= 1.45
		RunContext.Toast(player, "Paper cut crit!")
	end

	if RunContext.HasItemSpecial(s, "radio") and model:GetAttribute("EnemyId") == "OilGator" then
		dmg *= 1.35
	end

	return dmg
end

function AttackService.HitEnemy(player: Player, s: RunContext.RunState, model: Model, amount: number, knock: number, heavy: boolean, weapon: any?): EnemyService.DamageResult
	if RunContext.GetState(player) ~= s or not s.runActive or not EnemyService.CanDamage(model) then
		return { accepted = false, damageApplied = 0, killed = false }
	end
	local dmg = applyOnHitSpecials(player, s, model, amount)
	if weapon then
		dmg = applyWeaponSecondary(model, weapon, dmg)
	end
	local result = EnemyService.ApplyDamage(model, dmg, player, knock, heavy)
	if result.accepted and RunContext.GetState(player) == s then
		if RunContext.HasHeroicLifesteal(s) then
			local healed = Geometry.HealFromDamage(s.hp, s.maxHp, result.damageApplied, 0.06)
			if healed ~= s.hp then
				s.hp = healed
				-- Projectile/coil hits happen after the command's initial snapshot.
				RunContext.PushState(player)
			end
		end
		if weapon and weapon.secondaryEffect == "netRoot" and not result.killed and not model:GetAttribute("IsBoss") then
			model:SetAttribute("RootedUntil", os.clock() + Constants.NET_ROOT_DURATION)
			model:SetAttribute("AttackRevision", ((model:GetAttribute("AttackRevision") :: number?) or 0) + 1)
		end
	end
	return result
end

function AttackService.DoAttack(player: Player, facingArg: number?)
	local s = RunContext.GetState(player)
	if not s or not s.runActive or s.awaitingDraft then
		return
	end
	if not CombatService.CanAttack(player) then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local now = os.clock()
	local persona = RunContext.ActivePersonaDef(s)
	if not persona then
		return
	end
	s.combo = Geometry.NextCombo(s.combo, now, CombatService.GetAttackReadyAt(player), Constants.COMBO_WINDOW)
	s.lastAttackAt = now
	s.facing = CombatService.ResolveFacing(player, facingArg, s.facing)
	local generation = EnemyService.GetGeneration()
	local function isCurrent(): boolean
		return generation == EnemyService.GetGeneration() and RunContext.GetState(player) == s and s.runActive and player.Character == char
	end

	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	local moveHit = CombatService.GetMovesetHit(persona.id, s.combo)
	local speedScale = math.max(0.55, persona.attackSpeed * (weapon.speed or 1))
	local recovery = moveHit.recovery / speedScale
	local cancelAfter = moveHit.cancelAfter / speedScale
	CombatService.MarkAttack(player, recovery, cancelAfter)

	local base = (persona.attackDamage + (weapon.damage - 10) * 0.65) * s.damageMult * moveHit.dmgMul
	local rarity = s.personaRarity[persona.id] or "Common"
	base *= Balance.RarityMult(rarity)

	local range = (weapon.range or Constants.ATTACK_RANGE) * moveHit.rangeMul
	local knock = (weapon.knockback or Constants.KNOCKBACK_BASE) * moveHit.knockMul
	local origin = hrp.Position
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	-- Low lane muzzle reaches small grounded enemies; jumping raises the shot too.
	local feetDistance = if char and humanoid then CharacterGeometry.FeetDistance(char,hrp,humanoid) else hrp.Size.Y*0.5+2
	local projectileOrigin = Vector3.new(origin.X, Geometry.MuzzleY(origin.Y, feetDistance), origin.Z)
	local hits = 0
	local heavy = s.combo == 3
	local wkind = weapon.kind or "melee"

	local function applyHit(model: Model, dmg: number, kb: number, hv: boolean)
		if isCurrent() and AttackService.HitEnemy(player, s, model, dmg, kb, hv, weapon).accepted then hits += 1 end
	end

	if wkind == "ranged" then
		CombatService.SpawnProjectile({
			origin = projectileOrigin,
			facing = s.facing,
			range = range,
			damage = base,
			knockback = knock * 0.35,
			heavy = heavy,
			kind = "ranged",
			vfx = weapon.vfx,
			attacker = player,
			isCurrent = isCurrent,
			onHit = function(model, dmg, kb, hv)
				applyHit(model, dmg, kb, hv)
			end,
		})
	elseif wkind == "thrown" then
		CombatService.SpawnProjectile({
			origin = projectileOrigin,
			facing = s.facing,
			range = range,
			damage = base * 1.05,
			knockback = knock * 0.4,
			heavy = heavy,
			kind = "thrown",
			vfx = weapon.vfx,
			attacker = player,
			isCurrent = isCurrent,
			onHit = function(model, dmg, kb, hv)
				applyHit(model, dmg, kb, hv)
			end,
		})
	else
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			if CombatService.InHitVolume(origin, s.facing, root, range, 2, player) then
				applyHit(model, base, knock * 0.45, heavy)
			end
		end
	end

	if char then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponKind", wkind)
	end
	RunContext.PushState(player)
	local readyAt = CombatService.GetAttackReadyAt(player)
	local cancelAt = CombatService.GetCancelOpenAt(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "attack",
		combo = s.combo,
		facing = s.facing,
		weapon = s.weaponId,
		weaponKind = wkind,
		weaponVfx = weapon.vfx,
		hit = if wkind == "melee" then hits > 0 else nil,
		heavy = heavy,
		moveLabel = moveHit.label,
		attackReadyAt = readyAt,
		cancelOpenAt = cancelAt,
		serverNow = now,
		recovery = recovery,
	})
	task.delay(math.max(0.05, cancelAfter), function()
		if isCurrent() and CombatService.GetAttackReadyAt(player) == readyAt and CombatService.InCancelWindow(player) then
			Remotes.Get("CombatEvent"):FireClient(player, {
				kind = "cancelWindow",
				label = moveHit.label,
				combo = s.combo,
			})
		end
	end)
	if s.stageIndex == 1 then
		TutorialService.OnAttack(player, s.tutorial)
	end
end

return AttackService
