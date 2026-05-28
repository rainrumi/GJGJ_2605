extends Node2D

signal start_game

@onready var menu: Control = $Menu
@onready var settings_screen: SettingsScreen = $SettingsScreen


func _ready() -> void:
	settings_screen.closed.connect(_on_settings_screen_closed)


func _on_start_button_pressed() -> void:
	start_game.emit()


func _on_continue_button_pressed() -> void:
	start_game.emit()


func _on_settings_button_pressed() -> void:
	menu.visible = false
	settings_screen.open()


func _on_quit_button_pressed() -> void:
	pass


func _on_settings_screen_closed() -> void:
	menu.visible = true
