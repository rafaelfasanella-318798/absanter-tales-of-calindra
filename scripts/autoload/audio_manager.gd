class_name AudioManagerAutoload
extends Node
## Manages audio buses, background music crossfading, and SFX pooling.

signal music_started(track_name: String)
signal music_stopped


func play_music(_track_name: String, _fade_in: float = 1.0) -> void:
	music_started.emit(_track_name)


func stop_music(_fade_out: float = 1.0) -> void:
	music_stopped.emit()


func play_sfx(_sfx_name: String) -> void:
	pass
