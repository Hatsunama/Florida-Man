--!strict
-- ClassName is engine-owned. Family matching also rejects newly introduced audio
-- nodes without probing unavailable classes or assuming shared playback APIs.
local AudioPolicy = {}

export type Suppression = "sound" | "player" | "volume" | "effect" | "remove" | "none"

function AudioPolicy.IsForbiddenClass(className: string): boolean
	return string.sub(className, 1, 5) == "Audio"
		or string.sub(className, 1, 5) == "Sound"
		or string.sub(className, -11) == "SoundEffect"
		or className == "Wire"
		or className == "VideoFrame"
		or className == "VideoPlayer"
		or string.sub(className, 1, 9) == "VoiceChat"
end

function AudioPolicy.GetSuppression(className: string): Suppression
	if not AudioPolicy.IsForbiddenClass(className) then return "none" end
	-- Roblox-owned services are not removable presentation instances. Their
	-- descendant sources/graphs are still visited by the client. Platform voice
	-- configuration remains a place setting, outside this experience policy.
	if string.sub(className, -7) == "Service" or className == "VoiceChatInternal" then return "none" end
	if className == "Sound" then return "sound" end
	if className == "AudioPlayer" then return "player" end
	if className == "SoundGroup" or className == "VideoFrame" or className == "VideoPlayer" then return "volume" end
	if string.sub(className, -11) == "SoundEffect" then return "effect" end
	-- Wires, devices, listeners, emitters, processors, recording and speech nodes
	-- have differing APIs. Removing them breaks the graph without enabling bypass.
	return "remove"
end

return table.freeze(AudioPolicy)
