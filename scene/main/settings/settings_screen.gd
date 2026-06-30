class_name SettingsScreen
extends CanvasLayer

signal closed
signal title_requested

@onready var se_player: AudioStreamPlayer = $SePlayer
@onready var setting_rows: Array[Node] = [
	$Screen/Panel/Rows/MasterVolume,
	$Screen/Panel/Rows/BgmVolume,
	$Screen/Panel/Rows/SeVolume,
	$Screen/Panel/Rows/TextSpeed,
	$Screen/Panel/Rows/WindowSize,
	$Screen/Panel/Rows/Fullscreen,
	$Screen/Panel/Rows/Difficulty,
]


# 初期設定
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	se_player.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_refresh_values()


# 入力処理
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and key_event.pressed and not key_event.echo:
			get_viewport().set_input_as_handled()
			close()


# 表示処理
func open() -> void:
	_refresh_values()
	visible = true


# 非表示処理
func close() -> void:
	visible = false
	closed.emit()


# 値の反映
func _refresh_values() -> void:
	for row in setting_rows:
		if row.has_method("refresh_value"):
			row.refresh_value()


# 操作音再生
func _play_se() -> void:
	if se_player.stream == null:
		return
	se_player.stop()
	se_player.play()


# 初期化要求
func _on_reset_button_action_requested() -> void:
	GameSettings.reset_to_defaults()
	_refresh_values()
	_play_se()


# 戻る要求
func _on_back_button_action_requested() -> void:
	_play_se()
	close()


# タイトル要求
func _on_title_button_action_requested() -> void:
	_play_se()
	title_requested.emit()


# 変更通知
func _on_setting_feedback_requested() -> void:
	_play_se()
