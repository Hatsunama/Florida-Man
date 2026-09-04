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
local VFX = require(Controllers:WaitForChild("VFX"))
local HUD = require(UI:WaitForChild("HUD"))
local Newspaper = require(UI:WaitForChild("Newspaper"))
local ItemDraft = require(UI:WaitForChild("ItemDraft"))
local Credits = require(UI:WaitForChild("Credits"))
local Tagline = require(UI:WaitForChild("Tagline"))
local CaptainSteveUI = require(UI:WaitForChild("CaptainSteveUI"))
local MobileControls = require(UI:WaitForChild("MobileControls"))
local TutorialController = require(Controllers:WaitForChild("TutorialController"))

HUD.Init()
MovementController.Start()
CameraController.Start()
InputController.BindMovement(MovementController)
InputController.Start()
MobileControls.Init(InputController)
TutorialController.Start()
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
	TutorialController.ResetForStage(tostring(stageId))
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
	if ev.kind == "focus" then
		if typeof(ev.pos) == "Vector3" then
			CameraController.Focus(ev.pos, ev.duration or 0.36)
		end
		CameraController.Shake(ev.amount or 0.3, 0.14)
		return
	end
	if ev.kind == "hitConnect" then
		-- Every connect: hitstop + spark + shake (never on empty swings)
		MovementController.Hitstop(ev.hitstop)
		if typeof(ev.pos) == "Vector3" then
			VFX.HitSpark(ev.pos, ev.heavy == true)
		end
		CameraController.Shake(ev.amount or 0.4, if ev.heavy then 0.22 else 0.14)
		return
	end
	if not hrp then
		return
	end
	if ev.kind == "attack" then
		-- Slash VFX is immediate on client input; server echo only locks facing
		local facing = ev.facing or MovementController.GetFacing()
		MovementController.LockFacing(facing, 0.25)
		-- No shake on empty swing — juice only on hitConnect
	elseif ev.kind == "skill" then
		local facing = ev.facing or MovementController.GetFacing()
		VFX.SkillPattern(hrp, tostring(ev.skillKind or "aoe"), facing)
		HUD.Toast(tostring(ev.skill or "Skill") .. "!")
		CameraController.Shake(0.55, 0.22)
		MovementController.Hitstop(0.05)
	elseif ev.kind == "dodge" then
		-- trail already from MovementController
	elseif ev.kind == "swap" then
		local col = Color3.fromRGB(255, 160, 40)
		if typeof(ev.color) == "table" and ev.color[1] then
			col = Color3.new(ev.color[1], ev.color[2], ev.color[3])
		end
		VFX.SwapBurst(hrp, col)
		CameraController.Shake(0.35, 0.16)
		MovementController.Hitstop(0.04)
	elseif ev.kind == "hit" then
		HUD.Toast("Ouch! -" .. tostring(ev.damage))
		CameraController.Shake(0.65, 0.25)
	end
end)

-- Open Steve upgrade panel only on intentional interact (prompt / E), not stage taglines
local ProximityPromptService = game:GetService("ProximityPromptService")
ProximityPromptService.PromptTriggered:Connect(function(prompt, plr)
	if plr ~= Players.LocalPlayer then
		return
	end
	if prompt:GetAttribute("FM_Action") == "TalkCaptainSteve" then
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

-- Phase 1: forever hub toast spam removed — TutorialController + TutorialService are once-through.
