class_name SettingsButton
extends Button

signal action_requested


# 初期設定
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


# 押下処理
func _on_pressed() -> void:
	action_requested.emit()
