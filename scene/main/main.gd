extends Node

@onready var title: Node = $Title
@onready var game: Node = $Game


func _ready() -> void:
	show_title()


func show_title() -> void:
	title.visible = true
	game.visible = false


func show_game() -> void:
	title.visible = false
	game.visible = true


func _on_title_start_game() -> void:
	show_game()
