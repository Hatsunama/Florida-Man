--!strict
--[[ Florida Man — client entry ]]

local Players = game:GetService("Players")
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
local HUD = require(UI:WaitForChild("HUD"))
local Newspaper = require(UI:WaitForChild("Newspaper"))
local ItemDraft = require(UI:WaitForChild("ItemDraft"))
local Credits = require(UI:WaitForChild("Credits"))
local Tagline = require(UI:WaitForChild("Tagline"))
local CaptainSteveUI = require(UI:WaitForChild("CaptainSteveUI"))

HUD.Init()
InputController.Start()
CameraController.Start()
Newspaper.BindInput(InputController)
ItemDraft.BindInput(InputController)

Remotes.Get("StateUpdate").OnClientEvent:Connect(function(state)
	HUD.Update(state)
	CaptainSteveUI.SetState(state)
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
	if not hrp then
		return
	end
	if ev.kind == "attack" then
		local slash = Instance.new("Part")
		slash.Anchored = true
		slash.CanCollide = false
		slash.Material = Enum.Material.Neon
		slash.Color = Color3.fromRGB(255, 230, 120)
		slash.Size = Vector3.new(6 + (ev.combo or 1), 0.4, 4)
		local facing = ev.facing or 1
		slash.CFrame = CFrame.new(hrp.Position + Vector3.new(facing * 5, 1, 0))
		slash.Transparency = 0.2
		slash.Parent = workspace
		TweenService:Create(slash, TweenInfo.new(0.2), { Transparency = 1, Size = slash.Size + Vector3.new(2, 0, 1) }):Play()
		Debris:AddItem(slash, 0.25)
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
	elseif ev.kind == "dodge" then
		local ghost = hrp:Clone()
		ghost.Anchored = true
		ghost.CanCollide = false
		ghost.Transparency = 0.5
		ghost.Color = Color3.fromRGB(180, 220, 255)
		ghost.Parent = workspace
		Debris:AddItem(ghost, 0.3)
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
	elseif ev.kind == "hit" then
		-- enemy hit player — brief red vignette via toast
		HUD.Toast("Ouch! -" .. tostring(ev.damage))
	end
end)

-- Open Steve UI when toast/tagline from talk — also listen proximity key already fires TalkCaptainSteve
-- Hook: when server fires tagline from TalkCaptainSteve, also open panel
local steveOpenQueued = false
Remotes.Get("ShowTagline").OnClientEvent:Connect(function(_text, speaker)
	if speaker == "Captain Steve" and not steveOpenQueued then
		-- don't always open; only from hub talk via Toast containing "Smash"
	end
end)

Remotes.Get("Toast").OnClientEvent:Connect(function(text)
	if string.find(tostring(text), "Smash spare") then
		CaptainSteveUI.Open()
	end
end)

-- Disable default shift lock weirdness; keep jump on Space (Roblox default)
local player = Players.LocalPlayer
player.CameraMode = Enum.CameraMode.Classic

print("[Florida Man] Client ready — welcome to the swamp.")


-- Hub hint loop
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
