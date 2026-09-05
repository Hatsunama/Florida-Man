--!strict
--[[ Simple LoadingGui — Florida Man title splash. No marketplace upload / fake asset IDs. ]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local LoadingGui = {}

function LoadingGui.Init()
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	if pg:FindFirstChild("FM_Loading") then
		return
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Loading"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 100
	gui.ResetOnSpawn = false
	gui.Parent = pg

	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
	bg.BorderSizePixel = 0
	bg.Parent = gui

	-- Soft vignette frame using built-in texture (not marketplace)
	local frame = Instance.new("ImageLabel")
	frame.Name = "Frame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	frame.ImageTransparency = 0.92
	frame.ScaleType = Enum.ScaleType.Stretch
	frame.Parent = bg

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(0.8, 0, 0, 72)
	title.Position = UDim2.new(0.1, 0, 0.38, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.Text = "FLORIDA MAN"
	title.TextColor3 = Color3.fromRGB(255, 180, 60)
	title.TextStrokeColor3 = Color3.fromRGB(40, 20, 0)
	title.TextStrokeTransparency = 0.4
	title.TextScaled = true
	title.Parent = bg

	local sub = Instance.new("TextLabel")
	sub.Name = "Subtitle"
	sub.Size = UDim2.new(0.7, 0, 0, 32)
	sub.Position = UDim2.new(0.15, 0, 0.5, 0)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.Text = "It IS Florida… Anything is possible in the swamp I guess."
	sub.TextColor3 = Color3.fromRGB(200, 220, 255)
	sub.TextScaled = true
	sub.Parent = bg

	local tip = Instance.new("TextLabel")
	tip.Name = "Tip"
	tip.Size = UDim2.new(0.72, 0, 0, 28)
	tip.Position = UDim2.new(0.14, 0, 0.68, 0)
	tip.BackgroundTransparency = 1
	tip.Font = Enum.Font.Gotham
	tip.Text = "Press E at the bonfire · Options for mute / text speed · dialogue is on-screen text only"
	tip.TextColor3 = Color3.fromRGB(160, 170, 190)
	tip.TextScaled = true
	tip.Parent = bg

	local policy = Instance.new("TextLabel")
	policy.Name = "Policy"
	policy.Size = UDim2.new(0.7, 0, 0, 20)
	policy.Position = UDim2.new(0.15, 0, 0.78, 0)
	policy.BackgroundTransparency = 1
	policy.Font = Enum.Font.Gotham
	policy.Text = "Florida Dew = heal soda (not alcohol) · Soft launch N8 · InEngine_v3"
	policy.TextColor3 = Color3.fromRGB(120, 140, 160)
	policy.TextScaled = true
	policy.Parent = bg

	-- Accent circle (persona-colored stand-in for logo)
	local badge = Instance.new("Frame")
	badge.Name = "Badge"
	badge.Size = UDim2.fromOffset(64, 64)
	badge.Position = UDim2.new(0.5, -32, 0.28, -32)
	badge.BackgroundColor3 = Color3.fromRGB(255, 196, 72)
	badge.Parent = bg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = badge
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 120, 40)
	stroke.Thickness = 3
	stroke.Parent = badge

	task.delay(1.4, function()
		if not gui.Parent then
			return
		end
		local tw = TweenService:Create(bg, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1,
		})
		TweenService:Create(title, TweenInfo.new(0.55), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(sub, TweenInfo.new(0.55), { TextTransparency = 1 }):Play()
		TweenService:Create(tip, TweenInfo.new(0.55), { TextTransparency = 1 }):Play()
		TweenService:Create(policy, TweenInfo.new(0.55), { TextTransparency = 1 }):Play()
		TweenService:Create(badge, TweenInfo.new(0.55), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, TweenInfo.new(0.55), { Transparency = 1 }):Play()
		TweenService:Create(frame, TweenInfo.new(0.55), { ImageTransparency = 1 }):Play()
		tw:Play()
		tw.Completed:Wait()
		gui:Destroy()
	end)
end

return LoadingGui
