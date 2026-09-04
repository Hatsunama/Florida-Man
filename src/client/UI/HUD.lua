--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Personas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personas"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local Stages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stages"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local HUD = {}
local gui: ScreenGui
local hpFill: Frame
local hpText: TextLabel
local stageText: TextLabel
local toastLbl: TextLabel
local sunburnLbl: TextLabel
local p1: Frame
local p2: Frame
local itemBar: Frame
local controlsLbl: TextLabel
local state = nil

local function corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 1.5
	s.Transparency = 0.3
	s.Parent = parent
end

function HUD.Init()
	local player = Players.LocalPlayer
	gui = Instance.new("ScreenGui")
	gui.Name = "FloridaManHUD"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Top stage banner
	local banner = Instance.new("Frame")
	banner.Size = UDim2.new(0.56, 0, 0, 42)
	banner.Position = UDim2.new(0.22, 0, 0, 12)
	banner.BackgroundColor3 = Color3.fromRGB(20, 24, 32)
	banner.BackgroundTransparency = 0.2
	banner.Parent = gui
	corner(banner, 10)
	stroke(banner, Color3.fromRGB(255, 180, 60), 2)
	stageText = Instance.new("TextLabel")
	stageText.Size = UDim2.fromScale(1, 1)
	stageText.BackgroundTransparency = 1
	stageText.Font = Enum.Font.GothamBold
	stageText.TextScaled = true
	stageText.TextColor3 = Color3.fromRGB(255, 230, 160)
	stageText.Text = "FLORIDA MAN — Dawn Bonfire"
	stageText.Parent = banner

	-- HP bar
	local hpBg = Instance.new("Frame")
	hpBg.Name = "HP"
	hpBg.Size = UDim2.new(0, 280, 0, 28)
	hpBg.Position = UDim2.new(0, 20, 1, -120)
	hpBg.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
	hpBg.Parent = gui
	corner(hpBg, 8)
	hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
	hpFill.Parent = hpBg
	corner(hpFill, 8)
	hpText = Instance.new("TextLabel")
	hpText.Size = UDim2.fromScale(1, 1)
	hpText.BackgroundTransparency = 1
	hpText.Font = Enum.Font.GothamBold
	hpText.TextScaled = true
	hpText.TextColor3 = Color3.new(1, 1, 1)
	hpText.TextStrokeTransparency = 0.4
	hpText.Text = "HP 100/100"
	hpText.ZIndex = 2
	hpText.Parent = hpBg

	sunburnLbl = Instance.new("TextLabel")
	sunburnLbl.Size = UDim2.new(0, 180, 0, 24)
	sunburnLbl.Position = UDim2.new(0, 20, 1, -88)
	sunburnLbl.BackgroundTransparency = 1
	sunburnLbl.Font = Enum.Font.GothamBold
	sunburnLbl.TextSize = 18
	sunburnLbl.TextXAlignment = Enum.TextXAlignment.Left
	sunburnLbl.TextColor3 = Color3.fromRGB(255, 170, 60)
	sunburnLbl.Text = "☀️ Sunburn: 0"
	sunburnLbl.Parent = gui

	-- Persona portraits
	local function personaSlot(x: number): Frame
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, 120, 0, 64)
		f.Position = UDim2.new(0, x, 1, -200)
		f.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
		f.Parent = gui
		corner(f, 10)
		stroke(f, Color3.fromRGB(255, 200, 80), 2)
		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.Size = UDim2.new(1, -8, 0.55, 0)
		name.Position = UDim2.new(0, 4, 0.05, 0)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = "—"
		name.Parent = f
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Size = UDim2.new(1, -8, 0.35, 0)
		sub.Position = UDim2.new(0, 4, 0.6, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextScaled = true
		sub.TextColor3 = Color3.fromRGB(200, 200, 210)
		sub.Text = ""
		sub.Parent = f
		return f
	end
	p1 = personaSlot(20)
	p2 = personaSlot(150)

	itemBar = Instance.new("Frame")
	itemBar.Size = UDim2.new(0, 420, 0, 36)
	itemBar.Position = UDim2.new(1, -440, 1, -120)
	itemBar.BackgroundColor3 = Color3.fromRGB(20, 22, 28)
	itemBar.BackgroundTransparency = 0.25
	itemBar.Parent = gui
	corner(itemBar, 8)
	local itemText = Instance.new("TextLabel")
	itemText.Name = "Items"
	itemText.Size = UDim2.fromScale(1, 1)
	itemText.BackgroundTransparency = 1
	itemText.Font = Enum.Font.Gotham
	itemText.TextScaled = true
	itemText.TextColor3 = Color3.fromRGB(220, 230, 255)
	itemText.Text = "Items: (none)"
	itemText.Parent = itemBar

	controlsLbl = Instance.new("TextLabel")
	controlsLbl.Size = UDim2.new(0, 520, 0, 40)
	controlsLbl.Position = UDim2.new(0.5, -260, 1, -48)
	controlsLbl.BackgroundColor3 = Color3.fromRGB(10, 12, 18)
	controlsLbl.BackgroundTransparency = 0.35
	controlsLbl.Font = Enum.Font.Gotham
	controlsLbl.TextScaled = true
	controlsLbl.TextColor3 = Color3.fromRGB(180, 190, 210)
	controlsLbl.Text = "WASD move · Shift dodge · Click/J attack · K skill · Q swap · E interact · Xbox: A dodge X attack Y skill B swap"
	controlsLbl.Parent = gui
	corner(controlsLbl, 8)

	toastLbl = Instance.new("TextLabel")
	toastLbl.Size = UDim2.new(0.6, 0, 0, 36)
	toastLbl.Position = UDim2.new(0.2, 0, 0, 64)
	toastLbl.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	toastLbl.BackgroundTransparency = 0.25
	toastLbl.Font = Enum.Font.GothamBold
	toastLbl.TextScaled = true
	toastLbl.TextColor3 = Color3.fromRGB(255, 240, 180)
	toastLbl.Text = ""
	toastLbl.Visible = false
	toastLbl.Parent = gui
	corner(toastLbl, 8)
end

function HUD.Toast(text: string)
	toastLbl.Text = text
	toastLbl.Visible = true
	task.delay(3.2, function()
		if toastLbl.Text == text then
			toastLbl.Visible = false
		end
	end)
end

local function updatePersonaFrame(frame: Frame, personaId: string?, active: boolean, rarity: string?)
	local name = frame:FindFirstChild("Name") :: TextLabel
	local sub = frame:FindFirstChild("Sub") :: TextLabel
	if not personaId then
		name.Text = "Empty"
		sub.Text = "Unlock more"
		frame.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
		return
	end
	local def = Personas.Get(personaId)
	name.Text = if def then def.name else personaId
	sub.Text = (rarity or "Common") .. (if active then " · ACTIVE" else "")
	frame.BackgroundColor3 = if def then def.color:Lerp(Color3.fromRGB(20, 20, 25), 0.45) else Color3.fromRGB(25, 28, 36)
	local s = frame:FindFirstChildOfClass("UIStroke")
	if s then
		s.Color = if active then Color3.fromRGB(255, 230, 100) else Color3.fromRGB(120, 120, 140)
		s.Thickness = if active then 3 else 1.5
	end
end

function HUD.Update(s: any)
	state = s
	if not s then
		return
	end
	local pct = if s.maxHp > 0 then s.hp / s.maxHp else 0
	hpFill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
	hpFill.BackgroundColor3 = if pct > 0.5 then Color3.fromRGB(60, 200, 100) elseif pct > 0.25 then Color3.fromRGB(230, 180, 50) else Color3.fromRGB(220, 60, 60)
	hpText.Text = string.format("HP %d/%d", math.floor(s.hp), math.floor(s.maxHp))
	sunburnLbl.Text = string.format("☀️ Sunburn: %d", s.sunburn or 0)

	local stage = Stages.Get(s.stageId)
	stageText.Text = if stage then ("FLORIDA MAN — " .. stage.name) else "FLORIDA MAN"
	if s.turtlesNeeded and s.turtlesNeeded > 0 then
		stageText.Text ..= string.format("  ·  Turtles %d/%d", s.turtlesRescued or 0, s.turtlesNeeded)
	end

	updatePersonaFrame(p1, s.personas[1], s.activePersona == 1, s.personaRarity[s.personas[1]])
	updatePersonaFrame(p2, s.personas[2], s.activePersona == 2, s.personas[2] and s.personaRarity[s.personas[2]])

	local names = {}
	for _, id in s.items do
		local it = Items.Get(id)
		table.insert(names, if it then it.name else id)
	end
	local itemText = itemBar:FindFirstChild("Items") :: TextLabel
	itemText.Text = if #names > 0 then ("Items: " .. table.concat(names, " · ")) else "Items: (none yet — draft between stages)"

	-- inscription hint
	local counts = Items.CountInscriptions(s.items)
	local setBits = {}
	for tag, n in counts do
		if n > 0 then
			table.insert(setBits, string.format("%s %d/3", tag, n))
		end
	end
	if #setBits > 0 then
		itemText.Text ..= "  |  " .. table.concat(setBits, ", ")
	end
end

return HUD
