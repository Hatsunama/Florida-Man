--!strict
--[[ Client-authoritative 2.5D controller — Skul/Dead Cells lane feel.
	Locks Z to lane, smooth accel/decel, coyote jump, variable jump, air control,
	dodge dash with local VFX. Disables default camera fight / AutoRotate issues.
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
local hangoverMult = 1
local baseSpeed = 18
local enabled = true
local groundY: number? = nil

local ACCEL = 85
local DECEL = 95
local AIR_ACCEL = 45
local MAX_SPEED = 22
local JUMP_VELOCITY = 56
local JUMP_CUT = 0.45
local COYOTE_TIME = 0.12
local JUMP_BUFFER = 0.12
local GRAVITY = 140
local DODGE_SPEED = 62
local DODGE_DUR = 0.18

local function getChar(): (Model?, BasePart?, Humanoid?)
	local char = player.Character
	if not char then
		return nil, nil, nil
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	return char, hrp, hum
end

local function configureHumanoid(hum: Humanoid, hrp: BasePart)
	hum.AutoRotate = false
	hum.WalkSpeed = 0 -- we drive X ourselves
	hum.JumpPower = 0
	hum.JumpHeight = 0
	hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
	hum:SetStateEnabled(Enum.HumanoidStateType.Swimming, false)
	-- Keep falling/running for ground detection
	-- network ownership is server-side
end

local function isGrounded(hrp: BasePart, hum: Humanoid): boolean
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		-- raycast confirm
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
	for i = 1, 4 do
		task.delay((i - 1) * 0.03, function()
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
			TweenService:Create(ghost, TweenInfo.new(0.25), { Transparency = 1 }):Play()
			Debris:AddItem(ghost, 0.3)
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
	hrp.AssemblyLinearVelocity = Vector3.new(v.X, JUMP_VELOCITY, 0)
	hum:ChangeState(Enum.HumanoidStateType.Jumping)
	jumping = true
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

function MovementController.GetFacing(): number
	return facing
end

function MovementController.LockFacing(dir: number, duration: number)
	facing = if dir >= 0 then 1 else -1
	attackLockUntil = os.clock() + duration
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
	char:SetAttribute("IFrame", true)
	spawnDodgeTrail(hrp)
	-- impulse
	local v = hrp.AssemblyLinearVelocity
	hrp.AssemblyLinearVelocity = Vector3.new(dir * DODGE_SPEED, math.max(v.Y, 4), 0)
	velX = dir * DODGE_SPEED * 0.55
	task.delay(Constants.DODGE_IFRAME, function()
		if char then
			char:SetAttribute("IFrame", nil)
		end
	end)
	Remotes.Get("RequestDodge"):FireServer(facing)
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
			-- variable jump cut
			local _, hrp = getChar()
			if hrp and jumping and hrp.AssemblyLinearVelocity.Y > 0 then
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, v.Y * JUMP_CUT, v.Z)
			end
		end
	end)

	player.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if hrp and hum then
			configureHumanoid(hum, hrp)
			-- disable shift lock weirdness
			player.DevEnableMouseLock = false
		end
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

		-- input
		local left = UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left)
		local right = UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right)
		-- gamepad
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
				-- landing squash feel via brief scale attribute for camera
				char:SetAttribute("LandSquash", os.clock())
			end
		else
			coyote = math.max(0, coyote - dt)
		end
		jumpBuffer = math.max(0, jumpBuffer - dt)

		if jumpBuffer > 0 and coyote > 0 then
			doJump(hrp, hum)
		end

		local maxSpd = math.min(MAX_SPEED, baseSpeed) * hangoverMult
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
				-- decel
				local dec = if grounded then DECEL else DECEL * 0.4
				if velX > 0 then
					velX = math.max(0, velX - dec * dt)
				elseif velX < 0 then
					velX = math.min(0, velX + dec * dt)
				end
			end
		end

		-- apply velocity; lock Z; keep Y from physics
		local v = hrp.AssemblyLinearVelocity
		local newY = v.Y
		-- custom gravity boost for snappier fall
		if not grounded and newY < 0 then
			newY -= GRAVITY * 0.35 * dt
		end
		hrp.AssemblyLinearVelocity = Vector3.new(velX, newY, 0)

		-- hard lane lock (no fence jitter)
		local pos = hrp.Position
		if math.abs(pos.Z - Constants.LANE_Z) > 0.01 or math.abs(hrp.AssemblyLinearVelocity.Z) > 0.01 then
			hrp.CFrame = CFrame.new(pos.X, pos.Y, Constants.LANE_Z) * CFrame.Angles(0, if facing > 0 then math.rad(90) else math.rad(-90), 0)
			local vv = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(vv.X, vv.Y, 0)
		else
			-- face along +X / -X (side scroll)
			local targetCF = CFrame.new(pos) * CFrame.Angles(0, if facing > 0 then math.rad(90) else math.rad(-90), 0)
			hrp.CFrame = targetCF
		end

		char:SetAttribute("Facing", facing)
		char:SetAttribute("VelX", velX)
	end)
end

return MovementController
