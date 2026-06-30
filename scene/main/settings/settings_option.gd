class_name SettingsOption
extends HBoxContainer

signal feedback_requested

@export_enum("text_speed", "window_size", "difficulty") var option_type := "text_speed"
@export var items: PackedStringArray = []

@onready var option_button: OptionButton = $Value

var _is_refreshing := false


# 初期設定
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_setup_items()
	refresh_value()


# 項目設定
func _setup_items() -> void:
	option_button.clear()
	for item in items:
		option_button.add_item(item)


# 値の反映
func refresh_value() -> void:
	_is_refreshing = true
	option_button.select(_get_index())
	_is_refreshing = false


# 値取得
func _get_index() -> int:
	match option_type:
		"window_size":
			return GameSettings.window_size
		"difficulty":
			return GameSettings.difficulty
		_:
			return GameSettings.text_speed


# 値保存
func _set_index(index: int) -> void:
	match option_type:
		"window_size":
			GameSettings.set_window_size(index)
		"difficulty":
			GameSettings.set_difficulty(index)
		_:
			GameSettings.set_text_speed(index)


# 選択処理
func _on_item_selected(index: int) -> void:
	if _is_refreshing:
		return
	_set_index(index)
	feedback_requested.emit()
