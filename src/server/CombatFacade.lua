--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Items = require(Shared:WaitForChild("Items"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Story = require(Shared:WaitForChild("Story"))

local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))

local CombatFacade = {}

local deps: any = nil

function CombatFacade.Init(d: any)
	deps = d
	-- N2: enemy hits apply via server callback (no client-trusted damage attrs)
	EnemyService.SetOnPlayerHit(function(player: Player, amount: number, _source: string?)
		CombatFacade.ApplyDamageToPlayer(player, amount)
	end)
end

-- N0.1: hard-cap enemy drop grants vs itemSlots (no math.max(..., 8) soft overflow)
function CombatFacade.GrantEnemyDrop(player: Player, itemId: string): boolean
	return RunContext.TryGrantItem(player, itemId)
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

	if RunContext.HasHeroicLifesteal(s) then
		local heal = math.max(2, math.floor(dmg * 0.06))
		s.hp = math.min(s.maxHp, s.hp + heal)
	end
	return dmg
end

local function hitEnemy(player: Player, s: RunContext.RunState, model: Model, amount: number, knock: number, heavy: boolean): boolean
	local dmg = applyOnHitSpecials(player, s, model, amount)
	return EnemyService.ApplyDamage(model, dmg, player, knock, heavy)
end

function CombatFacade.KillPlayer(player: Player)
	local s = RunContext.GetState(player)
	if not s then
		return
	end
	CombatService.ClearIFrames(player)
	CombatService.ClearShieldAbsorb(player)
	s.deaths += 1
	s.hp = 0
	s.runActive = false
	RunContext.Toast(player, Story.DeathLine(s.deaths) .. " (+1 item slot after first death)")
	local deaths = s.deaths
	local unlocked = s.unlockedPersonas
	local rarities = s.personaRarity
	local sunburn = s.sunburn
	local unlockedW = s.unlockedWeapons
	RunContext.SetState(player, RunContext.NewRunState(deaths))
	s = RunContext.GetState(player) :: RunContext.RunState
	s.unlockedPersonas = unlocked
	s.personaRarity = rarities
	s.sunburn = sunburn
	s.unlockedWeapons = unlockedW or { BareHands = true, FlipFlopSlap = true }
	s.itemSlots = Constants.ITEM_SLOTS_AFTER_FIRST_DEATH
	RunContext.ComputeStats(s)
	s.hp = s.maxHp
	RunContext.PersistMeta(player, s)
	deps.StageFlow.LoadHub(player)
end

function CombatFacade.ApplyDamageToPlayer(player: Player, amount: number)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	if CombatService.HasIFrames(player) then
		return
	end

	amount = CombatService.ConsumeShieldAbsorb(player, amount)
	if amount <= 0 then
		RunContext.Toast(player, "Shell absorbed the hit!")
		RunContext.PushState(player)
		return
	end

	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == "absorb" then
			amount = math.floor(amount * 0.75)
		end
	end
	s.lastHurtAt = os.clock()
	s.hp = math.max(0, s.hp - amount)
	RunContext.PushState(player)
	if s.hp <= 0 then
		CombatFacade.KillPlayer(player)
	end
end

function CombatFacade.DoAttack(player: Player)
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
	if now - s.lastAttackAt > Constants.COMBO_WINDOW then
		s.combo = 0
	end
	s.combo = (s.combo % 3) + 1
	s.lastAttackAt = now
	s.facing = if hrp.CFrame.LookVector.X >= 0 then 1 else -1
	local move = hrp.AssemblyLinearVelocity
	if math.abs(move.X) > 1 then
		s.facing = if move.X >= 0 then 1 else -1
	end

	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	local moveHit = CombatService.GetMovesetHit(persona.id, s.combo)
	CombatService.MarkAttack(player, moveHit.recovery / math.max(0.55, persona.attackSpeed * (weapon.speed or 1)))

	local base = (persona.attackDamage + (weapon.damage - 10) * 0.65) * s.damageMult * moveHit.dmgMul
	local rarity = s.personaRarity[persona.id] or "Common"
	base *= Balance.RarityMult(rarity)

	local range = (weapon.range or Constants.ATTACK_RANGE) * moveHit.rangeMul
	local knock = (weapon.knockback or Constants.KNOCKBACK_BASE) * moveHit.knockMul
	local origin = hrp.Position
	local hits = 0
	local heavy = s.combo == 3
	local wkind = weapon.kind or "melee"

	local function applyHit(model: Model, dmg: number, kb: number, hv: boolean)
		hitEnemy(player, s, model, dmg, kb, hv)
		hits += 1
	end

	-- N2: turtle rescue is ProximityPrompt/RescueTurtle only (no attack-rescue double-count)

	if wkind == "ranged" then
		CombatService.SpawnProjectile({
			origin = origin,
			facing = s.facing,
			range = range,
			damage = base,
			knockback = knock * 0.35,
			heavy = heavy,
			kind = "ranged",
			vfx = weapon.vfx,
			attacker = player,
			onHit = function(model, dmg, kb, hv)
				applyHit(model, dmg, kb, hv)
			end,
		})
	elseif wkind == "thrown" then
		CombatService.SpawnProjectile({
			origin = origin,
			facing = s.facing,
			range = range,
			damage = base * 1.05,
			knockback = knock * 0.4,
			heavy = heavy,
			kind = "thrown",
			vfx = weapon.vfx,
			attacker = player,
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
			if CombatService.InLaneMelee(origin.X, s.facing, root.Position.X, range) then
				if math.abs(root.Position.Z - Constants.LANE_Z) < 6 then
					applyHit(model, base, knock * 0.45, heavy)
				end
			end
		end
	end

	if char then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponKind", wkind)
	end
	RunContext.PushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "attack",
		combo = s.combo,
		facing = s.facing,
		weapon = s.weaponId,
		weaponKind = wkind,
		weaponVfx = weapon.vfx,
		hit = hits > 0,
		heavy = heavy,
		moveLabel = moveHit.label,
	})
	local sfx = if (wkind == "melee" and hits > 0) then "SFX_Hit" else "SFX_Swing"
	Remotes.Get("PlaySound"):FireClient(player, sfx)
	if s.stageIndex == 1 then
		TutorialService.OnAttack(player, s.tutorial)
	end
end

function CombatFacade.DoSkill(player: Player)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	local now = os.clock()
	if now < s.skillReadyAt or not CombatService.CanSkill(player) then
		return
	end
	local persona = RunContext.ActivePersonaDef(s)
	if not persona then
		return
	end
	local rarity = s.personaRarity[persona.id] or "Common"
	local cd = persona.skillCooldown * Balance.SkillCooldownMult(rarity)
	s.skillReadyAt = now + cd
	CombatService.MarkSkill(player, cd)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local dmg = persona.skillDamage * s.damageMult * Balance.RarityMult(rarity)
	local facing = s.facing
	local origin = hrp.Position

	if persona.skillKind == "shield" then
		s.hp = math.min(s.maxHp, s.hp + 18)
		CombatService.SetShieldAbsorb(player, Constants.SHIELD_ABSORB_AMOUNT)
		if char then
			char:SetAttribute("ShieldAbsorbVFX", true)
			task.delay(3.5, function()
				if char then
					char:SetAttribute("ShieldAbsorbVFX", nil)
				end
				if CombatService.GetShieldAbsorb(player) > 0 then
					CombatService.ClearShieldAbsorb(player)
				end
			end)
		end
		RunContext.Toast(player, persona.skillName .. "! Shell sanctuary — absorb ready.")
	elseif persona.skillKind == "summon" then
		CombatService.SpawnLingeringHitbox({
			origin = origin,
			facing = facing,
			duration = Constants.SUMMON_LINGER,
			radius = 7,
			damage = dmg * 0.45,
			knockback = Constants.KNOCKBACK_BASE * 0.35,
			tick = Constants.SUMMON_TICK,
			attacker = player,
			onHit = function(model, amount, knock, heavy)
				hitEnemy(player, s, model, amount, knock, heavy)
			end,
			color = Color3.fromRGB(120, 255, 140),
		})
		RunContext.Toast(player, persona.skillName .. "! Coil lingers.")
	elseif persona.skillKind == "beam" or persona.skillKind == "wave" then
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if not root then
				continue
			end
			local dx = root.Position.X - origin.X
			if dx * facing >= 0 and math.abs(dx) < 28 then
				local mult = if persona.id == "LizardBreath" and (model:GetAttribute("EnemyId") == "OilGator") then 1.4 else 1
				hitEnemy(player, s, model, dmg * mult, Constants.KNOCKBACK_BASE * 0.6, true)
			end
		end
	elseif persona.skillKind == "aoe" then
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and (root.Position - origin).Magnitude < 18 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.5, true)
			end
		end
	elseif persona.skillKind == "dash" then
		local isCart = persona.id == "GolfCartBandit"
		if isCart then
			CombatService.SetIFrames(player, Constants.CART_DASH_IFRAME)
			if char then
				char:SetAttribute("IFrameVFX", true)
				task.delay(Constants.CART_DASH_IFRAME, function()
					if char then
						char:SetAttribute("IFrameVFX", nil)
					end
				end)
			end
			RunContext.Toast(player, persona.skillName .. "! Armor frames — full send.")
		end
		hrp.CFrame = hrp.CFrame + Vector3.new(facing * (if isCart then 16 else 14), 0, 0)
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and math.abs(root.Position.X - hrp.Position.X) < 12 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.55, true)
			end
		end
	end
	RunContext.PushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "skill",
		skill = persona.skillName,
		skillKind = persona.skillKind,
		facing = facing,
	})
end

function CombatFacade.DoDodge(player: Player, facingArg: number?)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	local now = os.clock()
	local cd = Constants.DODGE_COOLDOWN * (1 - math.clamp(s.dodgeBonus, 0, 0.5))
	if now < s.dodgeReadyAt then
		return
	end
	s.dodgeReadyAt = now + cd
	if typeof(facingArg) == "number" then
		s.facing = if facingArg >= 0 then 1 else -1
	end
	local char = player.Character

	CombatService.SetIFrames(player, Constants.DODGE_IFRAME)
	if RunContext.HasItemSpecial(s, "ember") then
		s.emberUntil = now + Constants.EMBER_BUFF_DURATION
	end
	if char then
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.DODGE_IFRAME, function()
			if char then
				char:SetAttribute("IFrameVFX", nil)
			end
		end)
	end
	Remotes.Get("CombatEvent"):FireClient(player, { kind = "dodge" })
	Remotes.Get("PlaySound"):FireClient(player, "SFX_Dodge")
	RunContext.PushState(player)
end

function CombatFacade.DoSwap(player: Player)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	if #s.personas < 2 then
		RunContext.Toast(player, "Need 2 personas to swap. Unlock more!")
		return
	end
	local now = os.clock()
	if now < s.swapReadyAt or not CombatService.CanSwap(player) then
		return
	end
	s.swapReadyAt = now + Constants.SWAP_COOLDOWN
	CombatService.MarkSwap(player, Constants.SWAP_COOLDOWN)
	s.activePersona = if s.activePersona == 1 then 2 else 1
	RunContext.ApplyCharacterSpeed(player)

	local persona = RunContext.ActivePersonaDef(s)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if char then
		CombatService.SetIFrames(player, Constants.SWAP_IFRAME)
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.SWAP_IFRAME, function()
			if char then
				char:SetAttribute("IFrameVFX", nil)
			end
		end)
	end
	local punish = (s.lastHurtAt > 0) and ((now - s.lastHurtAt) <= Constants.SWAP_PUNISH_WINDOW)
	if persona and hrp then
		local rarity = s.personaRarity[persona.id] or "Common"
		local mult = Constants.SWAP_ATTACK_DAMAGE_MULT * (if punish then Constants.SWAP_PUNISH_BONUS else 1)
		local dmg = persona.attackDamage * s.damageMult * mult * Balance.RarityMult(rarity)
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and (root.Position - hrp.Position).Magnitude < 14 then
				hitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.75, true)
			end
		end
		if punish then
			RunContext.Toast(player, "SWAP PUNISH! " .. persona.name .. " — hit back harder!")
		else
			RunContext.Toast(player, "Swap attack! " .. persona.name .. " — risk the CD, reap the tempo!")
		end
	end
	RunContext.PushState(player)
	Remotes.Get("CombatEvent"):FireClient(player, {
		kind = "swap",
		active = s.activePersona,
		personaId = if persona then persona.id else nil,
		color = if persona then { persona.color.R, persona.color.G, persona.color.B } else nil,
		punish = punish,
	})
end

function CombatFacade.EquipWeapon(player: Player, weaponId: unknown)
	local st = RunContext.GetState(player)
	if not st or typeof(weaponId) ~= "string" then
		return
	end
	if not st.unlockedWeapons[weaponId] or not Weapons.Get(weaponId) then
		return
	end
	st.weaponId = weaponId
	local wdef = Weapons.Get(weaponId)
	RunContext.Toast(player, "Equipped: " .. (if wdef then wdef.name else weaponId))
	RunContext.ApplyPersonaLook(player)
	RunContext.PushState(player)
end

return CombatFacade
