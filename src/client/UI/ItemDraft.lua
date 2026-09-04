--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local ItemDraft = {}
local InputController

function ItemDraft.BindInput(ctrl)
	InputController = ctrl
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = p
end

function ItemDraft.Show(picks: { any })
	local player = Players.LocalPlayer
	local pg = player:WaitForChild("PlayerGui")
	local old = pg:FindFirstChild("FM_Draft")
	if old then
		old:Destroy()
	end
	if InputController then
		InputController.SetEnabled(false)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "FM_Draft"
	gui.IgnoreGuiInset = true
	gui.DisplayOrder = 55
	gui.Parent = pg

	local dim = Instance.new("Frame")
	dim.Size = UDim2.fromScale(1, 1)
	dim.BackgroundColor3 = Color3.new(0, 0, 0)
	dim.BackgroundTransparency = 0.4
	dim.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(0, 600, 0, 40)
	title.Position = UDim2.new(0.5, -300, 0.18, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextSize = 28
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Text = "END OF STAGE — pick 1 item"
	title.Parent = gui

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.new(0, 600, 0, 28)
	hint.Position = UDim2.new(0.5, -300, 0.18, 40)
	hint.BackgroundTransparency = 1
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 16
	hint.TextColor3 = Color3.fromRGB(200, 210, 230)
	hint.Text = "Inscriptions: HUMID · FERAL · LUCKY · GREASY · HEROIC · CHAOS  —  3 matching = set bonus"
	hint.Parent = gui

	for i, it in picks do
		local card = Instance.new("TextButton")
		card.Size = UDim2.new(0, 200, 0, 260)
		card.Position = UDim2.new(0.5, -320 + (i - 1) * 220, 0.35, 0)
		card.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
		card.AutoButtonColor = true
		card.Text = ""
		card.Parent = gui
		corner(card, 12)
		local st = Instance.new("UIStroke")
		st.Color = Util.RarityColor(it.rarity)
		st.Thickness = if it.rarity == "Legendary" then 5 elseif it.rarity == "Unique" then 4 else 3
		st.Parent = card

		local rarity = Instance.new("TextLabel")
		rarity.Size = UDim2.new(1, -12, 0, 24)
		rarity.Position = UDim2.new(0, 6, 0, 10)
		rarity.BackgroundTransparency = 1
		rarity.Font = Enum.Font.GothamBold
		rarity.TextSize = 14
		rarity.TextColor3 = Util.RarityColor(it.rarity)
		rarity.Text = string.upper(it.rarity)
		rarity.Parent = card

		local name = Instance.new("TextLabel")
		name.Size = UDim2.new(1, -12, 0, 48)
		name.Position = UDim2.new(0, 6, 0, 40)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextWrapped = true
		name.TextSize = 20
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = it.name
		name.Parent = card

		local tag = Instance.new("TextLabel")
		tag.Size = UDim2.new(1, -12, 0, 22)
		tag.Position = UDim2.new(0, 6, 0, 92)
		tag.BackgroundTransparency = 1
		tag.Font = Enum.Font.GothamBold
		tag.TextSize = 14
		tag.TextColor3 = Util.InscriptionColor(it.inscription)
		tag.Text = "[" .. it.inscription .. "]"
		tag.Parent = card

		local desc = Instance.new("TextLabel")
		desc.Size = UDim2.new(1, -16, 0, 100)
		desc.Position = UDim2.new(0, 8, 0, 120)
		desc.BackgroundTransparency = 1
		desc.Font = Enum.Font.Gotham
		desc.TextWrapped = true
		desc.TextSize = 14
		desc.TextColor3 = Color3.fromRGB(200, 205, 220)
		desc.TextYAlignment = Enum.TextYAlignment.Top
		desc.Text = it.description .. "\n\n" .. it.statText
		desc.Parent = card

		card.MouseButton1Click:Connect(function()
			gui:Destroy()
			if InputController then
				InputController.SetEnabled(true)
			end
			Remotes.Get("PickDraftItem"):FireServer(it.id)
		end)
	end
end

return ItemDraft
