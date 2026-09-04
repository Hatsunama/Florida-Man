--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local Newspaper = {}
local InputController

function Newspaper.BindInput(ctrl)
	InputController = ctrl
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end

function Newspaper.Show(payload: any)
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Newspaper")
	if old then
		old:Destroy()
	end
	if InputController then
		InputController.SetEnabled(false)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Newspaper"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 50
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.45
	dim.Parent = gui

	local paper = Instance.new("Frame")
	paper.Size = UDim2.new(0, 640, 0, 420)
	paper.Position = UDim2.new(0.5, -320, 0.5, -210)
	paper.BackgroundColor3 = Color3.fromRGB(235, 225, 200)
	paper.Parent = gui
	corner(paper, 4)

	local masthead = Instance.new("TextLabel")
	masthead.Size = UDim2.new(1, -40, 0, 36)
	masthead.Position = UDim2.new(0, 20, 0, 16)
	masthead.BackgroundTransparency = 1
	masthead.Font = Enum.Font.GothamBold
	masthead.TextSize = 22
	masthead.TextColor3 = Color3.fromRGB(30, 30, 30)
	masthead.Text = "🌴 THE DAILY SWAMP  ·  BREAKING"
	masthead.Parent = paper

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -40, 0, 3)
	line.Position = UDim2.new(0, 20, 0, 56)
	line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	line.BorderSizePixel = 0
	line.Parent = paper

	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, -40, 0, 110)
	head.Position = UDim2.new(0, 20, 0, 70)
	head.BackgroundTransparency = 1
	head.Font = Enum.Font.GothamBold
	head.TextWrapped = true
	head.TextSize = 26
	head.TextColor3 = Color3.fromRGB(20, 20, 20)
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.TextYAlignment = Enum.TextYAlignment.Top
	head.Text = payload.headline or "BREAKING"
	head.Parent = paper

	local blurb = Instance.new("TextLabel")
	blurb.Size = UDim2.new(1, -40, 0, 80)
	blurb.Position = UDim2.new(0, 20, 0, 190)
	blurb.BackgroundTransparency = 1
	blurb.Font = Enum.Font.Gotham
	blurb.TextWrapped = true
	blurb.TextSize = 18
	blurb.TextColor3 = Color3.fromRGB(50, 50, 50)
	blurb.TextXAlignment = Enum.TextXAlignment.Left
	blurb.Text = (payload.blurb or "") .. "\n\nCleared: " .. tostring(payload.stageName) .. " → Next: " .. tostring(payload.nextName)
	blurb.Parent = paper

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 280, 0, 48)
	btn.Position = UDim2.new(0.5, -140, 1, -70)
	btn.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = if payload.isFinale then "TO CREDITS" else "CONTINUE → ITEM DRAFT"
	btn.Parent = paper
	corner(btn, 8)
	btn.MouseButton1Click:Connect(function()
		gui:Destroy()
		if InputController then
			InputController.SetEnabled(true)
		end
		Remotes.Get("ContinueFromNewspaper"):FireServer()
	end)
end

return Newspaper
