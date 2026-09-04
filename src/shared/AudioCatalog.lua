--!strict
--[[ Phase 5 audio catalog.
	Uses engine rbxasset:// library sounds (always available, no upload).
	Music beds: NO free commercial music IDs are wired — we layer looping ambient SFX
	so biomes are never silent. Replace MUSIC_* SoundIds in Studio when licensed beds exist.
]]

local AudioCatalog = {}

AudioCatalog.GROUPS = { "Master", "SFX", "Music", "UI", "Ambience" }

-- Volumes relative to Master (0–1)
AudioCatalog.GROUP_VOLUME = {
	Master = 1,
	SFX = 0.85,
	Music = 0.45,
	UI = 0.9,
	Ambience = 0.55,
}

-- Core verb + UI + combat SFX (SoundId must be non-empty)
AudioCatalog.SFX = {
	SFX_Swing = "rbxasset://sounds/swoosh.wav",
	SFX_Hit = "rbxasset://sounds/collision.wav",
	SFX_Dodge = "rbxasset://sounds/action_footsteps_plastic.mp3",
	SFX_CrabClick = "rbxasset://sounds/switch.wav",
	SFX_GatorHiss = "rbxasset://sounds/swoosh.wav",
	SFX_DraftSting = "rbxasset://sounds/electronicpingshort.wav",
	SFX_NewspaperSting = "rbxasset://sounds/electronicpingshort.wav",
	SFX_CreditsSwell = "rbxasset://sounds/short spring sound.wav",
	SFX_BossIntro = "rbxasset://sounds/Rocket shot.wav",
	SFX_Footstep = "rbxasset://sounds/action_footsteps_plastic.mp3",
	SFX_Splash = "rbxasset://sounds/impact_water.mp3",
	SFX_Flame = "rbxasset://sounds/swoosh.wav",
	SFX_UIClick = "rbxasset://sounds/switch.wav",
	SFX_Typewriter = "rbxasset://sounds/switch.wav",
	SFX_SteveBeep = "rbxasset://sounds/button.wav",
}

-- Biome looping ambient beds (SFX layers standing in for music)
-- Honest: these are ambient loops, not authored score. Documented as placeholders.
AudioCatalog.BIOME_BEDS = {
	hub = {
		{ name = "Bed_HubFlame", id = "rbxasset://sounds/swoosh.wav", volume = 0.12, pitch = 0.55 },
		{ name = "Bed_HubClick", id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.05, pitch = 0.4 },
	},
	beach = {
		{ name = "Bed_BeachSurf", id = "rbxasset://sounds/impact_water.mp3", volume = 0.22, pitch = 0.7 },
		{ name = "Bed_BeachWind", id = "rbxasset://sounds/swoosh.wav", volume = 0.1, pitch = 0.45 },
	},
	town = {
		{ name = "Bed_TownBuzz", id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.08, pitch = 0.35 },
		{ name = "Bed_TownHum", id = "rbxasset://sounds/collision.wav", volume = 0.06, pitch = 0.3 },
	},
	swamp = {
		{ name = "Bed_SwampDrip", id = "rbxasset://sounds/impact_water.mp3", volume = 0.18, pitch = 0.55 },
		{ name = "Bed_SwampBug", id = "rbxasset://sounds/switch.wav", volume = 0.07, pitch = 1.4 },
	},
	facility = {
		{ name = "Bed_FacHum", id = "rbxasset://sounds/collision.wav", volume = 0.1, pitch = 0.25 },
		{ name = "Bed_FacSpark", id = "rbxasset://sounds/electronicpingshort.wav", volume = 0.09, pitch = 0.8 },
	},
	offshore = {
		{ name = "Bed_OffWave", id = "rbxasset://sounds/impact_water.mp3", volume = 0.2, pitch = 0.5 },
		{ name = "Bed_OffMetal", id = "rbxasset://sounds/collision.wav", volume = 0.08, pitch = 0.4 },
	},
}

AudioCatalog.GROUP_FOR = {
	SFX_Swing = "SFX",
	SFX_Hit = "SFX",
	SFX_Dodge = "SFX",
	SFX_CrabClick = "SFX",
	SFX_GatorHiss = "SFX",
	SFX_BossIntro = "SFX",
	SFX_Footstep = "SFX",
	SFX_Splash = "SFX",
	SFX_Flame = "SFX",
	SFX_DraftSting = "UI",
	SFX_NewspaperSting = "UI",
	SFX_CreditsSwell = "Music",
	SFX_UIClick = "UI",
	SFX_Typewriter = "UI",
	SFX_SteveBeep = "UI",
}

function AudioCatalog.SoundId(name: string): string
	return AudioCatalog.SFX[name] or ""
end

function AudioCatalog.GroupName(name: string): string
	return AudioCatalog.GROUP_FOR[name] or "SFX"
end

return AudioCatalog
