--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Personas = require(Shared:WaitForChild("Personas"))
local Items = require(Shared:WaitForChild("Items"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local Balance = require(Shared:WaitForChild("Balance"))
local Types = require(Shared:WaitForChild("Types"))

local TutorialService = require(script.Parent:WaitForChild("TutorialService"))
local MetaService = require(script.Parent:WaitForChild("MetaService"))

local RunContext = {}

export type RunState = Types.RunState

local states: { [Player]: RunState } = {}
local rng = Random.new()

function RunContext.GetRng(): Random
	return rng
end

function RunContext.GetState(player: Player): RunState?
	return states[player]
end

function RunContext.SetState(player: Player, s: RunState)
	states[player] = s
end

function RunContext.ClearState(player: Player)
	states[player] = nil
end

function RunContext.PersistMeta(player: Player, s: RunState)
	MetaService.CaptureFromRun(player, s.deaths, s.sunburn, s.unlockedPersonas, s.stageIndex)
	MetaService.Save(player) -- dirty-gated + re-entrancy safe
end

function RunContext.PushState(player: Player)
	local s = states[player]
	if not s then
		return
	end
	Remotes.Get("StateUpdate"):FireClient(player, {
		stageId = s.stageId,
		stageIndex = s.stageIndex,
		hp = s.hp,
		maxHp = s.maxHp,
		personas = s.personas,
		activePersona = s.activePersona,
		unlockedPersonas = s.unlockedPersonas,
		personaRarity = s.personaRarity,
		items = s.items,
		itemSlots = s.itemSlots,
		sunburn = s.sunburn,
		luck = s.luck,
		deaths = s.deaths,
		turtlesRescued = s.turtlesRescued,
		turtlesNeeded = s.turtlesNeeded,
		hangoverUntil = s.hangoverUntil,
		inHub = s.inHub,
		runActive = s.runActive,
		skillReadyAt = s.skillReadyAt,
		swapReadyAt = s.swapReadyAt,
		dodgeReadyAt = s.dodgeReadyAt,
		serverNow = os.clock(),
		awaitingDraft = s.awaitingDraft,
		awaitingNewspaper = s.awaitingNewspaper,
		bossDefeated = s.bossDefeated,
		weaponId = s.weaponId,
		unlockedWeapons = s.unlockedWeapons,
		moveSpeed = s.moveSpeed,
		hangoverActive = os.clock() < s.hangoverUntil,
		actName = Balance.TierName(s.stageIndex),
		actNumber = Balance.ActNumber(s.stageIndex),
	})
end

function RunContext.Toast(player: Player, text: string)
	Remotes.Get("Toast"):FireClient(player, text)
end

function RunContext.ComputeStats(s: RunState)
	local maxHp = Constants.BASE_HP
	local dmg = 1
	local speed = 0
	local luck = 0
	local dodge = 0
	for _, id in s.items do
		local it = Items.Get(id)
		if it then
			maxHp += it.hpBonus
			dmg += it.damageBonus / 20
			speed += it.speedBonus
			luck += it.luckBonus
			dodge += it.dodgeBonus
			if it.special == "antiCorp" then
				dmg += 0.08
			end
			if it.special == "badge" then
				maxHp += 5
				dmg += 0.1
			end
		end
	end
	local counts = Items.CountInscriptions(s.items)
	for tag, n in counts do
		if n >= Constants.INSCRIPTION_SET_SIZE then
			local bonus = Items.SetBonuses[tag]
			if bonus then
				maxHp += bonus.hpBonus or 0
				if bonus.damageBonus then
					dmg += bonus.damageBonus
				end
				luck += bonus.luckBonus or 0
				dodge += bonus.dodgeBonus or 0
			end
		end
	end
	s.maxHp = maxHp
	s.damageMult = dmg
	s.speedBonus = speed
	s.luck = luck
	s.dodgeBonus = dodge
	if s.hp > s.maxHp then
		s.hp = s.maxHp
	end
end

function RunContext.HasItemSpecial(s: RunState, special: string): boolean
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == special then
			return true
		end
	end
	return false
end

function RunContext.HasHeroicLifesteal(s: RunState): boolean
	local counts = Items.CountInscriptions(s.items)
	return (counts.HEROIC or 0) >= Constants.INSCRIPTION_SET_SIZE
end

function RunContext.NewRunState(deaths: number): RunState
	return {
		stageId = "Hub",
		stageIndex = 0,
		hp = Constants.BASE_HP,
		maxHp = Constants.BASE_HP,
		personas = { "BeachBurnout" },
		activePersona = 1,
		unlockedPersonas = { BeachBurnout = true },
		personaRarity = { BeachBurnout = "Common" },
		items = {},
		itemSlots = if deaths > 0 then Constants.ITEM_SLOTS_AFTER_FIRST_DEATH else Constants.STARTING_ITEM_SLOTS,
		sunburn = 0,
		luck = 0,
		damageMult = 1,
		speedBonus = 0,
		dodgeBonus = 0,
		deaths = deaths,
		turtlesRescued = 0,
		turtlesNeeded = 0,
		hangoverUntil = 0,
		coldOneTaken = false,
		waveFlags = {},
		minibossSpawned = false,
		bossSpawned = false,
		bossDefeated = false,
		awaitingDraft = false,
		awaitingNewspaper = false,
		inHub = true,
		runActive = false,
		combo = 0,
		lastAttackAt = 0,
		lastHurtAt = 0,
		skillReadyAt = 0,
		swapReadyAt = 0,
		dodgeReadyAt = 0,
		facing = 1,
		unlockedFireworks = false,
		weaponId = Constants.STARTING_WEAPON,
		unlockedWeapons = { BareHands = true, FlipFlopSlap = true },
		moveSpeed = 18,
		checkpointX = 18,
		tutorial = TutorialService.NewFlags(),
		steveEvents = {},
		pendingSteveEvent = nil,
		midRoomState = "idle",
		lastActShown = 0,
	}
end

function RunContext.TeleportPlayer(player: Player, cf: CFrame)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		hrp.CFrame = cf
	end
end

function RunContext.ApplyPersonaLook(player: Player)
	local s = states[player]
	local char = player.Character
	if not s or not char then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	if not persona then
		return
	end
	char:SetAttribute("PersonaId", persona.id)
	local weapon = Weapons.Get(s.weaponId) or Weapons.GetStarter()
	if weapon then
		char:SetAttribute("WeaponVfx", weapon.vfx)
		char:SetAttribute("WeaponId", weapon.id)
		char:SetAttribute("WeaponKind", weapon.kind)
	end

	local bc = char:FindFirstChildOfClass("BodyColors")
	if not bc then
		bc = Instance.new("BodyColors")
		bc.Parent = char
	end
	local skin = persona.color:Lerp(Color3.fromRGB(255, 220, 180), 0.35)
	local accent = persona.accent
	bc.HeadColor3 = skin
	bc.TorsoColor3 = persona.color:Lerp(Color3.fromRGB(40, 40, 50), 0.25)
	bc.LeftArmColor3 = skin
	bc.RightArmColor3 = skin
	bc.LeftLegColor3 = accent:Lerp(skin, 0.5)
	bc.RightLegColor3 = accent:Lerp(skin, 0.5)

	local hl = char:FindFirstChild("FM_PersonaHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "FM_PersonaHighlight"
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = char
	end
	if hl:IsA("Highlight") then
		hl.FillColor = persona.color
		hl.OutlineColor = persona.accent
		hl.FillTransparency = 0.82
		hl.OutlineTransparency = 0.15
	end
end

function RunContext.ApplyCharacterSpeed(player: Player)
	local s = states[player]
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not s or not hum then
		return
	end
	local persona = Personas.Get(s.personas[s.activePersona])
	local base = if persona then persona.moveSpeed else 18
	base += s.speedBonus

	-- N2: Hangover ≠ OilSlow — min-stack one mult, never multiply both blindly
	local mult = 1
	local hungover = os.clock() < s.hangoverUntil
	if hungover then
		mult = math.min(mult, Constants.HANGOVER_SLOW)
	end
	local oilUntil = if char then char:GetAttribute("OilSlowUntil") else nil
	local oiled = typeof(oilUntil) == "number" and os.clock() < oilUntil
	if oiled then
		mult = math.min(mult, Constants.OIL_SLOW_MULT)
	end
	base *= mult
	s.moveSpeed = base

	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.AutoRotate = false
	if char then
		char:SetAttribute("MoveSpeed", base)
		char:SetAttribute("Hangover", hungover)
		char:SetAttribute("OilSlow", oiled)
		if not oiled then
			char:SetAttribute("OilSlowUntil", nil)
		end
		char:SetAttribute("AggroPull", RunContext.HasItemSpecial(s, "aggro"))
	end
	RunContext.ApplyPersonaLook(player)
end

function RunContext.UnlockPersona(player: Player, personaId: string)
	local s = states[player]
	if not s then
		return
	end
	if s.unlockedPersonas[personaId] then
		return
	end
	s.unlockedPersonas[personaId] = true
	s.personaRarity[personaId] = s.personaRarity[personaId] or "Common"
	local def = Personas.Get(personaId)
	RunContext.Toast(player, "Persona unlocked: " .. (if def then def.name else personaId))

	if #s.personas < 2 then
		table.insert(s.personas, personaId)
		RunContext.Toast(player, "Equipped to persona slot 2!")
	end
	RunContext.PushState(player)
end

-- Hard slot cap (N0.1): never exceed itemSlots
function RunContext.TryGrantItem(player: Player, itemId: string): boolean
	local s = states[player]
	if not s then
		return false
	end
	if #s.items >= s.itemSlots then
		return false
	end
	if not Items.Get(itemId) then
		return false
	end
	table.insert(s.items, itemId)
	local it = Items.Get(itemId)
	if it and it.healOnPickup > 0 then
		s.hp = math.min(s.maxHp, s.hp + it.healOnPickup)
	end
	RunContext.ComputeStats(s)
	return true
end

function RunContext.ActivePersonaDef(s: RunState)
	return Personas.Get(s.personas[s.activePersona])
end

return RunContext
