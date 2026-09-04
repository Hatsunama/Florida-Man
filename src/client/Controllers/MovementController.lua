--!strict
--[[ Premium 2.5D lane mover — Skul/Dead Cells feel.
	Drives X via AssemblyLinearVelocity only (never stomps full CFrame).
	Soft Z lock via AlignPosition (Z-axis force). Facing via AlignOrientation.
	Keeps coyote, jump buffer, variable jump, dash i-frames + trail.
	No stacked custom gravity — Roblox workspace.Gravity owns Y.
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local AnimController = require(script.Parent:WaitForChild("AnimController"))

local MovementController = {}

local player = Players.LocalPlayer
local moveX = 0
local facing = 1
local velX = 0
local coyote = 0
local jumpBuffer = 0
local jumpHeld = false
local jumping = false
local attackLockUntil = 0
local dodgeUntil = 0
local hitstopUntil = 0 -- set via Hitstop()
local hangoverMult = 1
local baseSpeed = 18
local enabled = true

local ACCEL = 100
local DECEL = 110
local AIR_ACCEL = 52
local MAX_SPEED = 23
local JUMP_VELOCITY = 56
local JUMP_CUT = 0.45
local COYOTE_TIME = 0.12
local JUMP_BUFFER = 0.12
local DODGE_SPEED = 62
local DODGE_DUR = 0.18

-- Per-character constraint refs (rebuilt on spawn)
local rootAttachment: Attachment? = nil
local alignPos: AlignPosition? = nil
local alignOri: AlignOrientation? = nil

--[[ Facing for +Z side-scroller: D/+X travel must face +X (LookVector.X > 0).
	Old Angles(0,+90,0) yielded LookVector (-1,0,0) which caused moonwalk.
	lookAlong with faceDir = sign(moveX) aligns LookVector with travel. ]]
local function faceCFrame(faceDir: number): CFrame
	local dir = if faceDir >= 0 then 1 else -1
	return CFrame.lookAlong(Vector3.zero, Vector3.new(dir, 0, 0))
end

local function getChar(): (Model?, BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	return char, hrp, hum
end

local function destroyMovers()
	if alignPos then
		alignPos:Destroy()
		alignPos = nil
	end
	if alignOri then
		alignOri:Destroy()
		alignOri = nil
	end
	if rootAttachment then
		rootAttachment:Destroy()
		rootAttachment = nil
	end
end

local function setupMovers(hrp: BasePart)
	destroyMovers()

	local att = Instance.new("Attachment")
	att.Name = "FM_MoveAttach"
	att.Parent = hrp
	rootAttachment = att

	-- Soft lane lock: force only on Z toward LANE_Z (does not fight X/Y physics)
	local ap = Instance.new("AlignPosition")
	ap.Name = "FM_LaneLock"
	ap.Mode = Enum.PositionAlignmentMode.OneAttachment
	ap.Attachment0 = att
	ap.ApplyAtCenterOfMass = true
	ap.RigidityEnabled = false
	ap.Responsiveness = 55
	ap.MaxForce = 1e6
	ap.ForceLimitMode = Enum.ForceLimitMode.PerAxis
	ap.MaxAxesForce = Vector3.new(0, 0, 250000)
	ap.Position = Vector3.new(hrp.Position.X, hrp.Position.Y, Constants.LANE_Z)
	ap.Parent = hrp
	alignPos = ap

	-- Snap facing so LookVector matches travel (+X when facing=+1)
	local ao = Instance.new("AlignOrientation")
	ao.Name = "FM_Face"
	ao.Mode = Enum.OrientationAlignmentMode.OneAttachment
	ao.Attachment0 = att
	ao.RigidityEnabled = true
	ao.Responsiveness = 200
	ao.MaxTorque = 1e7
	ao.CFrame = faceCFrame(facing)
	ao.Parent = hrp
	alignOri = ao
end

local function configureHumanoid(hum: Humanoid, hrp: BasePart)
	hum.AutoRotate = false
	hum.WalkSpeed = 0
	hum.JumpPower = 0
	hum.JumpHeight = 0
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	setupMovers(hrp)
end

local function isGrounded(hrp: BasePart, hum: Humanoid): boolean
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character :: Instance }
		local hit = workspace:Raycast(hrp.Position, Vector3.new(0, -3.2, 0), params)
		return hit ~= nil
	end
	return state == Enum.HumanoidStateType.Running
		or state == Enum.HumanoidStateType.Landed
		or state == Enum.HumanoidStateType.RunningNoPhysics
end

local function spawnDodgeTrail(hrp: BasePart)
	for i = 1, 6 do
		task.delay((i - 1) * 0.028, function()
			if not hrp.Parent then
				return
			end
			local ghost = Instance.new("Part")
			ghost.Size = Vector3.new(2, 4, 1)
			ghost.CFrame = hrp.CFrame
			ghost.Anchored = true
			ghost.CanCollide = false
			ghost.Material = Enum.Material.ForceField
			ghost.Color = Color3.fromRGB(160, 220, 255)
			ghost.Transparency = 0.35
			ghost.Parent = workspace
			TweenService:Create(ghost, TweenInfo.new(0.35), { Transparency = 1 }):Play()
			Debris:AddItem(ghost, 0.4)
		end)
	end
	local att = Instance.new("Attachment")
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new(Color3.fromRGB(180, 230, 255))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	pe.Lifetime = NumberRange.new(0.2, 0.35)
	pe.Speed = NumberRange.new(2, 6)
	pe.Rate = 0
	pe.LightEmission = 0.5
	pe.Parent = att
	pe:Emit(16)
	Debris:AddItem(att, 0.5)
end

local function doJump(hrp: BasePart, hum: Humanoid)
	local v = hrp.AssemblyLinearVelocity
	-- Preserve X; set jump Y; zero Z (lane)
	hrp.AssemblyLinearVelocity = Vector3.new(v.X, JUMP_VELOCITY, 0)
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	jumping = true
	AnimController.PlayJump()
	coyote = 0
	jumpBuffer = 0
end

function MovementController.SetHangover(active: boolean)
	hangoverMult = if active then Constants.HANGOVER_SLOW else 1
end

function MovementController.SetBaseSpeed(speed: number)
	baseSpeed = speed
end

function MovementController.SetEnabled(on: boolean)
	enabled = on
end

function MovementController.Hitstop(duration: number?)
	local d = duration or Constants.HITSTOP
	hitstopUntil = math.max(hitstopUntil, os.clock() + d)
end

function MovementController.GetFacing(): number
	return facing
end

function MovementController.LockFacing(dir: number, duration: number)
	facing = if dir >= 0 then 1 else -1
	attackLockUntil = os.clock() + duration
	if alignOri then
		alignOri.CFrame = faceCFrame(facing)
	end
end

function MovementController.RequestDodge()
	if not enabled then
		return
	end
	if os.clock() < dodgeUntil then
		return
	end
	local char, hrp = getChar()
	if not char or not hrp then
		return
	end
	local dir = moveX
	if math.abs(dir) < 0.1 then
		dir = facing
	else
		facing = if dir >= 0 then 1 else -1
	end
	dodgeUntil = os.clock() + Constants.DODGE_COOLDOWN
	AnimController.PlayDodge()
	char:SetAttribute("IFrameVFX", true)
	spawnDodgeTrail(hrp)
	if alignOri then
		alignOri.CFrame = faceCFrame(facing)
	end
	local v = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(dir * DODGE_SPEED, math.max(v.Y, 4), 0)
	velX = dir * DODGE_SPEED * 0.55
	task.delay(Constants.DODGE_IFRAME, function()
		if char then
			char:SetAttribute("IFrameVFX", nil)
		end
	end)
	Remotes.Get("RequestDodge"):FireServer(facing)
	pcall(function()
		local TutorialController = require(script.Parent:WaitForChild("TutorialController"))
		TutorialController.OnDodgeInput()
	end)
end

function MovementController.Start()
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp or not enabled then
			return
		end
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
			jumpHeld = true
			jumpBuffer = JUMP_BUFFER
		elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonR1 then
			MovementController.RequestDodge()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.ButtonA then
			jumpHeld = false
			local _, hrp = getChar()
			if hrp and jumping and hrp.AssemblyLinearVelocity.Y > 0 then
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, v.Y * JUMP_CUT, 0)
			end
		end
	end)

	player.CharacterAdded:Connect(function(char)
		destroyMovers()
		task.wait(0.15)
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if hrp and hum then
			configureHumanoid(hum, hrp)
			player.DevEnableMouseLock = false
		end
	end)
	player.CharacterRemoving:Connect(function()
		destroyMovers()
	end)
	if player.Character then
		local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = player.Character:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			configureHumanoid(hum, hrp)
		end
	end

	RunService.RenderStepped:Connect(function(dt)
		if not enabled then
			return
		end
		local char, hrp, hum = getChar()
		if not char or not hrp or not hum then
			return
		end
		if hum.Health <= 0 then
			return
		end

		-- Hitstop: brief freeze on connect (Skul juice) — keep facing/lane movers alive
		if os.clock() < hitstopUntil then
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(0, v.Y * 0.35, 0)
			velX = 0
			if alignPos then
				alignPos.Position = Vector3.new(hrp.Position.X, hrp.Position.Y, Constants.LANE_Z)
			end
			if alignOri then
				alignOri.CFrame = faceCFrame(facing)
			end
			return
		end

		-- Karen slow aura from attribute
		local slowUntil = char:GetAttribute("SlowUntil")
		local slowMult = 1
		if typeof(slowUntil) == "number" and os.clock() < slowUntil then
			slowMult = 0.55
		end

		-- Ensure movers exist (respawn / edge cases)
		if not alignPos or not alignOri or not rootAttachment or rootAttachment.Parent ~= hrp then
			setupMovers(hrp)
		end

		local left = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
		local right = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)
		local stick = UserInputService:GetGamepadState(Enum.UserInputType.Gamepad1)
		local stickX = 0
		for _, obj in stick do
			if obj.KeyCode == Enum.KeyCode.Thumbstick1 then
				stickX = obj.Position.X
			end
		end
		moveX = 0
		if left then
			moveX -= 1
		end
		if right then
			moveX += 1
		end
		if math.abs(stickX) > 0.2 then
			moveX = if stickX > 0 then 1 else -1
		end

		local grounded = isGrounded(hrp, hum)
		if grounded then
			coyote = COYOTE_TIME
			if jumping and hrp.AssemblyLinearVelocity.Y <= 0.5 then
				jumping = false
				char:SetAttribute("LandSquash", os.clock())
			end
		else
			coyote = math.max(0, coyote - dt)
		end
		jumpBuffer = math.max(0, jumpBuffer - dt)

		if jumpBuffer > 0 and coyote > 0 then
			doJump(hrp, hum)
		end

		local maxSpd = math.min(MAX_SPEED, baseSpeed) * hangoverMult * slowMult
		local accel = if grounded then ACCEL else AIR_ACCEL
		local inDodge = os.clock() < dodgeUntil - Constants.DODGE_COOLDOWN + DODGE_DUR

		if not inDodge then
			if math.abs(moveX) > 0.1 then
				velX = velX + moveX * accel * dt
				velX = math.clamp(velX, -maxSpd, maxSpd)
				if os.clock() > attackLockUntil then
					facing = if moveX >= 0 then 1 else -1
				end
			else
				local dec = if grounded then DECEL else DECEL * 0.4
				if velX > 0 then
					velX = math.max(0, velX - dec * dt)
				elseif velX < 0 then
					velX = math.min(0, velX + dec * dt)
				end
			end
		end

		-- Drive X only; preserve physics Y; kill Z velocity (AlignPosition holds Z pos)
		local v = hrp.AssemblyLinearVelocity
		hrp.AssemblyLinearVelocity = Vector3.new(velX, v.Y, 0)

		-- Soft Z target tracks current X/Y so we never yank those axes
		if alignPos then
			alignPos.Position = Vector3.new(hrp.Position.X, hrp.Position.Y, Constants.LANE_Z)
		end
		if alignOri then
			alignOri.CFrame = faceCFrame(facing)
		end

		-- Keep default Animate forward: MoveDirection shares sign with LookVector/travel
		if math.abs(moveX) > 0.1 then
			hum:Move(Vector3.new(moveX, 0, 0), false)
		else
			hum:Move(Vector3.zero, false)
		end

		char:SetAttribute("Facing", facing)
		char:SetAttribute("VelX", velX)
	end)
end

return MovementController
