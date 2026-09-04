--!strict
--[[ Client half of Phase 1 tutorial beat map.
	Detects move / jump / attack / dodge locally and notifies server once.
	Replaces the old forever-spam hub toasts.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local TutorialController = {}

local reported: { [string]: boolean } = {}
local lastX: number? = nil
local stageId = "Hub"
local enabled = true

local function report(beat: string)
	if reported[beat] or not enabled then
		return
	end
	reported[beat] = true
	Remotes.Get("TutorialBeat"):FireServer(beat)
end

function TutorialController.ResetForStage(id: string)
	stageId = id or "Hub"
	-- keep lifetime flags across hub→stage1 so move/jump don't re-fire; reset stage-only if leaving run
	if id == "Hub" then
		-- hub revisit after death: allow bonfire hint once more only if never completed attack beat
		if not reported["attack"] then
			reported["hubBonfire"] = false
		end
	end
	lastX = nil
end

function TutorialController.OnAttackInput()
	report("attack")
end

function TutorialController.OnDodgeInput()
	report("dodge")
end

function TutorialController.Start()
	local player = Players.LocalPlayer

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not enabled then
			return
		end
		local k = input.KeyCode
		if k == Enum.KeyCode.Space then
			report("jump")
		elseif k == Enum.KeyCode.LeftShift then
			report("dodge")
		elseif k == Enum.KeyCode.A or k == Enum.KeyCode.D or k == Enum.KeyCode.Left or k == Enum.KeyCode.Right then
			report("move")
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.15)
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then
				continue
			end
			local x = hrp.Position.X
			if lastX == nil then
				lastX = x
			elseif math.abs(x - lastX) > 2.5 then
				report("move")
				lastX = x
			end
			-- near Cold One → hint once (server also handles pickup beat)
			local world = workspace:FindFirstChild("GameWorld")
			local cold = world and world:FindFirstChild("ColdOne")
			if cold and cold:IsA("BasePart") and (cold.Position - hrp.Position).Magnitude < 10 then
				report("nearColdOne")
			end
		end
	end)
end

return TutorialController
