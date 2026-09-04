--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Personas = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Personas"))
local Items = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items"))
local Weapons = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Weapons"))
local Stages = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Stages"))
local Util = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Util"))
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Settings"))

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
local swapCdLbl: TextLabel
local skillCdLbl: TextLabel
local state = nil
local lastServerNow = 0
local lastLocalAt = 0

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

	local hpBg = Instance.new("Frame")
	hpBg.Name = "HP"
	hpBg.Size = UDim2.new(0, 280, 0, 28)
	hpBg.Position = UDim2.new(0, 20, 1, -120)
	hpBg.BackgroundColor3 = Color3.fromRGB(30, 20, 20)
	hpBg.Parent = gui
	corner(hpBg, 8)
	hpFill = Instance.new("Frame")
	hpFill.Size = UDim2.fromScale(1, 1)
	hpFill.BackgroundColor3 = Color3.fromRGB(40, 200, 90)
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

	local cycleBtn = Instance.new("TextButton")
	cycleBtn.Name = "FM_WeaponCycle"
	cycleBtn.Size = UDim2.new(0, 72, 0, 24)
	cycleBtn.Position = UDim2.new(0, 300, 1, -60)
	cycleBtn.BackgroundColor3 = Color3.fromRGB(28, 36, 48)
	cycleBtn.Font = Enum.Font.GothamBold
	cycleBtn.TextSize = 12
	cycleBtn.TextColor3 = Color3.fromRGB(180, 220, 255)
	cycleBtn.Text = "NEXT WPN"
	cycleBtn.AutoButtonColor = true
	cycleBtn.Parent = gui
	corner(cycleBtn, 6)
	stroke(cycleBtn, Color3.fromRGB(100, 140, 180), 1)
	cycleBtn.MouseButton1Click:Connect(function()
		pcall(function()
			local InputController = require(script.Parent.Parent.Controllers:WaitForChild("InputController"))
			InputController.CycleWeapon(1)
		end)
	end)

	swapCdLbl = Instance.new("TextLabel")
	swapCdLbl.Size = UDim2.new(0, 200, 0, 22)
	swapCdLbl.Position = UDim2.new(0, 310, 1, -88)
	swapCdLbl.BackgroundTransparency = 1
	swapCdLbl.Font = Enum.Font.GothamBold
	swapCdLbl.TextSize = 16
	swapCdLbl.TextXAlignment = Enum.TextXAlignment.Left
	swapCdLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
	swapCdLbl.Text = "Swap: Ready (Q)"
	swapCdLbl.Parent = gui

	skillCdLbl = Instance.new("TextLabel")
	skillCdLbl.Size = UDim2.new(0, 200, 0, 22)
	skillCdLbl.Position = UDim2.new(0, 310, 1, -66)
	skillCdLbl.BackgroundTransparency = 1
	skillCdLbl.Font = Enum.Font.GothamBold
	skillCdLbl.TextSize = 16
	skillCdLbl.TextXAlignment = Enum.TextXAlignment.Left
	skillCdLbl.TextColor3 = Color3.fromRGB(160, 220, 255)
	skillCdLbl.Text = "Skill: Ready (K)"
	skillCdLbl.Parent = gui

	local function syncSetting(key: string, value: boolean | string)
		pcall(function()
			local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
			Remotes.Get("SyncSettings"):FireServer(key, value)
		end)
		pcall(function()
			local AudioDirector = require(script.Parent.Parent.Controllers:WaitForChild("AudioDirector"))
			AudioDirector.Play("SFX_UIClick", { volume = 0.3 })
			if key == "MuteMaster" or key == "MuteSFX" or key == "MuteAmbience" then
				AudioDirector.ApplyMute()
			end
		end)
	end

	local function openOptions()
		local pg = Players.LocalPlayer:WaitForChild("PlayerGui")
		local old = pg:FindFirstChild("FM_Options")
		if old then
			old:Destroy()
			return
		end
		local opt = Instance.new("ScreenGui")
		opt.Name = "FM_Options"
		opt.IgnoreGuiInset = true
		opt.DisplayOrder = 55
		opt.ResetOnSpawn = false
		opt.Parent = pg

		local dim = Instance.new("TextButton")
		dim.Size = UDim2.fromScale(1, 1)
		dim.BackgroundColor3 = Color3.new(0, 0, 0)
		dim.BackgroundTransparency = 0.45
		dim.Text = ""
		dim.AutoButtonColor = false
		dim.Parent = opt
		dim.MouseButton1Click:Connect(function()
			opt:Destroy()
		end)

		local panel = Instance.new("Frame")
		panel.Size = UDim2.new(0, 360, 0, 480)
		panel.Position = UDim2.new(1, -380, 0, 56)
		panel.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
		panel.Active = true
		panel.Parent = opt
		corner(panel, 12)
		stroke(panel, Color3.fromRGB(255, 190, 80), 2)

		local title = Instance.new("TextLabel")
		title.Size = UDim2.new(1, -24, 0, 36)
		title.Position = UDim2.new(0, 12, 0, 10)
		title.BackgroundTransparency = 1
		title.Font = Enum.Font.GothamBold
		title.TextSize = 20
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextColor3 = Color3.fromRGB(255, 220, 140)
		title.Text = "Options / Accessibility"
		title.Parent = panel

		local list = Instance.new("Frame")
		list.Size = UDim2.new(1, -24, 1, -70)
		list.Position = UDim2.new(0, 12, 0, 52)
		list.BackgroundTransparency = 1
		list.Parent = panel
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = list

		local function rowBtn(label: string, valueText: string, onClick: () -> ()): TextButton
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 48) -- ≥44px mobile hit target
			b.BackgroundColor3 = Color3.fromRGB(34, 40, 54)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 15
			b.TextColor3 = Color3.fromRGB(230, 235, 245)
			b.TextXAlignment = Enum.TextXAlignment.Left
			b.AutoButtonColor = true
			b.Text = "  " .. label .. "  ·  " .. valueText
			b.Parent = list
			corner(b, 8)
			stroke(b, Color3.fromRGB(100, 120, 160), 1)
			b.MouseButton1Click:Connect(onClick)
			return b
		end

		local function boolRow(label: string, key: string)
			local b: TextButton
			local function refresh()
				local on = Settings.GetBool(Players.LocalPlayer, key)
				b.Text = "  " .. label .. "  ·  " .. (if on then "ON" else "OFF")
			end
			b = rowBtn(label, "…", function()
				local nextVal = Settings.Toggle(Players.LocalPlayer, key)
				syncSetting(key, nextVal)
				refresh()
				HUD.Toast(label .. (if nextVal then ": ON" else ": OFF"))
			end)
			refresh()
		end

		boolRow("Screen shake", "ShakeEnabled")
		boolRow("Colorblind telegraphs", "ColorblindTelegraphs")
		boolRow("Mute master", "MuteMaster")
		boolRow("Mute SFX", "MuteSFX")
		boolRow("Mute ambience", "MuteAmbience")
		boolRow("Reduce motion", "ReduceMotion")

		local speedBtn: TextButton
		local function refreshSpeed()
			local sp = Settings.GetTextSpeed(Players.LocalPlayer)
			speedBtn.Text = "  Tagline text speed  ·  " .. string.upper(sp)
		end
		speedBtn = rowBtn("Tagline text speed", "…", function()
			local nextVal = Settings.CycleTextSpeed(Players.LocalPlayer)
			syncSetting("TextSpeed", nextVal)
			refreshSpeed()
			HUD.Toast("Text speed: " .. nextVal)
		end)
		refreshSpeed()

		local close = Instance.new("TextButton")
		close.Size = UDim2.new(1, 0, 0, 44)
		close.BackgroundColor3 = Color3.fromRGB(70, 74, 88)
		close.Font = Enum.Font.GothamBold
		close.TextSize = 16
		close.TextColor3 = Color3.new(1, 1, 1)
		close.Text = "Close"
		close.Parent = list
		corner(close, 8)
		close.MouseButton1Click:Connect(function()
			opt:Destroy()
		end)
	end

	local optBtn = Instance.new("TextButton")
	optBtn.Name = "FM_OptionsBtn"
	optBtn.Size = UDim2.new(0, 118, 0, 44) -- ≥44px
	optBtn.Position = UDim2.new(1, -136, 0, 10)
	optBtn.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
	optBtn.Font = Enum.Font.GothamBold
	optBtn.TextSize = 14
	optBtn.TextColor3 = Color3.fromRGB(220, 230, 245)
	optBtn.Text = "Options"
	optBtn.AutoButtonColor = true
	optBtn.Parent = gui
	corner(optBtn, 8)
	stroke(optBtn, Color3.fromRGB(120, 140, 180), 1)
	optBtn.MouseButton1Click:Connect(function()
		openOptions()
	end)

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

	local function personaSlot(x: number): Frame
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0, 148, 0, 64)
		f.Position = UDim2.new(0, x, 1, -200)
		f.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
		f.Parent = gui
		corner(f, 10)
		stroke(f, Color3.fromRGB(255, 200, 80), 2)

		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 44, 0, 44)
		icon.Position = UDim2.new(0, 8, 0.5, -22)
		icon.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		icon.Parent = f
		local iconCorner = Instance.new("UICorner")
		iconCorner.CornerRadius = UDim.new(1, 0)
		iconCorner.Parent = icon
		local iconStroke = Instance.new("UIStroke")
		iconStroke.Color = Color3.fromRGB(255, 255, 255)
		iconStroke.Thickness = 2
		iconStroke.Transparency = 0.25
		iconStroke.Parent = icon
		local img = Instance.new("ImageLabel")
		img.Name = "FallbackImage"
		img.Size = UDim2.fromScale(1, 1)
		img.BackgroundTransparency = 1
		img.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
		img.ImageTransparency = 0.85
		img.ScaleType = Enum.ScaleType.Fit
		img.Parent = icon
		local imgCorner = Instance.new("UICorner")
		imgCorner.CornerRadius = UDim.new(1, 0)
		imgCorner.Parent = img
		local glyph = Instance.new("Frame")
		glyph.Name = "Glyph"
		glyph.Size = UDim2.new(0, 16, 0, 16)
		glyph.Position = UDim2.new(0.5, -8, 0.5, -8)
		glyph.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		glyph.ZIndex = 2
		glyph.Parent = icon
		local glyphCorner = Instance.new("UICorner")
		glyphCorner.CornerRadius = UDim.new(1, 0)
		glyphCorner.Parent = glyph
		local name = Instance.new("TextLabel")
		name.Name = "Name"
		name.Size = UDim2.new(1, -64, 0.55, 0)
		name.Position = UDim2.new(0, 58, 0.05, 0)
		name.BackgroundTransparency = 1
		name.Font = Enum.Font.GothamBold
		name.TextScaled = true
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.TextColor3 = Color3.new(1, 1, 1)
		name.Text = "—"
		name.Parent = f
		local sub = Instance.new("TextLabel")
		sub.Name = "Sub"
		sub.Size = UDim2.new(1, -64, 0.35, 0)
		sub.Position = UDim2.new(0, 58, 0.6, 0)
		sub.BackgroundTransparency = 1
		sub.Font = Enum.Font.Gotham
		sub.TextScaled = true
		sub.TextXAlignment = Enum.TextXAlignment.Left
		sub.TextColor3 = Color3.fromRGB(200, 200, 210)
		sub.Text = ""
		sub.Parent = f
		return f
	end
	p1 = personaSlot(20)
	p2 = personaSlot(178)

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
	controlsLbl.Text = "A/D move · Space jump · Shift dash · Click/J attack · K skill · Q swap · 1/2/3 weapons · E prompt"
	controlsLbl.Parent = gui
	corner(controlsLbl, 8)

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
	local icon = frame:FindFirstChild("Icon") :: Frame?
	local glyph = icon and icon:FindFirstChild("Glyph") :: Frame?
	if not personaId then
		name.Text = "Empty"
		sub.Text = "Unlock more"
		frame.BackgroundColor3 = Color3.fromRGB(25, 28, 36)
		if icon then
			icon.BackgroundColor3 = Color3.fromRGB(60, 62, 70)
		end
		if glyph then
			glyph.BackgroundColor3 = Color3.fromRGB(120, 120, 130)
		end
		return
	end
	local def = Personas.Get(personaId)
	name.Text = if def then def.name else personaId
	sub.Text = (rarity or "Common") .. (if active then " · ACTIVE" else "")
	frame.BackgroundColor3 = if def then def.color:Lerp(Color3.fromRGB(20, 20, 25), 0.45) else Color3.fromRGB(25, 28, 36)
	if icon and def then
		icon.BackgroundColor3 = def.color
		if glyph then
			glyph.BackgroundColor3 = def.accent
		end
	elseif icon then
		icon.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	end
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

function HUD.RefreshCds()
	if not state or not swapCdLbl then
		return
	end
	local nowApprox = lastServerNow + (os.clock() - lastLocalAt)
	local swapLeft = math.max(0, (state.swapReadyAt or 0) - nowApprox)
	local skillLeft = math.max(0, (state.skillReadyAt or 0) - nowApprox)
	if swapLeft <= 0.05 then
		swapCdLbl.Text = "Swap: Ready (Q)"
		swapCdLbl.TextColor3 = Color3.fromRGB(255, 220, 120)
	else
		swapCdLbl.Text = string.format("Swap CD: %.1fs", swapLeft)
		swapCdLbl.TextColor3 = Color3.fromRGB(180, 140, 80)
	end
	if skillLeft <= 0.05 then
		skillCdLbl.Text = "Skill: Ready (K)"
		skillCdLbl.TextColor3 = Color3.fromRGB(160, 220, 255)
	else
		skillCdLbl.Text = string.format("Skill CD: %.1fs", skillLeft)
		skillCdLbl.TextColor3 = Color3.fromRGB(100, 140, 180)
	end
end

function HUD.Update(s: any)
	state = s
	if not s then
		return
	end
	if typeof(s.serverNow) == "number" then
		lastServerNow = s.serverNow
		lastLocalAt = os.clock()
	end
	HUD.RefreshCds()
	local pct = if s.maxHp > 0 then s.hp / s.maxHp else 0
	hpFill.Size = UDim2.fromScale(math.clamp(pct, 0, 1), 1)
	hpFill.BackgroundColor3 = if pct > 0.5 then Color3.fromRGB(40, 200, 90) elseif pct > 0.25 then Color3.fromRGB(230, 180, 50) else Color3.fromRGB(220, 60, 60)
	hpText.Text = string.format("HP %d/%d", math.floor(s.hp), math.floor(s.maxHp))
	sunburnLbl.Text = string.format("☀️ Sunburn: %d", s.sunburn or 0)
	if weaponLbl then
		local w = Weapons.Get(s.weaponId or "BareHands")
		local kind = if w then w.kind else "?"
		local slotHint = ""
		if typeof(s.unlockedWeapons) == "table" then
			local n = 0
			for _, def in Weapons.List do
				if s.unlockedWeapons[def.id] then
					n += 1
					if def.id == (s.weaponId or "BareHands") and n <= 3 then
						slotHint = " [" .. tostring(n) .. "]"
					end
				end
			end
		end
		weaponLbl.Text = "Weapon: " .. (if w then w.name else tostring(s.weaponId)) .. " [" .. kind .. "]" .. slotHint
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

task.spawn(function()
	while gui and gui.Parent do
		HUD.RefreshCds()
		task.wait(0.1)
	end
end)

return HUD
