extends Node

# Bus Constants
const BUS_MUSIC = &"Music"
const BUS_SFX = &"SFX"
const BUS_VOICELINES = &"Voicelines"

var music_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer

func _ready() -> void:
	# Dedicated player for background music
	music_player = AudioStreamPlayer.new()
	music_player.bus = BUS_MUSIC
	add_child(music_player)

	# Dedicated player for assistant voicelines
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = BUS_VOICELINES
	add_child(voice_player)

# Diagnostic test function to verify bus routing and volume controls
func test_audio_system(sound_path: String = "res://Assets/Audio/click.wav") -> void:
	print("\n================ STARTING AUDIO BUS TEST ================")
	
	var test_busses = [BUS_SFX, BUS_MUSIC, BUS_VOICELINES]
	
	for bus_name in test_busses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		print("\n--- Testing Bus: '", bus_name, "' (Index: ", bus_idx, ") ---")
		
		if bus_idx == -1:
			push_error("FAIL: Bus '" + String(bus_name) + "' does NOT exist in AudioServer!")
			continue
			
		# Save original bus settings to restore later
		var original_vol = AudioServer.get_bus_volume_db(bus_idx)
		var original_mute = AudioServer.is_bus_mute(bus_idx)
		
		# Step 1: Normal playback
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, 0.0)
		print("1. Playing at NORMAL volume (0 dB)...")
		_play_test_sound(sound_path, bus_name)
		await get_tree().create_timer(1.0).timeout
		
		# Step 2: Alter volume to low (-24 dB)
		AudioServer.set_bus_volume_db(bus_idx, -24.0)
		print("2. Playing at QUIET volume (-24 dB)...")
		_play_test_sound(sound_path, bus_name)
		await get_tree().create_timer(1.0).timeout
		
		# Step 3: Mute the bus completely
		AudioServer.set_bus_mute(bus_idx, true)
		print("3. Playing while MUTED (Should hear nothing)...")
		_play_test_sound(sound_path, bus_name)
		await get_tree().create_timer(1.0).timeout
		
		# Restore original settings
		AudioServer.set_bus_volume_db(bus_idx, original_vol)
		AudioServer.set_bus_mute(bus_idx, original_mute)
		print("--- Restored original settings for '", bus_name, "' ---")

	print("\n================ AUDIO BUS TEST COMPLETE ================\n")

# Internal helper used only by the test function
func _play_test_sound(path: String, bus_name: StringName) -> void:
	var stream = load(path)
	if not stream:
		push_error("Could not load sound at: " + path)
		return
		
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = stream
	temp_player.bus = bus_name
	add_child(temp_player)
	temp_player.play()
	temp_player.finished.connect(temp_player.queue_free)

# Play one-shot sound effects by path
func play_sfx(path: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var stream = load(path)
	if not stream:
		push_error("AudioManager: Could not find audio file at path: " + path)
		return

	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = BUS_SFX
	
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

# Play background music by path
func play_music(path: String, volume_db: float = 0.0) -> void:
	var stream = load(path)
	if not stream:
		push_error("AudioManager: Could not find audio file at path: " + path)
		return

	if music_player.stream == stream and music_player.playing:
		return

	music_player.stream = stream
	music_player.volume_db = volume_db
	music_player.play()

# Play voicelines by path (interrupts previous line by default)
func play_voiceline(path: String, interrupt: bool = true, volume_db: float = 0.0) -> void:
	if voice_player.playing and not interrupt:
		return

	var stream = load(path)
	if not stream:
		push_error("AudioManager: Could not find audio file at path: " + path)
		return

	voice_player.stop()
	voice_player.stream = stream
	voice_player.volume_db = volume_db
	voice_player.play()

# Stop all active audio
func stop_all() -> void:
	music_player.stop()
	voice_player.stop()
