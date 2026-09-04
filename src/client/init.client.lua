--!strict
--[[ Florida Man — client entry ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared", 30)
assert(Shared, "Shared missing — connect Rojo")

local Remotes = require(Shared:WaitForChild("Remotes"))

local Controllers = script:WaitForChild("Controllers")
local UI = script:WaitForChild("UI")

local InputController = require(Controllers:WaitForChild("InputController"))
local CameraController = require(Controllers:WaitForChild("CameraController"))
local MovementController = require(Controllers:WaitForChild("MovementController"))
local HUD = require(UI:WaitForChild("HUD"))
local Newspaper = require(UI:WaitForChild("Newspaper"))
local ItemDraft = require(UI:WaitForChild("ItemDraft"))
local Credits = require(UI:WaitForChild("Credits"))
local Tagline = require(UI:WaitForChild("Tagline"))
local CaptainSteveUI = require(UI:WaitForChild("CaptainSteveUI"))

HUD.Init()
MovementController.Start()
CameraController.Start()
InputController.BindMovement(MovementController)
InputController.Start()
Newspaper.BindInput(InputController)
ItemDraft.BindInput(InputController)

Remotes.Get("StateUpdate").OnClientEvent:Connect(function(state)
	HUD.Update(state)
	CaptainSteveUI.SetState(state)
	if state then
		if state.moveSpeed then
			MovementController.SetBaseSpeed(state.moveSpeed)
		end
		MovementController.SetHangover(state.hangoverActive == true)
	end
end)

Remotes.Get("Toast").OnClientEvent:Connect(function(text)
	HUD.Toast(tostring(text))
end)

Remotes.Get("ShowNewspaper").OnClientEvent:Connect(function(payload)
	Newspaper.Show(payload)
end)

Remotes.Get("ShowDraft").OnClientEvent:Connect(function(picks)
	ItemDraft.Show(picks)
end)

Remotes.Get("ShowTagline").OnClientEvent:Connect(function(text, speaker)
	Tagline.Show(tostring(text), speaker)
end)

Remotes.Get("ShowCredits").OnClientEvent:Connect(function(payload)
	Credits.Show(payload)
end)

Remotes.Get("StageLoaded").OnClientEvent:Connect(function(stageId, name)
	HUD.Toast("Stage: " .. tostring(name))
end)

Remotes.Get("PlaySound").OnClientEvent:Connect(function(soundName: string)
	local world = workspace:FindFirstChild("GameWorld")
	local folder = world and world:FindFirstChild("StageSounds")
	local s = folder and folder:FindFirstChild(soundName)
	if s and s:IsA("Sound") then
		-- placeholder: play if SoundId set later; still useful hook
		if s.SoundId ~= "" then
			s:Play()
		end
	end
end)

Remotes.Get("DamageNumber").OnClientEvent:Connect(function(pos: Vector3, amount: number, _isPlayer: boolean?)
	local part = Instance.new("Part")
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 1, 1)
	part.Position = pos + Vector3.new(0, 3, 0)
	part.Parent = workspace
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(80, 40)
	bb.AlwaysOnTop = true
	bb.Parent = part
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 220, 80)
	t.TextStrokeTransparency = 0.3
	t.Text = tostring(amount)
	t.Parent = bb
	TweenService:Create(part, TweenInfo.new(0.7), { Position = part.Position + Vector3.new(0, 4, 0) }):Play()
	Debris:AddItem(part, 0.75)
end)

Remotes.Get("CombatEvent").OnClientEvent:Connect(function(ev)
	if typeof(ev) ~= "table" then
		return
	end
	local player = Players.LocalPlayer
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if ev.kind == "shake" then
		CameraController.Shake(ev.amount or 0.4, 0.18)
		return
	end
	if not hrp then
		return
	end
	if ev.kind == "attack" then
		local facing = ev.facing or MovementController.GetFacing()
		MovementController.LockFacing(facing, 0.25)
		local slash = Instance.new("Part")
		slash.Anchored = true
		slash.CanCollide = false
		slash.Material = Enum.Material.Neon
		slash.Color = Color3.fromRGB(255, 230, 120)
		slash.Size = Vector3.new(6 + (ev.combo or 1), 0.4, 4)
		slash.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 5, 1, 0))
		slash.Transparency = 0.2
		slash.Parent = workspace
		TweenService:Create(slash, TweenInfo.new(0.2), { Transparency = 1, Size = slash.Size + Vector3.new(2, 0, 1) }):Play()
		Debris:AddItem(slash, 0.25)
		CameraController.Shake(0.15 + (ev.combo or 1) * 0.05, 0.1)
	elseif ev.kind == "skill" then
		local burst = Instance.new("Part")
		burst.Shape = Enum.PartType.Ball
		burst.Anchored = true
		burst.CanCollide = false
		burst.Material = Enum.Material.ForceField
		burst.Color = Color3.fromRGB(120, 220, 255)
		burst.Size = Vector3.new(4, 4, 4)
		burst.CFrame = hrp.CFrame
		burst.Parent = workspace
		TweenService:Create(burst, TweenInfo.new(0.35), { Size = Vector3.new(20, 20, 20), Transparency = 1 }):Play()
		Debris:AddItem(burst, 0.4)
		HUD.Toast(tostring(ev.skill or "Skill") .. "!")
		CameraController.Shake(0.55, 0.22)
	elseif ev.kind == "dodge" then
		-- trail already from MovementController
	elseif ev.kind == "swap" then
		local ring = Instance.new("Part")
		ring.Shape = Enum.PartType.Cylinder
		ring.Anchored = true
		ring.CanCollide = false
		ring.Material = Enum.Material.Neon
		ring.Color = Color3.fromRGB(255, 160, 40)
		ring.Size = Vector3.new(0.5, 8, 8)
		ring.CFrame = hrp.CFrame * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace
		TweenService:Create(ring, TweenInfo.new(0.3), { Size = Vector3.new(0.5, 16, 16), Transparency = 1 }):Play()
		Debris:AddItem(ring, 0.35)
		CameraController.Shake(0.3, 0.15)
	elseif ev.kind == "hit" then
		HUD.Toast("Ouch! -" .. tostring(ev.damage))
		CameraController.Shake(0.65, 0.25)
	end
end)

Remotes.Get("Toast").OnClientEvent:Connect(function(text)
	if string.find(tostring(text), "Smash spare") then
		CaptainSteveUI.Open()
	end
end)

local player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic
player.DevEnableMouseLock = false

-- sync move speed from character attributes
RunService.Heartbeat:Connect(function()
	local char = player.Character
	if not char then
		return
	end
	local spd = char:GetAttribute("MoveSpeed")
	if typeof(spd) == "number" then
		MovementController.SetBaseSpeed(spd)
	end
	local hang = char:GetAttribute("Hangover")
	if typeof(hang) == "boolean" then
		MovementController.SetHangover(hang)
	end
end)

print("[Florida Man] Client ready — 2.5D mover online.")

task.spawn(function()
	while true do
		task.wait(4)
		local plr = Players.LocalPlayer
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local world = workspace:FindFirstChild("GameWorld")
		if hrp and world then
			local flame = world:FindFirstChild("Flame")
			local steve = world:FindFirstChild("CaptainSteve")
			if flame and (flame.Position - hrp.Position).Magnitude < 14 then
				HUD.Toast("Press E / LB near the bonfire to start your run")
			elseif steve and (steve.Position - hrp.Position).Magnitude < 14 then
				HUD.Toast("Press E / LB — Captain Steve (Sunburn upgrades)")
			end
		end
	end
end)
