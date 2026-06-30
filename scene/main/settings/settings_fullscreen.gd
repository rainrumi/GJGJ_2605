class_name SettingsFullscreen
extends HBoxContainer

signal feedback_requested

@onready var check_box: CheckBox = $Value

var _is_refreshing := false


# 初期設定
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	refresh_value()


# 値の反映
func refresh_value() -> void:
	_is_refreshing = true
	check_box.button_pressed = GameSettings.fullscreen
	_is_refreshing = false


# 切替処理
func _on_toggled(toggled_on: bool) -> void:
	if _is_refreshing:
		return
	GameSettings.set_fullscreen(toggled_on)
	feedback_requested.emit()
