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
local FunnelService = require(script.Parent:WaitForChild("FunnelService"))

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
	if not s or not s.runActive or s.deathProcessed then
		return
	end
	s.deathProcessed = true
	s.characterReady = false
	RunContext.BeginPhase(player, 'Recovering')
	EnemyService.Clear()
	s.deaths += 1
	s.hp = 0
	s.runActive = false
	FunnelService.Mark(player, "death", { deaths = s.deaths, stage = s.stageId, stageIndex = s.stageIndex })
	RunContext.Toast(player, Story.DeathLine(s.deaths))
	s.items = {}
	s.itemSlots = Constants.STARTING_ITEM_SLOTS
	s.runTurtlesRescued = 0
	s.rewardLedger = {}
	s.completionCommitted = false
	RunContext.ComputeStats(s)
	s.hp = s.maxHp
	local hum = player.Character and player.Character:FindFirstChildOfClass('Humanoid')
	s.characterReady = hum ~= nil and hum.Health > 0
	RunContext.PersistMeta(player, s)
	deps.StageFlow.LoadHub(player)
end

function CombatFacade.ApplyDamageToPlayer(player: Player, amount: number)
	if amount ~= amount or amount <= 0 or amount == math.huge then return end
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

	local mitigation = 1
	for _, id in s.items do
		local it = Items.Get(id)
		if it and it.special == "absorb" then
			mitigation *= 0.75
		end
	end
	amount = math.max(1, math.floor(amount * mitigation))
	s.lastHurtAt = os.clock()
	s.hp = math.max(0, s.hp - amount)
	RunContext.PushState(player)
	if s.hp <= 0 then
		CombatFacade.KillPlayer(player)
	end
end

function CombatFacade.DoAttack(player: Player, facing: number?)
	AttackService.DoAttack(player, facing)
end

function CombatFacade.DoSkill(player: Player, facing: number?)
	SkillService.DoSkill(player, facing)
end

function CombatFacade.DoDodge(player: Player, facingArg: number?)
	SwapService.DoDodge(player, facingArg)
end

function CombatFacade.DoSwap(player: Player, facing: number?)
	SwapService.DoSwap(player, facing)
end

function CombatFacade.EquipWeapon(player: Player, weaponId: unknown)
	local st = RunContext.GetState(player)
	if not st or typeof(weaponId) ~= "string" then
		return
	end
	if not st.unlockedWeapons[weaponId] or not Weapons.Get(weaponId) then
		return
	end
	if st.phase ~= 'Hub' and st.phase ~= 'Active' then return end
	if st.weaponId == weaponId then return end
	st.weaponId = weaponId
	local wdef = Weapons.Get(weaponId)
	RunContext.Toast(player, "Equipped: " .. (if wdef then wdef.name else weaponId))
	RunContext.ApplyPersonaLook(player)
	RunContext.PersistMeta(player, st)
	RunContext.PushState(player)
end

return CombatFacade
