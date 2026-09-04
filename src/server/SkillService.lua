--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))

local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local AttackService = require(script.Parent:WaitForChild("AttackService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))

local SkillService = {}

function SkillService.DoSkill(player: Player)
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
	local weapon = nil

	local function hit(model: Model, amount: number, knock: number, heavy: boolean)
		AttackService.HitEnemy(player, s, model, amount, knock, heavy, weapon)
	end

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
			local dx = root.Position.X - origin.X
			if dx * facing >= 0 and math.abs(dx) < 28 then
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
			if root and (root.Position - origin).Magnitude < 18 then
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
