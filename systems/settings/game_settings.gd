extends Node

signal settings_changed

const SETTINGS_PATH := "user://settings.cfg"
const BGM_PLAYER_GROUP := &"bgm_audio_players"
const SE_PLAYER_GROUP := &"se_audio_players"
const SE_DUCK_BGM_FACTOR := 0.1
const SE_DUCK_FADE_DURATION := 0.2

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
var _active_native_se_players: Dictionary = {}
var _active_external_se_channels: Dictionary = {}
var _bgm_duck_factor := 1.0
var _bgm_transition_factor := 1.0
var _bgm_duck_tween: Tween
var _bgm_duck_transition_id := 0


# 初期化
func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	load_settings()
	apply_settings()


# 設定読込
func load_settings() -> void:
	# 設定
	var config := ConfigFile.new()
	# エラー
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


# 設定保存
func save_settings() -> void:
	# 設定
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "bgm_volume", bgm_volume)
	config.set_value("audio", "se_volume", se_volume)
	config.set_value("gameplay", "text_speed", text_speed)
	config.set_value("display", "window_size", window_size)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("gameplay", "difficulty", difficulty)
	config.save(SETTINGS_PATH)


# 設定適用
func apply_settings() -> void:
	_set_bus_volume("Master", master_volume)
	_apply_group_volume(BGM_PLAYER_GROUP, bgm_volume * _bgm_duck_factor * _bgm_transition_factor)
	_apply_group_volume(SE_PLAYER_GROUP, se_volume)
	_apply_window_settings()
	var web_audio := get_node_or_null("/root/WebAudioFallback")
	if web_audio != null and web_audio.has_method("set_bgm_duck_factor"):
		web_audio.call("set_bgm_duck_factor", _bgm_duck_factor)
	if web_audio != null and web_audio.has_method("set_bgm_transition_factor"):
		web_audio.call("set_bgm_transition_factor", _bgm_transition_factor)
	_update_bgm_ducking()
	settings_changed.emit()


func play_se(player: AudioStreamPlayer, channel: StringName) -> void:
	_play_se(player, channel, false)


func play_se_with_bgm_ducking(player: AudioStreamPlayer, channel: StringName) -> void:
	_play_se(player, channel, true)


func _play_se(player: AudioStreamPlayer, channel: StringName, duck_bgm: bool) -> void:
	if player == null or player.stream == null:
		return
	var web_audio := get_node_or_null("/root/WebAudioFallback") as WebAudioFallbackService
	if web_audio != null and web_audio.play_se(player.stream, channel, duck_bgm):
		return
	var player_id := player.get_instance_id()
	var finished_callback := Callable(self, "_on_native_se_finished").bind(player_id)
	if not player.finished.is_connected(finished_callback):
		player.finished.connect(finished_callback)
	_active_native_se_players[player_id] = duck_bgm
	player.stop()
	player.play()
	_update_bgm_ducking()


func set_external_se_active(channel: StringName, active: bool, duck_bgm := false) -> void:
	if active:
		_active_external_se_channels[channel] = duck_bgm
	else:
		_active_external_se_channels.erase(channel)
	_update_bgm_ducking()


func _on_native_se_finished(player_id: int) -> void:
	_active_native_se_players.erase(player_id)
	_update_bgm_ducking()


func _update_bgm_ducking() -> void:
	var target_factor := SE_DUCK_BGM_FACTOR if _has_bgm_ducking_se() else 1.0
	if is_equal_approx(_bgm_duck_factor, target_factor):
		return
	_bgm_duck_transition_id += 1
	if _bgm_duck_tween != null and _bgm_duck_tween.is_valid():
		_bgm_duck_tween.kill()
	_bgm_duck_tween = create_tween()
	_bgm_duck_tween.tween_method(
		_set_bgm_duck_factor.bind(_bgm_duck_transition_id),
		_bgm_duck_factor,
		target_factor,
		SE_DUCK_FADE_DURATION,
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)


func _has_bgm_ducking_se() -> bool:
	for should_duck in _active_native_se_players.values():
		if bool(should_duck):
			return true
	for should_duck in _active_external_se_channels.values():
		if bool(should_duck):
			return true
	return false


func _set_bgm_duck_factor(value: float, transition_id: int) -> void:
	if transition_id != _bgm_duck_transition_id:
		return
	_bgm_duck_factor = value
	_apply_group_volume(BGM_PLAYER_GROUP, bgm_volume * _bgm_duck_factor * _bgm_transition_factor)
	var web_audio := get_node_or_null("/root/WebAudioFallback")
	if web_audio != null and web_audio.has_method("set_bgm_duck_factor"):
		web_audio.call("set_bgm_duck_factor", _bgm_duck_factor)


func set_bgm_transition_factor(value: float) -> void:
	_bgm_transition_factor = clampf(value, 0.0, 1.0)
	_apply_group_volume(BGM_PLAYER_GROUP, bgm_volume * _bgm_duck_factor * _bgm_transition_factor)
	var web_audio := get_node_or_null("/root/WebAudioFallback")
	if web_audio != null and web_audio.has_method("set_bgm_transition_factor"):
		web_audio.call("set_bgm_transition_factor", _bgm_transition_factor)


# todefaults初期化
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


# 文言間隔取得
func get_text_interval() -> float:
	return TEXT_INTERVALS[text_speed]


# master音量設定
func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


# BGM音量設定
func set_bgm_volume(value: float) -> void:
	bgm_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


# SE音量設定
func set_se_volume(value: float) -> void:
	se_volume = clampf(value, 0.0, 100.0)
	_apply_and_save()


# 文言speed設定
func set_text_speed(value: int) -> void:
	text_speed = clampi(value, 0, TEXT_INTERVALS.size() - 1)
	_apply_and_save()


# ウィンドウサイズ設定
func set_window_size(value: int) -> void:
	window_size = clampi(value, 0, WINDOW_SIZES.size() - 1)
	_apply_and_save()


# fullscreen設定
func set_fullscreen(value: bool) -> void:
	fullscreen = value
	_apply_and_save()


# 難度設定
func set_difficulty(value: int) -> void:
	difficulty = clampi(value, 0, 2)
	_apply_and_save()


# andsave適用
func _apply_and_save() -> void:
	save_settings()
	apply_settings()


# bus音量設定
func _set_bus_volume(bus_name: String, volume_percent: float) -> void:
	# bus番号
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	# linear音量
	var linear_volume := clampf(volume_percent / 100.0, 0.0, 1.0)
	AudioServer.set_bus_mute(bus_index, linear_volume <= 0.0)
	if linear_volume > 0.0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(linear_volume))


# カテゴリ別プレイヤー音量適用
func _apply_group_volume(group_name: StringName, volume_percent: float) -> void:
	for node in get_tree().get_nodes_in_group(group_name):
		if node is AudioStreamPlayer:
			_set_player_volume(node as AudioStreamPlayer, volume_percent)


func _set_player_volume(player: AudioStreamPlayer, volume_percent: float) -> void:
	player.volume_linear = clampf(volume_percent / 100.0, 0.0, 1.0)


func _on_node_added(node: Node) -> void:
	if not node is AudioStreamPlayer:
		return
	var player := node as AudioStreamPlayer
	if player.is_in_group(BGM_PLAYER_GROUP):
		_set_player_volume(player, bgm_volume * _bgm_duck_factor * _bgm_transition_factor)
	elif player.is_in_group(SE_PLAYER_GROUP):
		_set_player_volume(player, se_volume)


# ウィンドウ設定適用
func _apply_window_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(WINDOW_SIZES[window_size])
