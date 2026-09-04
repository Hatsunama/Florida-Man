--!strict
--[[ Side-scroll camera with deadzone + spring dampening + screen shake. ]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Settings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Settings"))

local CameraController = {}

local camPos = Vector3.zero
local camVel = Vector3.zero
local lookPos = Vector3.zero
local lookVel = Vector3.zero
local shakeAmp = 0
local shakeUntil = 0
local focusUntil = 0
local focusTarget: Vector3? = nil
local focusBiasX = 6
local deadzoneX = 3.5
local followBiasX = 6
local height = 9
local depth = Constants.CAMERA_DEPTH or 32
local STIFFNESS = 48
local DAMPING = 15

local function spring(current: Vector3, target: Vector3, vel: Vector3, dt: number): (Vector3, Vector3)
	local force = (target - current) * STIFFNESS
	local damp = vel * DAMPING
	local acc = force - damp
	vel = vel + acc * dt
	current = current + vel * dt
	return current, vel
end

function CameraController.Shake(amount: number, duration: number?)
	local player = Players.LocalPlayer
	if Settings.IsReduceMotion(player) then
		return
	end
	local enabled = player:GetAttribute("ShakeEnabled")
	if enabled == false then
		return
	end
	shakeAmp = math.max(shakeAmp, amount)
	shakeUntil = os.clock() + (duration or 0.2)
end

local arenaLockPos: Vector3? = nil
local arenaLocked = false

--- Brief framing nudge toward a world point (MidGate / miniboss). ≤0.4s Scriptable cut feel.
function CameraController.Focus(worldPos: Vector3, duration: number?)
	focusTarget = worldPos
	focusUntil = os.clock() + math.clamp(duration or 0.35, 0.15, 0.45)
	CameraController.Shake(0.25, 0.12)
end

--- MidGate room: pin camera bias to arena while wave is active
function CameraController.LockArena(worldPos: Vector3)
	arenaLockPos = worldPos
	arenaLocked = true
	CameraController.Focus(worldPos, 0.42)
	CameraController.Shake(0.35, 0.16)
end

function CameraController.UnlockArena(worldPos: Vector3?)
	arenaLocked = false
	arenaLockPos = nil
	if worldPos then
		CameraController.Focus(worldPos, 0.42)
	end
	CameraController.Shake(0.3, 0.14)
end

function CameraController.Start()
	local player = Players.LocalPlayer
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	player.CameraMode = Enum.CameraMode.Classic
	player.DevEnableMouseLock = false

	-- init from character if present
	task.defer(function()
		local char = player.Character or player.CharacterAdded:Wait()
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if hrp then
			camPos = Vector3.new(hrp.Position.X + followBiasX, hrp.Position.Y + height, Constants.LANE_Z + depth)
			lookPos = Vector3.new(hrp.Position.X + 8, hrp.Position.Y + 2, Constants.LANE_Z)
		end
	end)

	RunService.RenderStepped:Connect(function(dt)
		cam = workspace.CurrentCamera
		if not cam then
			return
		end
		cam.CameraType = Enum.CameraType.Scriptable
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			return
		end

		local focusX = hrp.Position.X
		local focusY = hrp.Position.Y
		if arenaLocked and arenaLockPos then
			-- Soft lock: blend player with arena center so room reads as an arena
			focusX = focusX * 0.35 + arenaLockPos.X * 0.65
			focusY = focusY * 0.5 + (arenaLockPos.Y + 2) * 0.5
		end
		if focusTarget and os.clock() < focusUntil then
			local alpha = math.clamp((focusUntil - os.clock()) / 0.35, 0, 1)
			-- ease toward event then back (alpha high at start of window remaining? use elapsed blend)
			local elapsed = 1 - alpha
			local blend = if elapsed < 0.45 then elapsed / 0.45 else alpha / 0.55
			blend = math.clamp(blend, 0, 0.85)
			focusX = focusX * (1 - blend) + focusTarget.X * blend
			focusY = focusY * (1 - blend) + (focusTarget.Y + 2) * blend
		else
			focusTarget = nil
		end
		-- deadzone on X relative to look
		local dx = focusX - (lookPos.X - 8)
		if math.abs(dx) > deadzoneX then
			focusX = lookPos.X - 8 + math.sign(dx) * (math.abs(dx) - deadzoneX) * 0.15 + focusX * 0.85
		end

		local land = char and char:GetAttribute("LandSquash")
		local landBump = 0
		if not Settings.IsReduceMotion(Players.LocalPlayer)
			and typeof(land) == "number"
			and os.clock() - land < 0.15
		then
			landBump = -0.8
		end

		local targetCam = Vector3.new(focusX + followBiasX, focusY + height + landBump, Constants.LANE_Z + depth)
		local targetLook = Vector3.new(focusX + 8, focusY + 2, Constants.LANE_Z)

		camPos, camVel = spring(camPos, targetCam, camVel, dt)
		lookPos, lookVel = spring(lookPos, targetLook, lookVel, dt)

		local shake = Vector3.zero
		if os.clock() < shakeUntil and shakeAmp > 0 then
			shake = Vector3.new(
				(math.noise(os.clock() * 40, 1) - 0.5) * 2 * shakeAmp,
				(math.noise(os.clock() * 40, 2) - 0.5) * 2 * shakeAmp,
				0
			)
			shakeAmp = shakeAmp * (1 - dt * 8)
		else
			shakeAmp = 0
		end

		cam.CFrame = CFrame.new(camPos + shake, lookPos + shake * 0.3)
		cam.FieldOfView = 65
	end)
end

return CameraController
