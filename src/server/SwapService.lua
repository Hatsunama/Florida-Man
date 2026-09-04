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

local SwapService = {}

function SwapService.DoDodge(player: Player, facingArg: number?)
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

function SwapService.DoSwap(player: Player)
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
