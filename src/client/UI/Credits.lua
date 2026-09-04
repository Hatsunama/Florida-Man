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
	dim.BackgroundColor3 = Color3.fromRGB(12, 20, 40)
	dim.BackgroundTransparency = 0.05
	dim.Parent = gui

	-- Sunrise gradient fake
	local sun = Instance.new("Frame")
	sun.Size = UDim2.new(1, 0, 0.35, 0)
	sun.Position = UDim2.new(0, 0, 0.65, 0)
	sun.BackgroundColor3 = Color3.fromRGB(255, 140, 60)
	sun.BackgroundTransparency = 0.55
	sun.BorderSizePixel = 0
	sun.Parent = gui
	local sun2 = Instance.new("Frame")
	sun2.Size = UDim2.new(1, 0, 0.2, 0)
	sun2.Position = UDim2.new(0, 0, 0.8, 0)
	sun2.BackgroundColor3 = Color3.fromRGB(255, 200, 100)
	sun2.BackgroundTransparency = 0.4
	sun2.BorderSizePixel = 0
	sun2.Parent = gui

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 720, 0, 560)
	holder.Position = UDim2.new(0.5, -360, 1, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local y = 0
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 56)
	title.Position = UDim2.new(0, 0, 0, y)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 44
	title.TextColor3 = Color3.fromRGB(255, 200, 80)
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
		sub.TextColor3 = Color3.fromRGB(255, 220, 160)
		sub.Text = payload.subtitle
		sub.Parent = holder
		y += 40
	else
		y += 20
	end

	for _, line in payload.lines or {} do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 30)
		lbl.Position = UDim2.new(0, 0, 0, y)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 20
		lbl.TextColor3 = Color3.fromRGB(230, 235, 245)
		lbl.Text = line
		lbl.Parent = holder
		y += 34
	end

	TweenService:Create(holder, TweenInfo.new(18, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0.5, -360, 0, -y),
	}):Play()

	task.delay(20, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

return Credits
