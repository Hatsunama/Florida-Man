local Policy = require('../src/shared/AudioPolicy')
local cases = {
	Sound = 'sound', AudioPlayer = 'player', SoundGroup = 'volume',
	VideoFrame = 'volume', VideoPlayer = 'volume',
	SoundEffect = 'effect', ChorusSoundEffect = 'effect', AssetSoundEffect = 'effect',
	AudioDeviceInput = 'remove', AudioDeviceOutput = 'remove', AudioEmitter = 'remove',
	AudioListener = 'remove', AudioFader = 'remove', AudioAnalyzer = 'remove',
	AudioChannelMixer = 'remove', AudioChannelSplitter = 'remove', AudioCompressor = 'remove',
	AudioRecorder = 'remove', AudioSpeechToText = 'remove', AudioTextToSpeech = 'remove',
	AudioFutureSource = 'remove', Wire = 'remove',
	SoundService = 'none', SoundShimService = 'none', AudioFocusService = 'none',
	VoiceChatService = 'none', VoiceChatInternal = 'none',
}
local checks = 0
for className, mode in cases do
	assert(Policy.IsForbiddenClass(className), className .. ' rejected from presentation templates')
	assert(Policy.GetSuppression(className) == mode, className .. ' uses compatible suppression')
	checks += 2
end
for _, className in { 'Model', 'Part', 'MeshPart', 'Attachment', 'Animation', 'AnimationController',
	'ParticleEmitter', 'Beam', 'Trail', 'Folder', 'ContentProvider', 'WireframeHandleAdornment', 'FloorWire' } do
	assert(not Policy.IsForbiddenClass(className), className .. ' remains valid presentation data')
	assert(Policy.GetSuppression(className) == 'none', className .. ' remains untouched')
	checks += 2
end
print('PASS ' .. tostring(checks) .. ' production audio policy checks')
