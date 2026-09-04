--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Personas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personas"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons"))
local Stages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stages"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))

local HUD = {}
local gui: ScreenGui
local hpFill: Frame
local hpText: TextLabel
local stageText: TextLabel
local toastLbl: TextLabel
local sunburnLbl: TextLabel
local weaponLbl: TextLabel
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
	hpFill.BackgroundColor3 = Color3.fromRGB(40, 200, 90) -- Florida Dew green
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

	weaponLbl = Instance.new("TextLabel")
	weaponLbl.Size = UDim2.new(0, 280, 0, 24)
	weaponLbl.Position = UDim2.new(0, 20, 1, -60)
	weaponLbl.BackgroundTransparency = 1
	weaponLbl.Font = Enum.Font.GothamBold
	weaponLbl.TextSize = 16
	weaponLbl.TextXAlignment = Enum.TextXAlignment.Left
	weaponLbl.TextColor3 = Color3.fromRGB(180, 220, 255)
	weaponLbl.Text = "Weapon: Bare Hands"
	weaponLbl.Parent = gui

	local bossBar = Instance.new("Frame")
	bossBar.Name = "BossBar"
	bossBar.Size = UDim2.new(0.5, 0, 0, 18)
	bossBar.Position = UDim2.new(0.25, 0, 0, 60)
	bossBar.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	bossBar.Visible = false
	bossBar.Parent = gui
	corner(bossBar, 6)
	local bossFill = Instance.new("Frame")
	bossFill.Name = "Fill"
	bossFill.Size = UDim2.fromScale(1, 1)
	bossFill.BackgroundColor3 = Color3.fromRGB(255, 80, 60)
	bossFill.Parent = bossBar
	corner(bossFill, 6)
	local bossText = Instance.new("TextLabel")
	bossText.Name = "BossName"
	bossText.Size = UDim2.fromScale(1, 1)
	bossText.BackgroundTransparency = 1
	bossText.Font = Enum.Font.GothamBold
	bossText.TextScaled = true
	bossText.TextColor3 = Color3.new(1, 1, 1)
	bossText.Text = "BOSS"
	bossText.ZIndex = 2
	bossText.Parent = bossBar

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
	controlsLbl.Text = "A/D lane · Space jump · Shift dash · Click/J attack · K skill · Q swap · E interact"
	controlsLbl.Parent = gui
	corner(controlsLbl, 8)
	-- Fade controls after first few seconds at hub
	task.delay(8, function()
		if controlsLbl and controlsLbl.Parent then
			local TweenService = game:GetService("TweenService")
			TweenService:Create(controlsLbl, TweenInfo.new(2), { BackgroundTransparency = 1, TextTransparency = 1 }):Play()
		end
	end)

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
		local rcol = Color3.fromRGB(120, 120, 140)
		if rarity == "Rare" then
			rcol = Color3.fromRGB(80, 140, 255)
		elseif rarity == "Unique" then
			rcol = Color3.fromRGB(180, 80, 255)
		elseif rarity == "Legendary" then
			rcol = Color3.fromRGB(255, 200, 60)
		end
		s.Color = if active then Color3.fromRGB(255, 230, 100) else rcol
		s.Thickness = if active then 3 else 2
	end
end

function HUD.Update(s: any)
	state = s
	if not s then
		return
	end
	local pct = if s.maxHp > 0 then s.hp / s.maxHp else 0
	hpFill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
	hpFill.BackgroundColor3 = if pct > 0.5 then Color3.fromRGB(40, 200, 90) elseif pct > 0.25 then Color3.fromRGB(230, 180, 50) else Color3.fromRGB(220, 60, 60)
	hpText.Text = string.format("HP %d/%d", math.floor(s.hp), math.floor(s.maxHp))
	sunburnLbl.Text = string.format("☀️ Sunburn: %d", s.sunburn or 0)
	if weaponLbl then
		local w = Weapons.Get(s.weaponId or "BareHands")
		weaponLbl.Text = "Weapon: " .. (if w then w.name else tostring(s.weaponId))
	end

	local stage = Stages.Get(s.stageId)
	local act = s.actName or ""
	if stage then
		if act ~= "" and not stage.isHub then
			stageText.Text = string.format("ACT %s — %s", tostring(s.actNumber or ""), stage.name)
		else
			stageText.Text = "FLORIDA MAN — " .. stage.name
		end
	else
		stageText.Text = "FLORIDA MAN"
	end
	if s.turtlesNeeded and s.turtlesNeeded > 0 then
		stageText.Text ..= string.format("  ·  Turtles %d/%d", s.turtlesRescued or 0, s.turtlesNeeded)
	end
	if s.hangoverActive then
		stageText.Text ..= "  ·  HANGOVER"
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
