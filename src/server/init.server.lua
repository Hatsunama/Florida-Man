--!strict
--[[ Florida Man — server entry ]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared", 30)
assert(Shared, "Shared modules missing — is Rojo connected?")

-- Safety platform so players never void before hub builds
local function ensureSafetyPad()
	local existing = Workspace:FindFirstChild("FM_SafetyPad")
	if existing then
		return
	end
	local pad = Instance.new("Part")
	pad.Name = "FM_SafetyPad"
	pad.Anchored = true
	pad.Size = Vector3.new(80, 2, 40)
	pad.Position = Vector3.new(20, -1, 0)
	pad.Color = Color3.fromRGB(210, 180, 110)
	pad.Material = Enum.Material.Sand
	pad.Parent = Workspace
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "FM_Spawn"
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(18, 0.5, 0) -- Constants.SPAWN_X
	-- Respawn marker only. Stage geometry supplies the visible, collidable floor.
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Neutral = true
	spawn.Parent = Workspace
end
ensureSafetyPad()

local Remotes = require(Shared:WaitForChild("Remotes"))
Remotes.InitServer()

local GameService = require(script:WaitForChild("GameService"))
GameService.SetupRemotes()

local function onPlayer(player: Player)
	GameService.InitPlayer(player)
end

for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end
Players.PlayerAdded:Connect(onPlayer)

local buildIdentity=ReplicatedStorage:FindFirstChild('BuildIdentity')
print('[Florida Man] Server initialized; build '..(if buildIdentity and buildIdentity:IsA('StringValue') then buildIdentity.Value else 'unpackaged-checkout')..'. Character readiness is checked separately.')
