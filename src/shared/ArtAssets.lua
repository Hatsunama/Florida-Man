--!strict
--[[ ArtAssets — Mesh / Animation ID registry + validation.
	NEVER invent rbxassetid values. Leave tables empty until Studio upload.
	Part kits remain the permanent CI / Rojo fallback (ArtKit InEngine_v3).
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtAssets = {}

export type ClipBag = {
	Idle: string,
	Run: string,
	Jump: string,
	Attack1: string,
	Attack2: string,
	Attack3: string,
	Dodge: string,
	Skill: string,
	Swap: string?,
}

-- Fill ONLY after real Studio uploads. Keys = persona id.
ArtAssets.AnimationIds = {
	BeachBurnout = {
		Idle = "",
		Run = "",
		Jump = "",
		Attack1 = "",
		Attack2 = "",
		Attack3 = "",
		Dodge = "",
		Skill = "",
		Swap = "",
	},
	CrabKing = {
		Idle = "",
		Run = "",
		Jump = "",
		Attack1 = "",
		Attack2 = "",
		Attack3 = "",
		Dodge = "",
		Skill = "",
		Swap = "",
	},
	GatorHauler = {
		Idle = "",
		Run = "",
		Jump = "",
		Attack1 = "",
		Attack2 = "",
		Attack3 = "",
		Dodge = "",
		Skill = "",
		Swap = "",
	},
	SnakeCharmer = {
		Idle = "",
		Run = "",
		Jump = "",
		Attack1 = "",
		Attack2 = "",
		Attack3 = "",
		Dodge = "",
		Skill = "",
		Swap = "",
	},
} :: { [string]: ClipBag }

-- Optional MeshPart model names under ReplicatedStorage.Assets.Meshes (Studio).
-- Empty until uploaded; EnemyFactory / WorldBuilder clone by FindFirstChild(name).
ArtAssets.MeshSubjects = {
	"BeachCrab",
	"CrabKingBoss",
	"DriveThruGator",
	"OilGator",
	"Spillfather",
	"CaptainSteve",
}

local FAKE_NUMERIC = {
	["0"] = true,
	["00"] = true,
	["000"] = true,
	["0000"] = true,
	["123"] = true,
	["1234"] = true,
	["12345"] = true,
	["123456"] = true,
	["1234567"] = true,
	["12345678"] = true,
	["123456789"] = true,
	["1234567890"] = true,
	["1111111111"] = true,
	["9999999999"] = true,
}

--- True only for non-empty rbxassetid:// with a plausible numeric id (not placeholder).
function ArtAssets.IsValidAssetId(id: any): boolean
	if typeof(id) ~= "string" or id == "" then
		return false
	end
	local num = string.match(id, "^rbxassetid://(%d+)$")
	if not num then
		return false
	end
	if FAKE_NUMERIC[num] then
		return false
	end
	-- Real marketplace / creator uploads are typically ≥6 digits; reject tiny stubs.
	if #num < 6 then
		return false
	end
	return true
end

function ArtAssets.GetAnimationId(personaId: string, clip: string): string?
	local bag = ArtAssets.AnimationIds[personaId]
	if not bag then
		return nil
	end
	local id = (bag :: any)[clip]
	if ArtAssets.IsValidAssetId(id) then
		return id :: string
	end
	return nil
end

--- Clone Mesh_v1 kit if Studio placed a Model under Assets.Meshes[subjectName].
function ArtAssets.TryCloneMeshModel(subjectName: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if not assets then
		return nil
	end
	local meshes = assets:FindFirstChild("Meshes")
	if not meshes then
		return nil
	end
	local template = meshes:FindFirstChild(subjectName)
	if not template or not template:IsA("Model") then
		return nil
	end
	local clone = template:Clone()
	clone:SetAttribute("ArtKit", "Mesh_v1")
	return clone
end

ArtAssets.ART_KIT_PART = "InEngine_v3"
ArtAssets.ART_KIT_MESH = "Mesh_v1"

return ArtAssets
