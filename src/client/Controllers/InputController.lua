--!strict
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local InputController = {}
InputController._enabled = true

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
	if flame and (flame.Position - hrp.Position).Magnitude < 10 then
		fire("RequestStartRun")
		return
	end
	local steve = world:FindFirstChild("CaptainSteve")
	if steve and (steve.Position - hrp.Position).Magnitude < 12 then
		fire("TalkCaptainSteve")
	end
end

function InputController.Start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not InputController._enabled then
			return
		end
		local k = input.KeyCode
		local t = input.UserInputType
		if t == Enum.UserInputType.MouseButton1 or k == Enum.KeyCode.J then
			fire("RequestAttack")
		elseif k == Enum.KeyCode.K then
			fire("RequestSkill")
		elseif k == Enum.KeyCode.Q then
			fire("RequestSwap")
		elseif k == Enum.KeyCode.LeftShift then
			fire("RequestDodge")
		elseif k == Enum.KeyCode.E then
			tryInteract()
		end
	end)

	ContextActionService:BindAction("FM_Attack", function(_, state)
		if state == Enum.UserInputState.Begin and InputController._enabled then
			fire("RequestAttack")
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
			fire("RequestDodge")
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
end

return InputController
