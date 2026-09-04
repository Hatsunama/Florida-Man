--!strict
--[[ AnimController — play uploaded AnimationIds when present; else procedural
	Motor6D attack/idle poses (BeachBurnout slap, CrabKing pinch lean).
	NEVER invent rbxassetid Animation IDs — registry lives in ArtAssets (empty until upload).
	Does NOT resize HumanoidRootPart (physics-safe).
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtAssets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ArtAssets"))
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Settings"))

local AnimController = {}

-- Back-compat alias: prefer ArtAssets.AnimationIds (single source of truth).
AnimController.AnimationIds = ArtAssets.AnimationIds

local player = Players.LocalPlayer
local tracks: { [string]: AnimationTrack } = {}
local animator: Animator? = nil
local hum: Humanoid? = nil
local hrp: BasePart? = nil
local poseUntil = 0
local poseKind = "idle"
local personaId = "BeachBurnout"
local conn: RBXScriptConnection? = nil
local charConn: RBXScriptConnection? = nil
local savedC0: { [Motor6D]: CFrame } = {}

local function clearTracks()
	for _, t in tracks do
		pcall(function()
			t:Stop(0)
			t:Destroy()
		end)
	end
	table.clear(tracks)
end

local function rememberMotor(m: Motor6D?)
	if m and not savedC0[m] then
		savedC0[m] = m.C0
	end
end

local function restoreMotors()
	for m, c0 in savedC0 do
		if m.Parent then
			m.C0 = c0
		end
	end
end

local function motor(char: Model, name: string): Motor6D?
	local m = char:FindFirstChild(name, true)
	if m and m:IsA("Motor6D") then
		return m
	end
	return nil
end

local function tryLoad(clip: string): AnimationTrack?
	local id = ArtAssets.GetAnimationId(personaId, clip)
	if not id then
		return nil
	end
	if not animator then
		return nil
	end
	local existing = tracks[clip]
	if existing then
		return existing
	end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return (animator :: Animator):LoadAnimation(anim)
	end)
	anim:Destroy()
	if ok and track then
		track.Priority = Enum.AnimationPriority.Action
		tracks[clip] = track
		return track
	end
	return nil
end

local function playClip(clip: string, fade: number?): boolean
	local t = tryLoad(clip)
	if t then
		if not t.IsPlaying then
			t:Play(fade or 0.12)
		end
		return true
	end
	return false
end

local function stopClip(clip: string)
	local t = tracks[clip]
	if t and t.IsPlaying then
		t:Stop(0.1)
	end
end

local function motionScale(): number
	if Settings.IsReduceMotion(player) then
		return 0.35
	end
	return 1
end

local function applyProcedural(_dt: number, moving: boolean, airborne: boolean)
	local char = player.Character
	if not char then
		return
	end
	local waist = motor(char, "Waist")
	local rs = motor(char, "RightShoulder")
	local ls = motor(char, "LeftShoulder")
	local root = motor(char, "Root")
	rememberMotor(waist)
	rememberMotor(rs)
	rememberMotor(ls)
	rememberMotor(root)

	local scale = motionScale()
	local now = os.clock()
	if now < poseUntil then
		local u = math.clamp(1 - (poseUntil - now) / 0.3, 0, 1)
		local swing = math.sin(u * math.pi) * scale
		if poseKind == "attack_BeachBurnout" then
			if waist and savedC0[waist] then
				waist.C0 = savedC0[waist] * CFrame.Angles(0, math.rad(22 * swing), 0)
			end
			if rs and savedC0[rs] then
				rs.C0 = savedC0[rs] * CFrame.Angles(math.rad(-70 * swing), 0, math.rad(35 * swing))
			end
			if ls and savedC0[ls] then
				ls.C0 = savedC0[ls] * CFrame.Angles(math.rad(-20 * swing), 0, math.rad(-15 * swing))
			end
		elseif poseKind == "attack_CrabKing" then
			if waist and savedC0[waist] then
				waist.C0 = savedC0[waist] * CFrame.Angles(math.rad(8 * swing), math.rad(-28 * swing), math.rad(12 * swing))
			end
			if rs and savedC0[rs] then
				rs.C0 = savedC0[rs] * CFrame.Angles(math.rad(-40 * swing), math.rad(50 * swing), math.rad(60 * swing))
			end
			if ls and savedC0[ls] then
				ls.C0 = savedC0[ls] * CFrame.Angles(math.rad(-40 * swing), math.rad(-50 * swing), math.rad(-60 * swing))
			end
		elseif poseKind == "dodge" then
			if root and savedC0[root] then
				root.C0 = savedC0[root] * CFrame.Angles(math.rad(-18 * swing), 0, 0)
			end
			if waist and savedC0[waist] then
				waist.C0 = savedC0[waist] * CFrame.new(0, -0.15 * swing, 0)
			end
		elseif poseKind == "jump" then
			if rs and savedC0[rs] then
				rs.C0 = savedC0[rs] * CFrame.Angles(math.rad(-40 * scale), 0, math.rad(20 * scale))
			end
			if ls and savedC0[ls] then
				ls.C0 = savedC0[ls] * CFrame.Angles(math.rad(-40 * scale), 0, math.rad(-20 * scale))
			end
		elseif poseKind == "skill" then
			if waist and savedC0[waist] then
				waist.C0 = savedC0[waist] * CFrame.Angles(math.rad(-12 * swing), math.rad(18 * swing), 0)
			end
			if rs and savedC0[rs] then
				rs.C0 = savedC0[rs] * CFrame.Angles(math.rad(-90 * swing), 0, math.rad(40 * swing))
			end
			if ls and savedC0[ls] then
				ls.C0 = savedC0[ls] * CFrame.Angles(math.rad(-50 * swing), 0, math.rad(-30 * swing))
			end
		elseif poseKind == "swap" then
			if root and savedC0[root] then
				root.C0 = savedC0[root] * CFrame.Angles(0, math.rad(40 * swing), 0)
			end
		end
		return
	end

	restoreMotors()
	if waist and savedC0[waist] then
		local bobAmp = 0.02 * scale
		local bob = if airborne then 0 elseif moving then math.sin(now * 10) * bobAmp * 2 else math.sin(now * 2.5) * bobAmp
		local sway = if moving then math.rad(math.sin(now * 10) * 3 * scale) else 0
		waist.C0 = savedC0[waist] * CFrame.new(0, bob, 0) * CFrame.Angles(0, 0, sway)
	end
end

function AnimController.SetPersona(id: string)
	personaId = id
	clearTracks()
	restoreMotors()
	table.clear(savedC0)
end

function AnimController.PlayAttack(combo: number?)
	local c = combo or 1
	local clip = if c >= 3 then "Attack3" elseif c == 2 then "Attack2" else "Attack1"
	if playClip(clip, 0.05) then
		poseUntil = 0
		return
	end
	if personaId == "CrabKing" then
		poseKind = "attack_CrabKing"
		poseUntil = os.clock() + 0.32
	else
		poseKind = "attack_BeachBurnout"
		poseUntil = os.clock() + 0.28
	end
end

function AnimController.PlayDodge()
	if playClip("Dodge", 0.05) then
		return
	end
	poseKind = "dodge"
	poseUntil = os.clock() + 0.22
end

function AnimController.PlayJump()
	if playClip("Jump", 0.05) then
		return
	end
	poseKind = "jump"
	poseUntil = os.clock() + 0.2
end

function AnimController.PlaySkill()
	if playClip("Skill", 0.05) then
		poseUntil = 0
		return
	end
	poseKind = "skill"
	poseUntil = os.clock() + 0.35
end

function AnimController.PlaySwap()
	if playClip("Swap", 0.05) then
		poseUntil = 0
		return
	end
	poseKind = "swap"
	poseUntil = os.clock() + 0.25
end

local function bindCharacter(char: Model)
	clearTracks()
	table.clear(savedC0)
	hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
	hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not hum or not hrp then
		return
	end
	local a = hum:FindFirstChildOfClass("Animator")
	if not a then
		a = Instance.new("Animator")
		a.Parent = hum
	end
	animator = a
	local animate = char:FindFirstChild("Animate")
	if animate then
		animate:SetAttribute("FM_AnimController", true)
	end
end

function AnimController.Start()
	if charConn then
		return
	end
	charConn = player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		task.defer(bindCharacter, player.Character)
	end
	conn = RunService.RenderStepped:Connect(function(dt)
		if not hrp or not hrp.Parent then
			return
		end
		local vx = hrp.AssemblyLinearVelocity.X
		local vy = hrp.AssemblyLinearVelocity.Y
		local moving = math.abs(vx) > 2.5
		local airborne = math.abs(vy) > 2.5
		local parent = hrp.Parent
		local pid = parent and parent:GetAttribute("PersonaId")
		if typeof(pid) == "string" and pid ~= personaId then
			AnimController.SetPersona(pid)
		end
		if os.clock() >= poseUntil then
			if airborne then
				playClip("Jump", 0.15)
			elseif moving then
				stopClip("Idle")
				playClip("Run", 0.15)
			else
				stopClip("Run")
				playClip("Idle", 0.2)
			end
		end
		-- Procedural overlay when Attack clips are not uploaded (validated IDs only)
		if ArtAssets.GetAnimationId(personaId, "Attack1") == nil then
			applyProcedural(dt, moving, airborne)
		end
	end)
end

return AnimController
