--!strict
--[[ Phase 1 — once-through tutorial beat map (hub + Daytona ~60s).
	Prompts fire once in order; never spam every N seconds.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))
local CharacterGeometry = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('CharacterGeometry'))

local TutorialService = {}
local SessionService = require(script.Parent:WaitForChild('SessionService'))

export type TutorialFlags = {
	move: boolean,
	jump: boolean,
	attack: boolean,
	dodgeAccepted: boolean,
	coldOne: boolean,
	crabKing: boolean,
	hubBonfire: boolean,
	started: boolean,
}

type Observation = { character: Model, generation: number, flags: TutorialFlags, revision: number,
	teleport: number, impulse: number, originX: number, position: Vector3, grounded: boolean,
	takeoffY: number?, takeoffAt: number }
local observations: { [Player]: Observation? } = {}
local activeFlags: { [Player]: TutorialFlags? } = {}

function TutorialService.NewFlags(): TutorialFlags
	return {
		move = false,
		jump = false,
		attack = false,
		dodgeAccepted = false,
		coldOne = false,
		crabKing = false,
		hubBonfire = false,
		started = false,
	}
end

local function toast(player: Player, text: string)
	Remotes.Get("Toast"):FireClient(player, text)
end

--- Hub once: after LoadHub
function TutorialService.OnHubLoaded(player: Player, flags: TutorialFlags)
	activeFlags[player] = flags
	if flags.started then
		return
	end
	flags.started = true
	SessionService.Delay(player, 0.8, function()
		if activeFlags[player] == flags and not flags.move then
			toast(player, "Move along the beach using A/D, the left stick, or the touch arrows.")
		end
	end)
end

--- Called when server detects meaningful X movement from spawn
function TutorialService.OnMoved(player: Player, flags: TutorialFlags)
	if flags.move then
		return
	end
	flags.move = true
	toast(player, "Use Jump: Space, controller A, or the touch button. Hold for height; release for a short hop.")
end

function TutorialService.OnJumped(player: Player, flags: TutorialFlags, inHub: boolean)
	if flags.jump or not flags.move then
		return
	end
	flags.jump = true
	if inHub and not flags.hubBonfire then
		toast(player, "Use Interact by the bonfire to start your run.")
		flags.hubBonfire = true
	elseif not inHub then
		toast(player, "Jump over low danger and land outside marked attack areas.")
	end
end

function TutorialService.OnStage1Loaded(player: Player, flags: TutorialFlags)
	activeFlags[player] = flags
	SessionService.Delay(player, 2.0, function()
		if activeFlags[player] == flags and not flags.attack then
			toast(player, "Face the crabs, then use Attack: click/J, controller X, or the touch button.")
		end
	end)
end

function TutorialService.OnAttack(player: Player, flags: TutorialFlags)
	if flags.attack then
		return
	end
	flags.attack = true
	toast(player, "Watch the marked attack area. Use Dodge to cross danger safely; attack after it passes.")
end

function TutorialService.OnDodgeAccepted(player: Player, flags: TutorialFlags)
	if flags.dodgeAccepted or not flags.attack then
		return
	end
	flags.dodgeAccepted = true
	toast(player, if flags.coldOne then "Dodge gives brief protection. Keep clear of the next marked attack." else "Dodge gives brief protection. Walk into the glowing Florida Dew to recover.")
end

-- Called after server motion correction. These milestones describe observed motion
-- and an accepted dodge; they do not claim that an attack was successfully avoided.
function TutorialService.Observe(player: Player, flags: TutorialFlags, inHub: boolean)
	activeFlags[player] = flags
	if flags.move and flags.jump then observations[player] = nil; return end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not SessionService.IsOwner(player) or not char or not root or not hum or hum.Health <= 0 then
		observations[player] = nil
		return
	end
	local position = root.Position
	if position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then return end
	local _, generation = SessionService.GetIdentity(player)
	local revision = (char:GetAttribute("MotionResetRevision") :: number?) or 0
	local teleport = (char:GetAttribute("AuthorizedTeleportUntil") :: number?) or 0
	local impulse = (char:GetAttribute("ImpulseRevision") :: number?) or 0
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	params.RespectCanCollide = true
	local floor = Workspace:Raycast(position, Vector3.new(0, -(CharacterGeometry.FeetDistance(char,root,hum) + 0.35), 0), params)
	local velocity = root.AssemblyLinearVelocity
	local grounded = floor ~= nil and floor.Normal.Y >= 0.65 and math.abs(velocity.Y) < 4
	local old = observations[player]
	if not old or old.character ~= char or old.generation ~= generation or old.flags ~= flags
		or old.revision ~= revision or old.teleport ~= teleport or old.impulse ~= impulse then
		observations[player] = { character = char, generation = generation, flags = flags, revision = revision,
			teleport = teleport, impulse = impulse, originX = position.X, position = position,
			grounded = grounded, takeoffY = nil, takeoffAt = 0 }
		return
	end
	local now = os.clock()
	if not flags.move and math.abs(position.X - old.originX) >= 4 and math.abs(velocity.X) <= 80
		and math.abs((char:GetAttribute("ExternalVelocityX") :: number?) or 0) < 0.1 then
		TutorialService.OnMoved(player, flags)
	end
	if old.grounded and velocity.Y > 6 then old.takeoffY, old.takeoffAt = old.position.Y, now end
	local takeoffY = old.takeoffY
	if takeoffY and now - old.takeoffAt < 0.4 and position.Y - takeoffY >= 0.6 and velocity.Y > 0 then
		TutorialService.OnJumped(player, flags, inHub)
		old.takeoffY = nil
	end
	if grounded or now - old.takeoffAt >= 0.4 then old.takeoffY = nil end
	old.position, old.grounded = position, grounded
end

function TutorialService.OnColdOne(player: Player, flags: TutorialFlags)
	if flags.coldOne then
		return
	end
	flags.coldOne = true
	toast(player, "Hangover cleared. Keep right — King of the Tide Pool awaits.")
end

function TutorialService.OnCrabKingIntro(player: Player, flags: TutorialFlags)
	if flags.crabKing then
		return
	end
	flags.crabKing = true
	toast(player, "MINIBOSS — King of the Tide Pool! Dodge the pinch, then punish.")
end

Players.PlayerRemoving:Connect(function(player)
	observations[player] = nil
	activeFlags[player] = nil
end)

return TutorialService
