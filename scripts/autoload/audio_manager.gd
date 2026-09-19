class_name AudioManagerAutoload
extends Node
## Manages audio buses, background music crossfading, and SFX pooling.

signal music_started(track_name: String)
signal music_stopped
signal sfx_played(sfx_name: String)

const SAMPLE_RATE: int = 22050

var current_track: String = ""
var master_volume: float = 1.0
var music_volume: float = 1.0
var sfx_volume: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_players()


func _setup_audio_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	for i in range(8):
		var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		_sfx_players.append(sfx_player)


func play_music(track_name: String, _fade_in: float = 0.5) -> void:
	if current_track == track_name and _music_player.playing:
		return

	current_track = track_name
	music_started.emit(track_name)

	var path: String = "res://assets/audio/music/%s.ogg" % track_name
	if ResourceLoader.exists(path):
		var stream: AudioStream = load(path) as AudioStream
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(music_volume * master_volume)
		_music_player.play()
	else:
		# Synthetic placeholder tone stream for music
		_music_player.stop()


func stop_music(_fade_out: float = 0.5) -> void:
	current_track = ""
	_music_player.stop()
	music_stopped.emit()


func play_sfx(sfx_name: String) -> void:
	sfx_played.emit(sfx_name)

	var stream: AudioStream = _get_or_generate_sfx(sfx_name)
	if stream == null:
		return

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return

	# If all busy, steal the first player
	if not _sfx_players.is_empty():
		_sfx_players[0].stream = stream
		_sfx_players[0].volume_db = linear_to_db(sfx_volume * master_volume)
		_sfx_players[0].play()


func set_master_volume(val: float) -> void:
	master_volume = clampf(val, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)


func set_music_volume(val: float) -> void:
	music_volume = clampf(val, 0.0, 1.0)
	if _music_player != null:
		_music_player.volume_db = linear_to_db(music_volume * master_volume)


func set_sfx_volume(val: float) -> void:
	sfx_volume = clampf(val, 0.0, 1.0)


func _get_or_generate_sfx(sfx_name: String) -> AudioStream:
	if _sfx_cache.has(sfx_name):
		return _sfx_cache[sfx_name]

	var file_path: String = "res://assets/audio/sfx/%s.wav" % sfx_name
	if ResourceLoader.exists(file_path):
		var s: AudioStream = load(file_path) as AudioStream
		_sfx_cache[sfx_name] = s
		return s

	# Procedural retro chiptune waveform generation
	var generated: AudioStreamWAV = _create_procedural_chiptune_sfx(sfx_name)
	_sfx_cache[sfx_name] = generated
	return generated


func _create_procedural_chiptune_sfx(sfx_name: String) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SAMPLE_RATE

	var duration: float = 0.12
	var freq: float = 440.0

	match sfx_name:
		"menu_select":
			freq = 660.0
			duration = 0.06
		"menu_back":
			freq = 330.0
			duration = 0.06
		"slash":
			freq = 220.0
			duration = 0.10
		"hit":
			freq = 150.0
			duration = 0.12
		"heal":
			freq = 880.0
			duration = 0.20
		"item":
			freq = 550.0
			duration = 0.10
		"door":
			freq = 200.0
			duration = 0.15
		"level_up":
			freq = 980.0
			duration = 0.35

	var num_samples: int = int(float(SAMPLE_RATE) * duration)
	var byte_data: PackedByteArray = PackedByteArray()
	byte_data.resize(num_samples)

	for i in range(num_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		# Square wave with envelope
		var phase: float = fmod(t * freq, 1.0)
		var val: float = 1.0 if phase < 0.5 else -1.0
		var envelope: float = 1.0 - (float(i) / float(num_samples))
		var sample_val: int = int(clampf((val * envelope * 0.4) * 127.0 + 128.0, 0.0, 255.0))
		byte_data[i] = sample_val

	wav.data = byte_data
	return wav
