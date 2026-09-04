--!strict
--[[ Phase 1 — once-through tutorial beat map (hub + Daytona ~60s).
	Prompts fire once in order; never spam every N seconds.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local TutorialService = {}

export type TutorialFlags = {
	move: boolean,
	jump: boolean,
	attack: boolean,
	dodgeTele: boolean,
	coldOne: boolean,
	crabKing: boolean,
	hubBonfire: boolean,
	started: boolean,
}

function TutorialService.NewFlags(): TutorialFlags
	return {
		move = false,
		jump = false,
		attack = false,
		dodgeTele = false,
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
	if flags.started then
		return
	end
	flags.started = true
	task.delay(0.8, function()
		if not flags.move then
			toast(player, "TUTORIAL — A/D or ←→ to move")
		end
	end)
end

--- Called when server detects meaningful X movement from spawn
function TutorialService.OnMoved(player: Player, flags: TutorialFlags)
	if flags.move then
		return
	end
	flags.move = true
	toast(player, "Nice. Space to jump — gaps matter later.")
end

function TutorialService.OnJumped(player: Player, flags: TutorialFlags)
	if flags.jump or not flags.move then
		return
	end
	flags.jump = true
	if not flags.hubBonfire then
		toast(player, "Press E or click the bonfire prompt to start your run")
		flags.hubBonfire = true
	end
end

function TutorialService.OnStage1Loaded(player: Player, flags: TutorialFlags)
	task.delay(2.0, function()
		if not flags.attack then
			toast(player, "Click or J to attack — face the crabs")
		end
	end)
end

function TutorialService.OnAttack(player: Player, flags: TutorialFlags)
	if flags.attack then
		return
	end
	flags.attack = true
	toast(player, "When you see a RED telegraph — Shift / dash to i-frame dodge")
end

function TutorialService.OnDodgeDuringTele(player: Player, flags: TutorialFlags)
	if flags.dodgeTele then
		return
	end
	flags.dodgeTele = true
	toast(player, "Clean dodge! Walk into the glowing Florida Dew (Cold One)")
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

return TutorialService
