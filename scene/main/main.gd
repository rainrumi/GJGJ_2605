extends Node

@onready var title: Node = $Title
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var stage_clear: Node = $StageClear
@onready var bgm: AudioStreamPlayer = $BGM


func _ready() -> void:
	_play_bgm()
	show_title()


func show_title() -> void:
	title.visible = true
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false


func show_game() -> void:
	title.visible = false
	game.visible = true
	game_ui.visible = true
	stage_clear.visible = false
	if game.has_method("start_battle"):
		game.start_battle()


func show_stage_clear() -> void:
	title.visible = false
	game.visible = false
	game_ui.visible = false
	if stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	stage_clear.visible = true


func _on_title_start_game() -> void:
	show_game()


func _on_game_battle_finished(won: bool) -> void:
	if won:
		show_stage_clear()
	else:
		show_title()


func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	show_game()


func _play_bgm() -> void:
	if bgm.stream is AudioStreamMP3:
		var mp3_stream := bgm.stream as AudioStreamMP3
		mp3_stream.loop = true
	if not bgm.playing:
		bgm.play()
