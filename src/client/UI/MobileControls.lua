--!strict
--[[ Phase 0: ugly but usable on-screen combat buttons for touch. ]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local MobileControls = {}

local function fire(name: string)
	Remotes.Get(name):FireServer()
end

function MobileControls.Init(inputController: any?)
	-- Always create on touch-enabled; also useful for testing
	if not UserInputService.TouchEnabled and not UserInputService.GamepadEnabled then
		-- Still create tiny buttons if TouchEnabled flips later — show when touch
	end
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_MobileControls"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = pg

	local function mk(text: string, pos: UDim2, color: Color3, onClick: () -> ())
		local b = Instance.new("TextButton")
		b.Size = UDim2.fromOffset(72, 72)
		b.Position = pos
		b.AnchorPoint = Vector2.new(1, 1)
		b.BackgroundColor3 = color
		b.BackgroundTransparency = 0.25
		b.Text = text
		b.TextColor3 = Color3.new(1, 1, 1)
		b.Font = Enum.Font.GothamBold
		b.TextScaled = true
		b.AutoButtonColor = true
		b.Parent = gui
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = b
		b.MouseButton1Click:Connect(onClick)
		b.Visible = UserInputService.TouchEnabled
		return b
	end

	local attack = mk("ATK", UDim2.new(1, -24, 1, -24), Color3.fromRGB(220, 80, 60), function()
		if inputController and inputController._enabled ~= false then
			local pg = Players.LocalPlayer:FindFirstChild("PlayerGui")
			if pg and (pg:FindFirstChild("FM_Draft") or pg:FindFirstChild("FM_Newspaper") or pg:FindFirstChild("FM_Steve") or pg:FindFirstChild("FM_Credits")) then
				return
			end
			fire("RequestAttack")
		end
	end)
	mk("SKILL", UDim2.new(1, -108, 1, -24), Color3.fromRGB(80, 140, 220), function()
		fire("RequestSkill")
	end)
	mk("DASH", UDim2.new(1, -24, 1, -108), Color3.fromRGB(80, 200, 160), function()
		if inputController and inputController._movement then
			inputController._movement.RequestDodge()
		else
			fire("RequestDodge")
		end
	end)
	mk("USE", UDim2.new(1, -108, 1, -108), Color3.fromRGB(220, 180, 60), function()
		fire("RequestStartRun")
		fire("TalkCaptainSteve")
	end)
	mk("WPN", UDim2.new(1, -192, 1, -24), Color3.fromRGB(120, 100, 200), function()
		if inputController and inputController.CycleWeapon then
			inputController.CycleWeapon(1)
		end
	end)

	UserInputService.LastInputTypeChanged:Connect(function()
		local show = UserInputService.TouchEnabled
		for _, ch in gui:GetChildren() do
			if ch:IsA("TextButton") then
				ch.Visible = show
			end
		end
	end)
end

return MobileControls
