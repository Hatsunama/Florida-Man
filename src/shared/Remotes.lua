--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local NAMES = {
	"RequestStartRun",
	"RequestAttack",
	"RequestSkill",
	"RequestDodge",
	"RequestSwap",
	"RequestJump",
	"EquipWeapon",
	"PickDraftItem",
	"SmashPersona",
	"UpgradePersona",
	"TalkCaptainSteve",
	"RescueTurtle",
	"ContinueFromNewspaper",
	"StateUpdate",
	"CombatEvent",
	"ShowNewspaper",
	"ShowDraft",
	"ShowTagline",
	"ShowCredits",
	"StageLoaded",
	"Toast",
	"DamageNumber",
	"PlaySound",
	"TutorialBeat",
	"SyncSettings",
}

function Remotes.InitServer(): Folder
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, name in NAMES do
		local existing = folder:FindFirstChild(name)
		if not existing then
			local r = Instance.new("RemoteEvent")
			r.Name = name
			r.Parent = folder
		end
	end
	return folder :: Folder
end

function Remotes.Get(name: string): RemoteEvent
	local folder = ReplicatedStorage:WaitForChild("Remotes", 30) :: Folder
	return folder:WaitForChild(name, 30) :: RemoteEvent
end

return Remotes
