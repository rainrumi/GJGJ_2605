extends Node

@onready var title: Node = $Title
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var bgm: AudioStreamPlayer = $BGM


func _ready() -> void:
	_play_bgm()
	show_title()


func show_title() -> void:
	title.visible = true
	game.visible = false
	game_ui.visible = false


func show_game() -> void:
	title.visible = false
	game.visible = true
	game_ui.visible = true
	if game.has_method("start_battle"):
		game.start_battle()


func _on_title_start_game() -> void:
	show_game()


func _play_bgm() -> void:
	if bgm.stream is AudioStreamMP3:
		var mp3_stream := bgm.stream as AudioStreamMP3
		mp3_stream.loop = true
	if not bgm.playing:
		bgm.play()
