--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Settings"))

local Tagline = {}

function Tagline.Show(text: string, speaker: string?)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Tagline")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Tagline"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 40
	gui.Parent = pg

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0.72, 0, 0, 118)
	frame.Position = UDim2.new(0.14, 0, 0.68, 0)
	frame.BackgroundColor3 = Color3.fromRGB(15, 20, 28)
	frame.BackgroundTransparency = 0.12
	frame.Active = true
	frame.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = frame
	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(255, 200, 80)
	st.Thickness = 2
	st.Parent = frame

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = frame

	local who = Instance.new("TextLabel")
	who.Size = UDim2.new(1, 0, 0, 22)
	who.Position = UDim2.new(0, 0, 0, 0)
	who.BackgroundTransparency = 1
	who.Font = Enum.Font.GothamBold
	who.TextSize = 15
	who.TextXAlignment = Enum.TextXAlignment.Left
	who.TextColor3 = Color3.fromRGB(255, 190, 70)
	who.Text = (speaker or "Captain Steve") .. " — live from the swamp"
	who.Parent = frame

	local body = Instance.new("TextLabel")
	body.Size = UDim2.new(1, 0, 0, 58)
	body.Position = UDim2.new(0, 0, 0, 28)
	body.BackgroundTransparency = 1
	body.Font = Enum.Font.GothamBold
	body.TextWrapped = true
	body.TextSize = 22
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.TextYAlignment = Enum.TextYAlignment.Top
	body.TextColor3 = Color3.fromRGB(255, 245, 220)
	body.Text = ""
	body.Parent = frame

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(1, 0, 0, 18)
	hint.Position = UDim2.new(0, 0, 1, -18)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 12
	hint.TextXAlignment = Enum.TextXAlignment.Right
	hint.TextColor3 = Color3.fromRGB(180, 190, 210)
	hint.Text = "tap / click to skip · Esc dismiss"
	hint.Parent = frame

	frame.BackgroundTransparency = 1
	TweenService:Create(frame, TweenInfo.new(0.28), { BackgroundTransparency = 0.12 }):Play()

	local full = '"' .. text .. '"'
	local cancelled = false
	local revealed = false
	local destroyAt = 0

	local function finishTypewriter()
		if revealed then
			return
		end
		revealed = true
		body.Text = full
		hint.Text = "tap / click / Esc to dismiss"
		destroyAt = os.clock() + 4.5
	end

	local function dismiss()
		cancelled = true
		if gui.Parent then
			gui:Destroy()
		end
	end

	gui.Destroying:Connect(function()
		cancelled = true
	end)

	local delaySec = Settings.TypewriterDelay(player)
	if delaySec <= 0 then
		finishTypewriter()
	else
		task.spawn(function()
			for i = 1, #full do
				if cancelled or not gui.Parent then
					return
				end
				if revealed then
					return
				end
				body.Text = string.sub(full, 1, i)
				task.wait(delaySec)
			end
			if not cancelled and gui.Parent then
				finishTypewriter()
			end
		end)
	end

	local function onSkip()
		if cancelled or not gui.Parent then
			return
		end
		if not revealed then
			finishTypewriter()
			return
		end
		dismiss()
	end

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			onSkip()
		end
	end)

	local conn = UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Return or input.KeyCode == Enum.KeyCode.Space then
			onSkip()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			-- only if clicking outside frame still skip when revealed
			if revealed then
				onSkip()
			end
		end
	end)
	gui.Destroying:Connect(function()
		conn:Disconnect()
	end)

	task.spawn(function()
		while gui.Parent and not cancelled do
			if revealed and destroyAt > 0 and os.clock() >= destroyAt then
				dismiss()
				return
			end
			task.wait(0.2)
		end
	end)
end

return Tagline
