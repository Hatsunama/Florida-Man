--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Items = require(Shared:WaitForChild("Items"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local Story = require(Shared:WaitForChild("Story"))
local Constants = require(Shared:WaitForChild("Constants"))

local EnemyService = require(script.Parent:WaitForChild("EnemyService"))
local CombatService = require(script.Parent:WaitForChild("CombatService"))
local AttackService = require(script.Parent:WaitForChild("AttackService"))
local SkillService = require(script.Parent:WaitForChild("SkillService"))
local SwapService = require(script.Parent:WaitForChild("SwapService"))
local RunContext = require(script.Parent:WaitForChild("RunContext"))

local CombatFacade = {}

local deps: any = nil

function CombatFacade.Init(d: any)
	deps = d
	EnemyService.SetOnPlayerHit(function(player: Player, amount: number, _source: string?)
		CombatFacade.ApplyDamageToPlayer(player, amount)
	end)
end

function CombatFacade.GrantEnemyDrop(player: Player, itemId: string): boolean
	return RunContext.TryGrantItem(player, itemId)
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
	AttackService.DoAttack(player)
end

function CombatFacade.DoSkill(player: Player)
	SkillService.DoSkill(player)
end

function CombatFacade.DoDodge(player: Player, facingArg: number?)
	SwapService.DoDodge(player, facingArg)
end

function CombatFacade.DoSwap(player: Player)
	SwapService.DoSwap(player)
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
