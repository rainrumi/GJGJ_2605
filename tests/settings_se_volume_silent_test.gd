extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var volume_script := FileAccess.get_file_as_string(
		"res://scene/main/settings/settings_volume.gd"
	)
	var settings_scene := FileAccess.get_file_as_string(
		"res://scene/main/settings/settings_screen.tscn"
	)
	_expect(not volume_script.is_empty(), "SettingsVolume script can be read")
	_expect(not settings_scene.is_empty(), "SettingsScreen scene can be read")
	_expect(
		not volume_script.contains("feedback_requested.emit()"),
		"SettingsVolume does not request feedback SE",
	)
	_expect(
		not settings_scene.contains(
			'signal="feedback_requested" from="Screen/Panel/Rows/SeVolume"'
		),
		"SE volume row is not connected to feedback SE playback",
	)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("SettingsSeVolumeSilentTest: %s" % message)
