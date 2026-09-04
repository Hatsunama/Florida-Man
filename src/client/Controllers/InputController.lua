--!strict
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local VFX = require(script.Parent:WaitForChild("VFX"))
local AnimController = require(script.Parent:WaitForChild("AnimController"))
local CaptainSteveUI = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("CaptainSteveUI"))
local TutorialController = require(script.Parent:WaitForChild("TutorialController"))

local InputController = {}
InputController._enabled = true
InputController._movement = nil :: any

local function fire(name: string)
	Remotes.Get(name):FireServer()
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
local ATTACK_RECOVERY = 0.2

local function doSwingFire()
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
	local now = os.clock()
	if now >= attackReadyAt then
		doSwingFire()
	else
		-- Buffer: fire as soon as recovery ends (Skul-like)
		attackBufferedUntil = now + 0.12
		task.delay(attackReadyAt - now, function()
			if os.clock() <= attackBufferedUntil + 0.02 and os.clock() >= attackReadyAt - 0.01 then
				if InputController._enabled then
					doSwingFire()
				end
			end
		end)
	end
end

function InputController.BindMovement(movement: any)
	InputController._movement = movement
end

function InputController.Start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not InputController._enabled then
			return
		end
		-- Don't let Space eat through draft/newspaper/steve panels
		local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
		if pg and input.KeyCode == Enum.KeyCode.Space then
			if pg:FindFirstChild("FM_Newspaper") or pg:FindFirstChild("FM_Draft") or pg:FindFirstChild("FM_Steve") or pg:FindFirstChild("FM_Credits") then
				return
			end
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
			-- handled by MovementController
		elseif k == Enum.KeyCode.E then
			tryInteract()
			-- Phase 1: weapon keys 1–3 stubs removed (Phase 3 owns weapons). No silent no-ops.
		end
	end)

	ContextActionService:BindAction("FM_Attack", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled then
			tryAttack()
		end
	end, false, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonR2)

	ContextActionService:BindAction("FM_Skill", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled then
			fire("RequestSkill")
		end
	end, false, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonL2)

	ContextActionService:BindAction("FM_Swap", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled then
			fire("RequestSwap")
		end
	end, false, Enum.KeyCode.ButtonB)

	ContextActionService:BindAction("FM_Dodge", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled then
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
		if state == Enum.UserInputState.Begin and InputController._enabled then
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
