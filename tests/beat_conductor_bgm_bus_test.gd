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

	var game_settings := root.get_node("GameSettings")
	var original_bgm_volume := float(game_settings.get("bgm_volume"))
	game_settings.set("bgm_volume", 37.0)
	var beat_conductor := packed.instantiate() as BeatConductor
	root.add_child(beat_conductor)
	await process_frame

	var audio_player := beat_conductor.get_node("AudioStreamPlayer") as AudioStreamPlayer
	_expect(audio_player != null, "AudioStreamPlayer node exists")
	_expect(AudioServer.get_bus_count() == 1, "AudioServer uses only the Master bus")
	_expect(audio_player.bus == "Master", "AudioStreamPlayer uses Master bus")
	_expect(audio_player.is_in_group("bgm_audio_players"), "BGM player has the BGM volume group")
	_expect(is_equal_approx(audio_player.volume_linear, 0.37), "BGM volume applies when the player enters the tree")
	game_settings.set("bgm_volume", original_bgm_volume)
	game_settings.call("apply_settings")

	beat_conductor.queue_free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("BeatConductorBgmBusTest: %s" % message)
