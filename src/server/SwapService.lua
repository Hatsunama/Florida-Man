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
local MovementAuthority = require(script.Parent:WaitForChild("MovementAuthority"))

local SwapService = {}

function SwapService.DoDodge(player: Player, facingArg: number?)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	local now = os.clock()
	local cd = Constants.DODGE_COOLDOWN * (1 - math.clamp(s.dodgeBonus, 0, 0.5))
	if not CombatService.CanDodge(player) then
		return
	end
	CombatService.MarkDodge(player, cd)
	MovementAuthority.AllowDodge(player, Constants.DODGE_DISTANCE, Constants.DODGE_DURATION)
	CombatService.MarkAttack(player, Constants.DODGE_IFRAME, Constants.DODGE_IFRAME)
	s.facing = CombatService.ResolveFacing(player, facingArg, s.facing)
	local char = player.Character
	local generation = EnemyService.GetGeneration()

	CombatService.SetIFrames(player, Constants.DODGE_IFRAME)
	if RunContext.HasItemSpecial(s, "ember") then
		s.emberUntil = now + Constants.EMBER_BUFF_DURATION
	end
	if char then
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.DODGE_IFRAME, function()
			if char and player.Character == char and generation == EnemyService.GetGeneration() and not CombatService.HasIFrames(player) then
				char:SetAttribute("IFrameVFX", nil)
			end
		end)
	end
	Remotes.Get("CombatEvent"):FireClient(player, { kind = "dodge", facing = s.facing, dodgeReadyAt = CombatService.GetDodgeReadyAt(player), serverNow = now })
	RunContext.PushState(player)
end

function SwapService.DoSwap(player: Player, facingArg: number?)
	local s = RunContext.GetState(player)
	if not s or not s.runActive then
		return
	end
	if #s.personas < 2 then
		RunContext.Toast(player, "Need 2 personas to swap. Unlock more!")
		return
	end
	local now = os.clock()
	if not CombatService.CanSwap(player) then
		return
	end
	CombatService.MarkSwap(player, Constants.SWAP_COOLDOWN)
	CombatService.MarkAttack(player, 0.22, 0.15)
	s.facing = CombatService.ResolveFacing(player, facingArg, s.facing)
	local generation = EnemyService.GetGeneration()
	s.activePersona = if s.activePersona == 1 then 2 else 1
	RunContext.ApplyCharacterSpeed(player)

	local persona = RunContext.ActivePersonaDef(s)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if char then
		CombatService.SetIFrames(player, Constants.SWAP_IFRAME)
		char:SetAttribute("IFrameVFX", true)
		task.delay(Constants.SWAP_IFRAME, function()
			if char and player.Character == char and generation == EnemyService.GetGeneration() and not CombatService.HasIFrames(player) then
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
			if root and CombatService.InHitVolume(hrp.Position, s.facing, root, 14, 3, player, true) then
				AttackService.HitEnemy(player, s, model, dmg, Constants.KNOCKBACK_BASE * 0.75, true, nil)
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

return SwapService
