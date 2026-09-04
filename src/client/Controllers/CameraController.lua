--!strict
--[[ Side-scroll camera with deadzone + spring dampening + screen shake. ]]

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CameraController = {}

local camPos = Vector3.zero
local camVel = Vector3.zero
local lookPos = Vector3.zero
local lookVel = Vector3.zero
local shakeAmp = 0
local shakeUntil = 0
local deadzoneX = 3.5
local followBiasX = 6
local height = 9
local depth = 32
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
	shakeAmp = math.max(shakeAmp, amount)
	shakeUntil = os.clock() + (duration or 0.2)
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
		-- deadzone on X relative to look
		local dx = focusX - (lookPos.X - 8)
		if math.abs(dx) > deadzoneX then
			focusX = lookPos.X - 8 + math.sign(dx) * (math.abs(dx) - deadzoneX) * 0.15 + focusX * 0.85
		end

		local land = char and char:GetAttribute("LandSquash")
		local landBump = 0
		if typeof(land) == "number" and os.clock() - land < 0.15 then
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
