extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const BGM_BUS_NAME := "BGM"
const SE_BUS_NAME := "SE"

const DEFAULT_MASTER_VOLUME := 80.0
const DEFAULT_BGM_VOLUME := 70.0
const DEFAULT_SE_VOLUME := 80.0
const DEFAULT_TEXT_SPEED := 1
const DEFAULT_WINDOW_SIZE := 1
const DEFAULT_FULLSCREEN := false
const DEFAULT_DIFFICULTY := 1

const WINDOW_SIZES: Array[Vector2i] = [
	Vector2i(640, 360),
	Vector2i(960, 540),
	Vector2i(1280, 720),
	Vector2i(1600, 900),
]

const TEXT_INTERVALS: Array[float] = [
	0.06,
	0.04,
	0.02,
	0.0,
]

var master_volume := DEFAULT_MASTER_VOLUME
var bgm_volume := DEFAULT_BGM_VOLUME
var se_volume := DEFAULT_SE_VOLUME
var text_speed := DEFAULT_TEXT_SPEED
var window_size := DEFAULT_WINDOW_SIZE
var fullscreen := DEFAULT_FULLSCREEN
var difficulty := DEFAULT_DIFFICULTY


func _ready() -> void:
	_ensure_audio_bus(BGM_BUS_NAME)
	_ensure_audio_bus(SE_BUS_NAME)
	load_settings()
	apply_settings()


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return
	master_volume = clampf(float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME)), 0.0, 100.0)
	bgm_volume = clampf(float(config.get_value("audio", "bgm_volume", DEFAULT_BGM_VOLUME)), 0.0, 100.0)
	se_volume = clampf(float(config.get_value("audio", "se_volume", DEFAULT_SE_VOLUME)), 0.0, 100.0)
	text_speed = clampi(int(config.get_value("gameplay", "text_speed", DEFAULT_TEXT_SPEED)), 0, TEXT_INTERVALS.size() - 1)
	window_size = clampi(int(config.get_value("display", "window_size", DEFAULT_WINDOW_SIZE)), 0, WINDOW_SIZES.size() - 1)
	fullscreen = bool(config.get_value("display", "fullscreen", DEFAULT_FULLSCREEN))
	difficulty = clampi(int(config.get_value("gameplay", "difficulty", DEFAULT_DIFFICULTY)), 0, 2)


func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "se_volume", se_volume)
	config.set_value("gameplay", "text_speed", text_speed)
	config.set_value("display", "window_size", window_size)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("gameplay", "difficulty", difficulty)
	config.save(SETTINGS_PATH)


func apply_settings() -> void:
	_ensure_audio_bus(BGM_BUS_NAME)
	_ensure_audio_bus(SE_BUS_NAME)
	_set_bus_volume("Master", master_volume)
	_set_bus_volume(BGM_BUS_NAME, bgm_volume)
	_set_bus_volume(SE_BUS_NAME, se_volume)
	_apply_window_settings()
	settings_changed.emit()


func reset_to_defaults() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	bgm_volume = DEFAULT_BGM_VOLUME
	se_volume = DEFAULT_SE_VOLUME
	text_speed = DEFAULT_TEXT_SPEED
	window_size = DEFAULT_WINDOW_SIZE
	fullscreen = DEFAULT_FULLSCREEN
	difficulty = DEFAULT_DIFFICULTY
	save_settings()
	apply_settings()


func get_text_interval() -> float:
	return TEXT_INTERVALS[text_speed]


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


func set_se_volume(value: float) -> void:
	se_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


func set_text_speed(value: int) -> void:
	text_speed = clampi(value, 0, TEXT_INTERVALS.size() - 1)
	_apply_and_save()


func set_window_size(value: int) -> void:
	window_size = clampi(value, 0, WINDOW_SIZES.size() - 1)
	_apply_and_save()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_and_save()


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, 2)
	_apply_and_save()


func _apply_and_save() -> void:
	save_settings()
	apply_settings()


func _set_bus_volume(bus_name: String, volume_percent: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var linear_volume := clampf(volume_percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0)
	if linear_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	var bus_index := AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(bus_index, bus_name)
	AudioServer.set_bus_send(bus_index, "Master")


func _apply_window_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(WINDOW_SIZES[window_size])
