--!strict
--[[ CombatService — owned combat helpers: melee tests, knockback, server i-frames, attack recovery. ]]

local Players = game:GetService("Players")
local Constants = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Constants"))

local CombatService = {}

local iframesUntil: { [Player]: number } = {}
local attackReadyAt: { [Player]: number } = {}

local ATTACK_RECOVERY = 0.22
local POINT_BLANK = 2.5

function CombatService.SetIFrames(player: Player, duration: number)
	local untilT = os.clock() + math.max(0, duration)
	local prev = iframesUntil[player] or 0
	iframesUntil[player] = math.max(prev, untilT)
end

function CombatService.HasIFrames(player: Player): boolean
	local t = iframesUntil[player]
	if not t then
		return false
	end
	if os.clock() < t then
		return true
	end
	iframesUntil[player] = nil
	return false
end

function CombatService.ClearIFrames(player: Player)
	iframesUntil[player] = nil
end

function CombatService.CanAttack(player: Player): boolean
	local t = attackReadyAt[player]
	if t and os.clock() < t then
		return false
	end
	return true
end

function CombatService.MarkAttack(player: Player, recovery: number?)
	attackReadyAt[player] = os.clock() + (recovery or ATTACK_RECOVERY)
end

function CombatService.LaneKnockback(originX: number, targetPos: Vector3, strength: number): Vector3
	local dir = if targetPos.X >= originX then 1 else -1
	local kb = math.clamp(strength or Constants.KNOCKBACK_BASE, 0, 24)
	return Vector3.new(targetPos.X + dir * kb, targetPos.Y, Constants.LANE_Z)
end

function CombatService.InLaneMelee(attackerX: number, facing: number, targetX: number, range: number): boolean
	local dx = targetX - attackerX
	local adx = math.abs(dx)
	-- Intentional point-blank (document: both sides, very close)
	if adx <= POINT_BLANK then
		return true
	end
	-- Facing-required for anything beyond point-blank
	if adx > range then
		return false
	end
	return math.sign(dx + 0.001) == facing
end

Players.PlayerRemoving:Connect(function(player)
	iframesUntil[player] = nil
	attackReadyAt[player] = nil
end)

return CombatService
