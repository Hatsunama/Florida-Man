--!strict
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Weapons = require(Shared:WaitForChild("Weapons"))
local VFX = require(script.Parent:WaitForChild("VFX"))
local AnimController = require(script.Parent:WaitForChild("AnimController"))
local CaptainSteveUI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("CaptainSteveUI"))
local TutorialController = require(script.Parent:WaitForChild("TutorialController"))

local InputController = {}
InputController._enabled = true
InputController._movement = nil :: any
InputController._unlockedWeapons = { BareHands = true, FlipFlopSlap = true } :: { [string]: boolean }
InputController._weaponId = "BareHands"

local function fire(name: string, ...)
	Remotes.Get(name):FireServer(...)
end

local function uiBlocking(): boolean
	local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then
		return false
	end
	return pg:FindFirstChild("FM_Newspaper") ~= nil
		or pg:FindFirstChild("FM_Draft") ~= nil
		or pg:FindFirstChild("FM_Steve") ~= nil
		or pg:FindFirstChild("FM_Tagline") ~= nil
		or pg:FindFirstChild("FM_Options") ~= nil
		or pg:FindFirstChild("FM_Credits") ~= nil
end

local function unlockedOrdered(): { string }
	local ids = {}
	for _, w in Weapons.List do
		if InputController._unlockedWeapons[w.id] then
			table.insert(ids, w.id)
		end
	end
	if #ids == 0 then
		table.insert(ids, "BareHands")
	end
	return ids
end

local function equipBySlot(slot: number)
	if uiBlocking() or not InputController._enabled then
		return
	end
	local ids = unlockedOrdered()
	local id = ids[slot]
	if not id then
		return
	end
	fire("EquipWeapon", id)
end

local function cycleWeapon(delta: number)
	if uiBlocking() or not InputController._enabled then
		return
	end
	local ids = unlockedOrdered()
	local cur = 1
	for i, id in ids do
		if id == InputController._weaponId then
			cur = i
			break
		end
	end
	local nextIdx = ((cur - 1 + delta) % #ids) + 1
	fire("EquipWeapon", ids[nextIdx])
end

function InputController.SetWeaponState(weaponId: string?, unlocked: { [string]: boolean }?)
	if typeof(weaponId) == "string" then
		InputController._weaponId = weaponId
	end
	if typeof(unlocked) == "table" then
		InputController._unlockedWeapons = unlocked
	end
end

function InputController.CycleWeapon(delta: number?)
	cycleWeapon(if typeof(delta) == "number" then delta else 1)
end

local function tryInteract()
	local player = Players.LocalPlayer
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local world = workspace:FindFirstChild("GameWorld")
	if not hrp or not world then
		return
	end
	local flame = world:FindFirstChild("Flame")
	if flame and (flame.Position - hrp.Position).Magnitude < 12 then
		fire("RequestStartRun")
		return
	end
	local steve = world:FindFirstChild("CaptainSteve")
	if steve and (steve.Position - hrp.Position).Magnitude < 12 then
		fire("TalkCaptainSteve")
		CaptainSteveUI.Open()
	end
end

local comboHint = 0
local lastSwingAt = 0
local attackBufferedUntil = 0
local attackReadyAt = 0
local ATTACK_RECOVERY = 0.22 -- fallback until StateUpdate / CombatEvent syncs server recovery

function InputController.SyncAttackReady(serverReadyAt: number?, serverNow: number?, recovery: number?)
	local localNow = os.clock()
	if typeof(serverReadyAt) == "number" and typeof(serverNow) == "number" then
		local remaining = (serverReadyAt :: number) - (serverNow :: number)
		attackReadyAt = localNow + math.max(0, remaining)
		return
	end
	if typeof(recovery) == "number" then
		attackReadyAt = localNow + math.max(0, recovery :: number)
	end
end

local function doSwingFire()
	if uiBlocking() then
		return
	end
	local mov = InputController._movement
	local facing = 1
	if mov then
		facing = mov.GetFacing()
		mov.LockFacing(facing, 0.28)
	end
	local now = os.clock()
	if now - lastSwingAt > 0.45 then
		comboHint = 0
	end
	comboHint = (comboHint % 3) + 1
	lastSwingAt = now
	attackReadyAt = now + ATTACK_RECOVERY
	local player = Players.LocalPlayer
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		local ch = player.Character
		local vfxKind = ch and ch:GetAttribute("WeaponVfx")
		if typeof(vfxKind) ~= "string" then
			vfxKind = "punch"
		end
		VFX.SwingSlash(hrp, facing, comboHint, vfxKind :: string)
		AnimController.PlayAttack(comboHint)
	end
	fire("RequestAttack")
	TutorialController.OnAttackInput()
end

local function tryAttack()
	if uiBlocking() then
		return
	end
	local now = os.clock()
	if now >= attackReadyAt then
		doSwingFire()
	else
		attackBufferedUntil = now + 0.12
		task.delay(attackReadyAt - now, function()
			if uiBlocking() or not InputController._enabled then
				return
			end
			if os.clock() <= attackBufferedUntil + 0.02 and os.clock() >= attackReadyAt - 0.01 then
				doSwingFire()
			end
		end)
	end
end

function InputController.TryAttack()
	tryAttack()
end

function InputController.BindMovement(movement: any)
	InputController._movement = movement
end

function InputController.Start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not InputController._enabled then
			return
		end
		if uiBlocking() then
			return
		end
		local k = input.KeyCode
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or k == Enum.KeyCode.J then
			tryAttack()
		elseif k == Enum.KeyCode.K then
			fire("RequestSkill")
		elseif k == Enum.KeyCode.Q then
			fire("RequestSwap")
		elseif k == Enum.KeyCode.LeftShift then
			-- dodge via MovementController
		elseif k == Enum.KeyCode.E then
			tryInteract()
		elseif k == Enum.KeyCode.One then
			equipBySlot(1)
		elseif k == Enum.KeyCode.Two then
			equipBySlot(2)
		elseif k == Enum.KeyCode.Three then
			equipBySlot(3)
		end
	end)

	ContextActionService:BindAction("FM_Attack", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled and not uiBlocking() then
			tryAttack()
		end
	end, false, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction("FM_Skill", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled and not uiBlocking() then
			fire("RequestSkill")
		end
	end, false, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("FM_Swap", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled and not uiBlocking() then
			fire("RequestSwap")
		end
	end, false, Enum.KeyCode.ButtonB)

	ContextActionService:BindAction("FM_Dodge", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled and not uiBlocking() then
			local mov = InputController._movement
			if mov then
				mov.RequestDodge()
			else
				fire("RequestDodge")
			end
			TutorialController.OnDodgeInput()
		end
	end, false, Enum.KeyCode.ButtonR1)

	ContextActionService:BindAction("FM_Interact", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled and not uiBlocking() then
			tryInteract()
		end
	end, false, Enum.KeyCode.ButtonL1)
end

function InputController.SetEnabled(on: boolean)
	InputController._enabled = on
	local mov = InputController._movement
	if mov then
		mov.SetEnabled(on)
	end
end

return InputController
