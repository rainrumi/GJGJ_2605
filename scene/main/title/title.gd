extends Node2D

signal start_game
signal settings_requested
signal quit_requested


# 押下処理
func _on_start_button_pressed() -> void:
	start_game.emit()


# 押下処理
func _on_continue_button_pressed() -> void:
	start_game.emit()


# 押下処理
func _on_settings_button_pressed() -> void:
	settings_requested.emit()


# 押下処理
func _on_quit_button_pressed() -> void:
	quit_requested.emit()
