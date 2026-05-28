extends Node2D

signal start_game
signal settings_requested


func _on_start_button_pressed() -> void:
	start_game.emit()


func _on_continue_button_pressed() -> void:
	start_game.emit()


func _on_settings_button_pressed() -> void:
	settings_requested.emit()


func _on_quit_button_pressed() -> void:
	pass
