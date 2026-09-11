--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Geometry = require(Shared:WaitForChild('CombatGeometry'))
local CharacterGeometry = require(Shared:WaitForChild('CharacterGeometry'))

local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local AttackService = require(script.Parent:WaitForChild("AttackService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))

local SkillService = {}

function SkillService.DoSkill(player: Player, facingArg: number?)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	if not CombatService.CanSkill(player) then
		return
	end
	local persona = RunContext.ActivePersonaDef(s)
	if not persona then
		return
	end
	local rarity = s.personaRarity[persona.id] or "Common"
	local cd = persona.skillCooldown * Balance.SkillCooldownMult(rarity)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	CombatService.MarkSkill(player, cd)
	s.skillReadyAt = CombatService.GetSkillReadyAt(player)
	CombatService.MarkAttack(player, 0.3, 0.2)
	local generation = EnemyService.GetGeneration()
	local function isCurrent(): boolean
		return generation == EnemyService.GetGeneration() and RunContext.GetState(player) == s and s.runActive and player.Character == char
	end
	local dmg = persona.skillDamage * s.damageMult * Balance.RarityMult(rarity)
	local facing = CombatService.ResolveFacing(player, facingArg, s.facing)
	s.facing = facing
	local origin = hrp.Position
	local weapon = nil

	local function hit(model: Model, amount: number, knock: number, heavy: boolean)
		if isCurrent() then AttackService.HitEnemy(player, s, model, amount, knock, heavy, weapon) end
	end

	if persona.skillKind == "shield" then
		s.hp = math.min(s.maxHp, s.hp + 18)
		CombatService.SetShieldAbsorb(player, Constants.SHIELD_ABSORB_AMOUNT)
		if char then
			char:SetAttribute("ShieldAbsorbVFX", true)
			task.delay(3.5, function()
				if not isCurrent() then return end
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
		local humanoid = char and char:FindFirstChildOfClass('Humanoid')
		local height = 3
		local feetDistance = if char and humanoid then CharacterGeometry.FeetDistance(char,hrp,humanoid) else hrp.Size.Y*0.5+2
		local centerY = Geometry.GroundedCenterY(origin.Y, feetDistance, height)
		CombatService.SpawnLingeringHitbox({
			origin = Vector3.new(origin.X, centerY, origin.Z),
			height = height,
			facing = facing,
			duration = Constants.SUMMON_LINGER,
			radius = 7,
			damage = dmg * 0.45,
			knockback = Constants.KNOCKBACK_BASE * 0.35,
			tick = Constants.SUMMON_TICK,
			attacker = player,
			isCurrent = isCurrent,
			onHit = function(model, amount, knock, heavy)
				hit(model, amount, knock, heavy)
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
			local skillRange = if persona.skillKind == "beam" then 28 else 16
			if CombatService.InHitVolume(origin, facing, root, skillRange, 2.5, player) then
				local mult = if persona.id == "LizardBreath" and (model:GetAttribute("EnemyId") == "OilGator") then 1.4 else 1
				hit(model, dmg * mult, Constants.KNOCKBACK_BASE * 0.6, true)
			end
		end
	elseif persona.skillKind == "aoe" then
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and CombatService.InHitVolume(origin, facing, root, 18, 4, player, true) then
				hit(model, dmg, Constants.KNOCKBACK_BASE * 0.5, true)
			end
		end
	elseif persona.skillKind == "dash" then
		local isCart = persona.id == "GolfCartBandit"
		if isCart then
			CombatService.SetIFrames(player, Constants.CART_DASH_IFRAME)
			if char then
				char:SetAttribute("IFrameVFX", true)
				task.delay(Constants.CART_DASH_IFRAME, function()
					if isCurrent() and char and not CombatService.HasIFrames(player) then
						char:SetAttribute("IFrameVFX", nil)
					end
				end)
			end
			RunContext.Toast(player, persona.skillName .. "! Armor frames — full send.")
		end
		local destination = CombatService.SweepDash(player, hrp, facing * (if isCart then 16 else 14))
		MovementAuthority.Reset(player, CFrame.new(destination) * (hrp.CFrame - hrp.Position))
		local center = (origin + destination) * 0.5
		local reach = math.abs(destination.X - origin.X) * 0.5 + 2
		for _, model in EnemyService.GetAlive() do
			if model:GetAttribute("IsAlly") then
				continue
			end
			local root = model.PrimaryPart
			if root and CombatService.InHitVolume(center, facing, root, reach, 2.5, player, true) then
				hit(model, dmg, Constants.KNOCKBACK_BASE * 0.55, true)
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

return SkillService
