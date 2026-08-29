extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://systems/audio/beat_conductor.tscn") as PackedScene
	_expect(packed != null, "BeatConductor scene loads")
	if packed == null:
		quit(_failures)
		return

	var beat_conductor := packed.instantiate() as BeatConductor
	root.add_child(beat_conductor)
	await process_frame

	var audio_player := beat_conductor.get_node("AudioStreamPlayer") as AudioStreamPlayer
	_expect(audio_player != null, "AudioStreamPlayer node exists")
	_expect(audio_player.bus == "BGM", "AudioStreamPlayer uses BGM bus")

	beat_conductor.queue_free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("BeatConductorBgmBusTest: %s" % message)
