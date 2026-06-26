class_name SettingsScreen
extends CanvasLayer

signal closed
signal title_requested

@onready var panel: Panel = $Screen/Panel
@onready var master_slider: HSlider = $Screen/Panel/Rows/MasterVolume/Value
@onready var master_value_label: Label = $Screen/Panel/Rows/MasterVolume/ValueLabel
@onready var bgm_slider: HSlider = $Screen/Panel/Rows/BgmVolume/Value
@onready var bgm_value_label: Label = $Screen/Panel/Rows/BgmVolume/ValueLabel
@onready var se_slider: HSlider = $Screen/Panel/Rows/SeVolume/Value
@onready var se_value_label: Label = $Screen/Panel/Rows/SeVolume/ValueLabel
@onready var text_speed_option: OptionButton = $Screen/Panel/Rows/TextSpeed/Value
@onready var window_size_option: OptionButton = $Screen/Panel/Rows/WindowSize/Value
@onready var fullscreen_check: CheckBox = $Screen/Panel/Rows/Fullscreen/Value
@onready var difficulty_option: OptionButton = $Screen/Panel/Rows/Difficulty/Value
@onready var se_player: AudioStreamPlayer = $SePlayer

var _is_refreshing := false


# 初期化
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	se_player.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_setup_options()
	_refresh_values()


# 未処理入力
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey:
		# keyイベント
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and key_event.pressed and not key_event.echo:
			get_viewport().set_input_as_handled()
			close()


# open処理
func open() -> void:
	_refresh_values()
	visible = true


# close処理
func close() -> void:
	visible = false
	closed.emit()


# setupoptions処理
func _setup_options() -> void:
	text_speed_option.clear()
	text_speed_option.add_item("ゆっくり")
	text_speed_option.add_item("ふつう")
	text_speed_option.add_item("はやい")
	text_speed_option.add_item("一瞬")
	window_size_option.clear()
	window_size_option.add_item("640 x 360")
	window_size_option.add_item("960 x 540")
	window_size_option.add_item("1280 x 720")
	window_size_option.add_item("1600 x 900")
	difficulty_option.clear()
	difficulty_option.add_item("やさしい")
	difficulty_option.add_item("ふつう")
	difficulty_option.add_item("むずかしい")


# values更新
func _refresh_values() -> void:
	_is_refreshing = true
	master_slider.value = GameSettings.master_volume
	bgm_slider.value = GameSettings.bgm_volume
	se_slider.value = GameSettings.se_volume
	text_speed_option.select(GameSettings.text_speed)
	window_size_option.select(GameSettings.window_size)
	fullscreen_check.button_pressed = GameSettings.fullscreen
	difficulty_option.select(GameSettings.difficulty)
	_update_volume_labels()
	_is_refreshing = false


# 音量labels更新
func _update_volume_labels() -> void:
	master_value_label.text = "%d%%" % roundi(master_slider.value)
	bgm_value_label.text = "%d%%" % roundi(bgm_slider.value)
	se_value_label.text = "%d%%" % roundi(se_slider.value)


# 変更処理
func _on_master_value_changed(value: float) -> void:
	if _is_refreshing:
		return
	GameSettings.set_master_volume(value)
	_update_volume_labels()


# 変更処理
func _on_bgm_value_changed(value: float) -> void:
	if _is_refreshing:
		return
	GameSettings.set_bgm_volume(value)
	_update_volume_labels()


# 変更処理
func _on_se_value_changed(value: float) -> void:
	if _is_refreshing:
		return
	GameSettings.set_se_volume(value)
	_update_volume_labels()
	_play_se()


# 選択処理
func _on_text_speed_item_selected(index: int) -> void:
	if _is_refreshing:
		return
	GameSettings.set_text_speed(index)
	_play_se()


# 選択処理
func _on_window_size_item_selected(index: int) -> void:
	if _is_refreshing:
		return
	GameSettings.set_window_size(index)
	_play_se()


# イベント処理
func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if _is_refreshing:
		return
	GameSettings.set_fullscreen(toggled_on)
	_play_se()


# 選択処理
func _on_difficulty_item_selected(index: int) -> void:
	if _is_refreshing:
		return
	GameSettings.set_difficulty(index)
	_play_se()


# 押下処理
func _on_reset_button_pressed() -> void:
	GameSettings.reset_to_defaults()
	_refresh_values()
	_play_se()


# 押下処理
func _on_back_button_pressed() -> void:
	_play_se()
	close()


# 押下処理
func _on_title_button_pressed() -> void:
	_play_se()
	title_requested.emit()


# SE再生
func _play_se() -> void:
	if se_player.stream == null:
		return
	se_player.stop()
	se_player.play()
