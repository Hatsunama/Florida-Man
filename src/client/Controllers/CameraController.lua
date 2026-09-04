--!strict
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local CameraController = {}

function CameraController.Start()
	local cam = workspace.CurrentCamera
	local player = Players.LocalPlayer
	RunService.RenderStepped:Connect(function()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp or not cam then
			return
		end
		cam.CameraType = Enum.CameraType.Scriptable
		local target = Vector3.new(hrp.Position.X + 6, hrp.Position.Y + 10, Constants.LANE_Z + 38)
		local look = Vector3.new(hrp.Position.X + 8, hrp.Position.Y + 2, Constants.LANE_Z)
		cam.CFrame = cam.CFrame:Lerp(CFrame.new(target, look), 0.12)
	end)
end

return CameraController
