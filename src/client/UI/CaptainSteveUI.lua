--!strict
--[[ Captain Steve hub panel — smash personas for Sunburn, upgrade rarity. ]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Personas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personas"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local CaptainSteveUI = {}
local lastState = nil

function CaptainSteveUI.SetState(s)
	lastState = s
end

function CaptainSteveUI.Open()
	if not lastState then
		return
	end
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Steve")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Steve"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 45
	gui.Parent = pg

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 520, 0, 420)
	panel.Position = UDim2.new(0.5, -260, 0.5, -210)
	panel.BackgroundColor3 = Color3.fromRGB(24, 28, 38)
	panel.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 8)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextColor3 = Color3.fromRGB(255, 220, 140)
	title.Text = "Captain Steve — Pelican Upgrades"
	title.Parent = panel

	local sub = Instance.new("TextLabel")
	sub.Size = UDim2.new(1, -20, 0, 40)
	sub.Position = UDim2.new(0, 10, 0, 48)
	sub.BackgroundTransparency = 1
	sub.Font = Enum.Font.Gotham
	sub.TextWrapped = true
	sub.TextSize = 14
	sub.TextColor3 = Color3.fromRGB(190, 200, 220)
	sub.Text = "Smash unwanted personas → Sunburn. Upgrade Common→Rare→Unique→Legendary. Sunburn: " .. tostring(lastState.sunburn)
	sub.Parent = panel

	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -20, 1, -120)
	scroll.Position = UDim2.new(0, 10, 0, 95)
	scroll.BackgroundTransparency = 1
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 6
	scroll.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 6)
	layout.Parent = scroll

	for id, unlocked in lastState.unlockedPersonas do
		if unlocked then
			local def = Personas.Get(id)
			local rarity = lastState.personaRarity[id] or "Common"
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, -10, 0, 56)
			row.BackgroundColor3 = Color3.fromRGB(35, 40, 52)
			row.Parent = scroll
			local rc = Instance.new("UICorner")
			rc.CornerRadius = UDim.new(0, 8)
			rc.Parent = row

			local nm = Instance.new("TextLabel")
			nm.Size = UDim2.new(0.45, 0, 1, 0)
			nm.Position = UDim2.new(0, 8, 0, 0)
			nm.BackgroundTransparency = 1
			nm.Font = Enum.Font.GothamBold
			nm.TextSize = 16
			nm.TextXAlignment = Enum.TextXAlignment.Left
			nm.TextColor3 = Color3.new(1, 1, 1)
			nm.Text = (if def then def.name else id) .. "  (" .. rarity .. ")"
			nm.Parent = row

			local up = Instance.new("TextButton")
			up.Size = UDim2.new(0, 110, 0, 36)
			up.Position = UDim2.new(1, -240, 0.5, -18)
			up.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
			up.Font = Enum.Font.GothamBold
			up.TextSize = 14
			up.TextColor3 = Color3.new(1, 1, 1)
			up.Text = "Upgrade"
			up.Parent = row
			local uc = Instance.new("UICorner")
			uc.CornerRadius = UDim.new(0, 6)
			uc.Parent = up
			up.MouseButton1Click:Connect(function()
				Remotes.Get("UpgradePersona"):FireServer(id)
				task.delay(0.2, function()
					gui:Destroy()
				end)
			end)

			local smash = Instance.new("TextButton")
			smash.Size = UDim2.new(0, 110, 0, 36)
			smash.Position = UDim2.new(1, -120, 0.5, -18)
			smash.BackgroundColor3 = Color3.fromRGB(180, 70, 50)
			smash.Font = Enum.Font.GothamBold
			smash.TextSize = 14
			smash.TextColor3 = Color3.new(1, 1, 1)
			smash.Text = "Smash"
			smash.Parent = row
			local sc = Instance.new("UICorner")
			sc.CornerRadius = UDim.new(0, 6)
			sc.Parent = smash
			smash.MouseButton1Click:Connect(function()
				Remotes.Get("SmashPersona"):FireServer(id)
				task.delay(0.2, function()
					gui:Destroy()
				end)
			end)
		end
	end

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 120, 0, 36)
	close.Position = UDim2.new(0.5, -60, 1, -42)
	close.BackgroundColor3 = Color3.fromRGB(70, 70, 80)
	close.Font = Enum.Font.GothamBold
	close.Text = "Close"
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Parent = panel
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 8)
	cc.Parent = close
	close.MouseButton1Click:Connect(function()
		gui:Destroy()
	end)
end

return CaptainSteveUI
