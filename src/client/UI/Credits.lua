--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Credits = {}

function Credits.Show(payload: any)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Credits")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Credits"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 60
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.fromRGB(8, 14, 32)
	dim.BackgroundTransparency = 0
	dim.BorderSizePixel = 0
	dim.Parent = gui
	local dimGrad = Instance.new("UIGradient")
	dimGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 28, 55)),
		ColorSequenceKeypoint.new(0.55, Color3.fromRGB(40, 35, 70)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 140, 70)),
	})
	dimGrad.Rotation = 90
	dimGrad.Parent = dim

	-- Sunrise band with gradient
	local sun = Instance.new("Frame")
	sun.Size = UDim2.new(1, 0, 0.42, 0)
	sun.Position = UDim2.new(0, 0, 0.58, 0)
	sun.BackgroundColor3 = Color3.fromRGB(255, 160, 70)
	sun.BackgroundTransparency = 0.35
	sun.BorderSizePixel = 0
	sun.Parent = gui
	local sunGrad = Instance.new("UIGradient")
	sunGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 40)),
		ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255, 180, 80)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 230, 160)),
	})
	sunGrad.Rotation = 90
	sunGrad.Parent = sun
	sun.BackgroundTransparency = 1
	TweenService:Create(sun, TweenInfo.new(4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0.25,
	}):Play()

	local sunDisk = Instance.new("Frame")
	sunDisk.Size = UDim2.new(0, 120, 0, 120)
	sunDisk.Position = UDim2.new(0.5, -60, 0.62, 0)
	sunDisk.BackgroundColor3 = Color3.fromRGB(255, 220, 120)
	sunDisk.BorderSizePixel = 0
	sunDisk.Parent = gui
	local sunCorner = Instance.new("UICorner")
	sunCorner.CornerRadius = UDim.new(1, 0)
	sunCorner.Parent = sunDisk
	sunDisk.BackgroundTransparency = 1
	TweenService:Create(sunDisk, TweenInfo.new(5, Enum.EasingStyle.Sine), { BackgroundTransparency = 0.15 }):Play()

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 720, 0, 720)
	holder.Position = UDim2.new(0.5, -360, 1, 40)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local y = 0
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 56)
	title.Position = UDim2.new(0, 0, 0, y)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 48
	title.TextColor3 = Color3.fromRGB(255, 210, 90)
	title.Text = payload.title or "FLORIDA MAN"
	title.Parent = holder
	y += 56

	if payload.subtitle then
		local sub = Instance.new("TextLabel")
		sub.Size = UDim2.new(1, 0, 0, 28)
		sub.Position = UDim2.new(0, 0, 0, y)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextSize = 18
		sub.TextColor3 = Color3.fromRGB(255, 230, 180)
		sub.Text = payload.subtitle
		sub.Parent = holder
		y += 44
	else
		y += 24
	end

	for _, line in payload.lines or {} do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 30)
		lbl.Position = UDim2.new(0, 0, 0, y)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 20
		lbl.TextColor3 = Color3.fromRGB(235, 240, 250)
		lbl.Text = line
		lbl.Parent = holder
		y += 36
	end

	-- Slower scroll (~28s) for sunrise feel
	local scrollSec = 28
	TweenService:Create(holder, TweenInfo.new(scrollSec, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0.5, -360, 0, -y - 40),
	}):Play()

	-- Music swell (Phase 5)
	pcall(function()
		local AudioDirector = require(script.Parent.Parent.Controllers:WaitForChild("AudioDirector"))
		AudioDirector.Play("SFX_CreditsSwell", { volume = 0.7, pitch = 0.85 })
		AudioDirector.Duck(3)
	end)

	task.delay(scrollSec + 3, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

return Credits
