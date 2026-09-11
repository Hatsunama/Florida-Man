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

for _, personaId in { "GolfCartBandit", "FireworksEnthusiast", "LizardBreath", "TurtlePaladin" } do
	ArtAssets.AnimationIds[personaId] = { Idle = "", Run = "", Jump = "", Attack1 = "", Attack2 = "", Attack3 = "", Dodge = "", Skill = "", Swap = "" }
end

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

-- Optional imported content is presentation data. Executable/audio instances and collision policy
-- cannot enter the game through a model template. Failed contracts retain the procedural kit.
function ArtAssets.ValidateMeshModel(model: Model): (boolean, string)
	local root = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") or not root:IsDescendantOf(model) then return false, "Missing model root" end
	if model:GetAttribute("FM_AssetSchema") ~= 1 or model:GetAttribute("FM_ForwardAxis") ~= "+X" then return false, "Missing reviewed orientation/schema contract" end
	local parts = 0
	local descendants = model:GetDescendants()
	if #descendants > 1024 then return false, "Model exceeds instance budget" end
	for _, object in descendants do
		if object:IsA("LuaSourceContainer") or object:IsA("Sound") or object:IsA("AudioPlayer")
			or object:IsA("RemoteEvent") or object:IsA("RemoteFunction") or object:IsA("BindableEvent") or object:IsA("BindableFunction")
			or object:IsA("BodyMover") or object:IsA("AlignPosition") or object:IsA("AlignOrientation")
			or object:IsA("LinearVelocity") or object:IsA("VectorForce") or object:IsA("AngularVelocity") then
			return false, "Model contains a runtime or audio owner"
		end
		if object:IsA("BasePart") then
			parts += 1
			local size = object.Size
			local distance = (object.Position - root.Position).Magnitude
			if size.X ~= size.X or size.Y ~= size.Y or size.Z ~= size.Z or distance ~= distance
				or math.max(size.X,size.Y,size.Z) > 80 or distance > 80 then return false, "Unbounded model geometry" end
		end
	end
	if parts > 256 then return false, "Model exceeds part budget" end
	return true, "Validated presentation template"
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
	local valid = ArtAssets.ValidateMeshModel(template)
	if not valid then return nil end
	local clone = template:Clone()
	for _, object in clone:GetDescendants() do
		if object:IsA("BasePart") then object.CanCollide=false; object.CanQuery=false; object.CanTouch=false end
	end
	clone:SetAttribute("ArtKit", "Mesh_v1")
	return clone
end

ArtAssets.ART_KIT_PART = "InEngine_v3"
ArtAssets.ART_KIT_MESH = "Mesh_v1"

return ArtAssets
