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
	dim.BackgroundColor3 = Color3.fromRGB(5, 10, 18)
	dim.BackgroundTransparency = 0.15
	dim.Parent = gui

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0, 700, 0, 500)
	holder.Position = UDim2.new(0.5, -350, 1, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local y = 0
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, 0, 0, 60)
	title.Position = UDim2.new(0, 0, 0, y)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 42
	title.TextColor3 = Color3.fromRGB(255, 200, 80)
	title.Text = payload.title or "FLORIDA MAN"
	title.Parent = holder
	y += 80

	for _, line in payload.lines or {} do
		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, 0, 0, 32)
		lbl.Position = UDim2.new(0, 0, 0, y)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.Gotham
		lbl.TextSize = 20
		lbl.TextColor3 = Color3.fromRGB(220, 230, 240)
		lbl.Text = line
		lbl.Parent = holder
		y += 36
	end

	TweenService:Create(holder, TweenInfo.new(14, Enum.EasingStyle.Linear), {
		Position = UDim2.new(0.5, -350, 0, -y),
	}):Play()

	task.delay(16, function()
		if gui.Parent then
			gui:Destroy()
		end
	end)
end

return Credits
