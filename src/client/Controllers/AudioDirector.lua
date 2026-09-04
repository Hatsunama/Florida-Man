--!strict
local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AudioCatalog = require(Shared:WaitForChild("AudioCatalog"))

local AudioDirector = {}

-- Policy: conversations = Tagline/Toast/Newspaper popups only. No dialogue VO/SFX.
local DIALOGUE_SFX_BLOCK = {
	SFX_SteveBeep = true,
	SFX_Typewriter = true,
}

local groups: { [string]: SoundGroup } = {}
local bedFolder: Folder? = nil
local currentBiome: string? = nil
local duckUntil = 0
local duckConn: RBXScriptConnection? = nil

local function ensureGroups()
	local master = SoundService:FindFirstChild("FM_Master")
	if not master or not master:IsA("SoundGroup") then
		if master then
			master:Destroy()
		end
		master = Instance.new("SoundGroup")
		master.Name = "FM_Master"
		master.Volume = AudioCatalog.GROUP_VOLUME.Master
		master.Parent = SoundService
	end
	groups.Master = master :: SoundGroup

	for _, name in AudioCatalog.GROUPS do
		if name ~= "Master" then
			local key = "FM_" .. name
			local g = SoundService:FindFirstChild(key)
			if not g or not g:IsA("SoundGroup") then
				if g then
					g:Destroy()
				end
				g = Instance.new("SoundGroup")
				g.Name = key
				g.Volume = AudioCatalog.GROUP_VOLUME[name] or 0.8
				g.Parent = SoundService
			end
			groups[name] = g :: SoundGroup
		end
	end
end

local function applyDuck()
	local music = groups.Music
	local amb = groups.Ambience
	if not music or not amb then
		return
	end
	local ducked = os.clock() < duckUntil
	music.Volume = if ducked then (AudioCatalog.GROUP_VOLUME.Music * 0.35) else AudioCatalog.GROUP_VOLUME.Music
	amb.Volume = if ducked then (AudioCatalog.GROUP_VOLUME.Ambience * 0.4) else AudioCatalog.GROUP_VOLUME.Ambience
end

function AudioDirector.Duck(seconds: number?)
	duckUntil = math.max(duckUntil, os.clock() + (seconds or 0.55))
	applyDuck()
end

function AudioDirector.Play(name: string, opts: { volume: number?, pitch: number? }?)
	ensureGroups()
	if DIALOGUE_SFX_BLOCK[name] then
		return
	end
	local id = AudioCatalog.SoundId(name)
	if id == "" then
		warn("[AudioDirector] empty SoundId for", name)
		return
	end
	local groupName = AudioCatalog.GroupName(name)
	local sg = groups[groupName] or groups.SFX
	if groupName == "UI" or groupName == "Music" then
		AudioDirector.Duck(0.6)
	end

	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Volume = (opts and opts.volume) or 0.55
	s.PlaybackSpeed = (opts and opts.pitch) or 1
	s.SoundGroup = sg
	s.Parent = SoundService
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
	task.delay(8, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

--- Prefer StageSounds clone if present (spatial), else one-shot via Play
function AudioDirector.PlayFromWorld(soundName: string)
	if DIALOGUE_SFX_BLOCK[soundName] then
		return
	end
	local world = Workspace:FindFirstChild("GameWorld")
	local folder = world and world:FindFirstChild("StageSounds")
	local src = folder and folder:FindFirstChild(soundName)
	if src and src:IsA("Sound") and src.SoundId ~= "" then
		local groupName = AudioCatalog.GroupName(soundName)
		local sg = groups[groupName] or groups.SFX
		if groupName == "UI" or groupName == "Music" then
			AudioDirector.Duck(0.55)
		end
		local clone = src:Clone()
		clone.SoundGroup = sg
		clone.Parent = SoundService
		clone:Play()
		clone.Ended:Once(function()
			clone:Destroy()
		end)
		task.delay(8, function()
			if clone.Parent then
				clone:Destroy()
			end
		end)
		return
	end
	AudioDirector.Play(soundName)
end

function AudioDirector.StopBiomeBeds()
	if bedFolder then
		bedFolder:Destroy()
		bedFolder = nil
	end
	currentBiome = nil
end

function AudioDirector.StartBiomeBeds(biome: string)
	ensureGroups()
	local key = biome
	if not AudioCatalog.BIOME_BEDS[key] then
		key = "beach"
	end
	if currentBiome == key and bedFolder and bedFolder.Parent then
		return
	end
	AudioDirector.StopBiomeBeds()
	currentBiome = key
	local folder = Instance.new("Folder")
	folder.Name = "FM_BiomeBeds"
	folder.Parent = SoundService
	bedFolder = folder
	local beds = AudioCatalog.BIOME_BEDS[key]
	local amb = groups.Ambience
	for _, bed in beds do
		local s = Instance.new("Sound")
		s.Name = bed.name
		s.SoundId = bed.id
		s.Volume = bed.volume
		s.PlaybackSpeed = bed.pitch
		s.Looped = true
		s.SoundGroup = amb
		s.Parent = folder
		s:Play()
	end
end

function AudioDirector.SyncBiomeFromWorld()
	local world = Workspace:FindFirstChild("GameWorld")
	local biome = world and world:GetAttribute("Biome")
	if typeof(biome) == "string" and biome ~= "" then
		AudioDirector.StartBiomeBeds(biome)
	else
		AudioDirector.StartBiomeBeds("hub")
	end
end

function AudioDirector.Start()
	ensureGroups()
	if duckConn then
		duckConn:Disconnect()
	end
	duckConn = game:GetService("RunService").Heartbeat:Connect(function()
		if duckUntil > 0 then
			applyDuck()
			if os.clock() >= duckUntil then
				duckUntil = 0
				applyDuck()
			end
		end
	end)
	AudioDirector.StartBiomeBeds("hub")
	local player = Players.LocalPlayer
	task.defer(function()
		local world = Workspace:FindFirstChild("GameWorld") or Workspace:WaitForChild("GameWorld", 10)
		if world then
			world:GetAttributeChangedSignal("Biome"):Connect(function()
				AudioDirector.SyncBiomeFromWorld()
			end)
			AudioDirector.SyncBiomeFromWorld()
		end
	end)
	local _ = player
end

return AudioDirector
