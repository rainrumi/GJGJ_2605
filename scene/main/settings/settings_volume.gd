class_name SettingsVolume
extends HBoxContainer

signal feedback_requested

@export_enum("master", "bgm", "se") var volume_type := "master"

@onready var slider: HSlider = $Value
@onready var value_label: Label = $ValueLabel

var _is_refreshing := false


# 初期設定
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	refresh_value()


# 値の反映
func refresh_value() -> void:
	_is_refreshing = true
	slider.value = _get_volume()
	_update_label()
	_is_refreshing = false


# 表示更新
func _update_label() -> void:
	value_label.text = "%d%%" % roundi(slider.value)


# 音量取得
func _get_volume() -> float:
	match volume_type:
		"bgm":
			return GameSettings.bgm_volume
		"se":
			return GameSettings.se_volume
		_:
			return GameSettings.master_volume


# 音量保存
func _set_volume(value: float) -> void:
	match volume_type:
		"bgm":
			GameSettings.set_bgm_volume(value)
		"se":
			GameSettings.set_se_volume(value)
			feedback_requested.emit()
		_:
			GameSettings.set_master_volume(value)


# 変更処理
func _on_value_changed(value: float) -> void:
	if _is_refreshing:
		return
	_set_volume(value)
	_update_label()
