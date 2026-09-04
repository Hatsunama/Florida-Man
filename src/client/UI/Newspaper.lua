--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

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
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 1
	dim.Active = true -- Phase 1: lock world clicks while open
	dim.ZIndex = 1
	dim.Parent = gui

	local paper = Instance.new("Frame")
	paper.Size = UDim2.new(0, 680, 0, 520)
	paper.Position = UDim2.new(0.5, -340, 0.5, -250)
	paper.BackgroundColor3 = Color3.fromRGB(235, 225, 200)
	paper.BackgroundTransparency = 1
	paper.Active = true
	paper.ZIndex = 5
	paper.Parent = gui
	corner(paper, 4)
	local scale = Instance.new("UIScale")
	scale.Scale = 0.82
	scale.Parent = paper
	-- Snappy open: fade + scale punch
	TweenService:Create(dim, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 0.4 }):Play()
	TweenService:Create(paper, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { BackgroundTransparency = 0, Position = UDim2.new(0.5, -340, 0.5, -260) }):Play()
	TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

	local breaking = Instance.new("TextLabel")
	breaking.Size = UDim2.new(0, 140, 0, 28)
	breaking.Position = UDim2.new(0, 20, 0, 14)
	breaking.BackgroundColor3 = Color3.fromRGB(180, 20, 30)
	breaking.Font = Enum.Font.GothamBold
	breaking.TextSize = 16
	breaking.TextColor3 = Color3.new(1, 1, 1)
	breaking.Text = "BREAKING"
	breaking.Parent = paper
	corner(breaking, 4)

	local masthead = Instance.new("TextLabel")
	masthead.Size = UDim2.new(1, -180, 0, 28)
	masthead.Position = UDim2.new(0, 170, 0, 14)
	masthead.BackgroundTransparency = 1
	masthead.Font = Enum.Font.Antique
	masthead.TextSize = 20
	masthead.TextXAlignment = Enum.TextXAlignment.Left
	masthead.TextColor3 = Color3.fromRGB(30, 30, 30)
	masthead.Text = "THE DAILY SWAMP  ·  " .. tostring(payload.actName or "FLORIDA")
	masthead.Parent = paper

	local line = Instance.new("Frame")
	line.Size = UDim2.new(1, -40, 0, 3)
	line.Position = UDim2.new(0, 20, 0, 50)
	line.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	line.BorderSizePixel = 0
	line.Parent = paper

	local head = Instance.new("TextLabel")
	head.Size = UDim2.new(1, -40, 0, 100)
	head.Position = UDim2.new(0, 20, 0, 60)
	head.BackgroundTransparency = 1
	head.Font = Enum.Font.Antique
	head.TextWrapped = true
	head.TextSize = 26
	head.TextColor3 = Color3.fromRGB(20, 20, 20)
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.TextYAlignment = Enum.TextYAlignment.Top
	head.Text = payload.headline or "BREAKING"
	head.Parent = paper

	local beat = Instance.new("TextLabel")
	beat.Size = UDim2.new(1, -40, 0, 40)
	beat.Position = UDim2.new(0, 20, 0, 160)
	beat.BackgroundTransparency = 1
	beat.Font = Enum.Font.GothamMedium
	beat.TextWrapped = true
	beat.TextSize = 15
	beat.TextColor3 = Color3.fromRGB(100, 40, 40)
	beat.TextXAlignment = Enum.TextXAlignment.Left
	beat.Text = payload.storyBeat or ""
	beat.Parent = paper

	-- Phase 4: act art panels (colored Frames + beat text from Story.lua)
	local panels = payload.panels
	if typeof(panels) == "table" then
		for i, panel in panels do
			if i > 3 then
				break
			end
			local c = panel.color or { 80, 120, 160 }
			local frame = Instance.new("Frame")
			frame.Size = UDim2.new(0, 200, 0, 88)
			frame.Position = UDim2.new(0, 20 + (i - 1) * 212, 0, 205)
			frame.BackgroundColor3 = Color3.fromRGB(c[1] or 80, c[2] or 120, c[3] or 160)
			frame.BorderSizePixel = 0
			frame.Parent = paper
			corner(frame, 6)
			local pt = Instance.new("TextLabel")
			pt.Size = UDim2.new(1, -12, 0, 22)
			pt.Position = UDim2.new(0, 6, 0, 6)
			pt.BackgroundTransparency = 1
			pt.Font = Enum.Font.GothamBold
			pt.TextSize = 14
			pt.TextColor3 = Color3.new(1, 1, 1)
			pt.TextXAlignment = Enum.TextXAlignment.Left
			pt.Text = tostring(panel.title or ("PANEL " .. tostring(i)))
			pt.Parent = frame
			local pb = Instance.new("TextLabel")
			pb.Size = UDim2.new(1, -12, 0, 52)
			pb.Position = UDim2.new(0, 6, 0, 30)
			pb.BackgroundTransparency = 1
			pb.Font = Enum.Font.Gotham
			pb.TextSize = 12
			pb.TextWrapped = true
			pb.TextColor3 = Color3.fromRGB(245, 245, 245)
			pb.TextXAlignment = Enum.TextXAlignment.Left
			pb.TextYAlignment = Enum.TextYAlignment.Top
			pb.Text = tostring(panel.text or "")
			pb.Parent = frame
		end
	end

	local steve = Instance.new("TextLabel")
	steve.Size = UDim2.new(1, -40, 0, 28)
	steve.Position = UDim2.new(0, 20, 0, 302)
	steve.BackgroundTransparency = 1
	steve.Font = Enum.Font.GothamMedium
	steve.TextSize = 13
	steve.TextColor3 = Color3.fromRGB(60, 80, 40)
	steve.TextXAlignment = Enum.TextXAlignment.Left
	steve.TextTruncate = Enum.TextTruncate.AtEnd
	steve.Text = if payload.steveLine then ('Steve: "' .. tostring(payload.steveLine) .. '"') else ""
	steve.Parent = paper

	local blurb = Instance.new("TextLabel")
	blurb.Size = UDim2.new(1, -40, 0, 56)
	blurb.Position = UDim2.new(0, 20, 0, 332)
	blurb.BackgroundTransparency = 1
	blurb.Font = Enum.Font.Gotham
	blurb.TextWrapped = true
	blurb.TextSize = 15
	blurb.TextColor3 = Color3.fromRGB(50, 50, 50)
	blurb.TextXAlignment = Enum.TextXAlignment.Left
	blurb.Text = (payload.blurb or "") .. "\nCleared: " .. tostring(payload.stageName) .. " → Next: " .. tostring(payload.nextName)
	blurb.Parent = paper

	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0, 300, 0, 48)
	btn.Position = UDim2.new(0.5, -150, 1, -70)
	btn.BackgroundColor3 = Color3.fromRGB(40, 90, 160)
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 20
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Active = true
	btn.Selectable = true
	btn.ZIndex = 20
	btn.AutoButtonColor = true
	btn.Text = if payload.isFinale then "TO SUNRISE CREDITS" else "CONTINUE → ITEM DRAFT"
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
