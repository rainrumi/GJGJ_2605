extends Node

const STAGE_CLEAR_RETURN_DELAY := 1.0

@onready var title: Node = $Title
@onready var opening_novel: CanvasLayer = $OpeningNovel
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var stage_clear: Node = $StageClear
@onready var bgm: AudioStreamPlayer = $BGM

var current_day := 1


func _ready() -> void:
	_play_bgm()
	show_title()


func show_title() -> void:
	title.visible = true
	opening_novel.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false


func show_game(reset_player_state: bool = true) -> void:
	title.visible = false
	opening_novel.visible = false
	game.visible = true
	game_ui.visible = true
	stage_clear.visible = false
	if game.has_method("start_battle"):
		game.start_battle(_get_starting_hp(reset_player_state), current_day)


func show_stage_clear() -> void:
	title.visible = false
	opening_novel.visible = false
	game.visible = false
	game_ui.visible = false
	if stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	stage_clear.visible = true


func _on_title_start_game() -> void:
	current_day = 1
	if stage_clear.has_method("reset_player_state"):
		stage_clear.reset_player_state()
	title.visible = false
	opening_novel.start()


func _on_opening_novel_finished() -> void:
	show_game()


func _on_game_battle_finished(won: bool) -> void:
	if won:
		show_stage_clear()
	else:
		show_title()


func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	current_day += 1
	show_game(false)


func _get_starting_hp(reset_player_state: bool) -> int:
	if reset_player_state:
		if game.has_method("get_max_hp"):
			return game.get_max_hp()
		return 100
	if stage_clear.has_method("get_current_hp"):
		return stage_clear.get_current_hp()
	return game.get_current_hp()


func _play_bgm() -> void:
	if bgm.stream is AudioStreamMP3:
		var mp3_stream := bgm.stream as AudioStreamMP3
		mp3_stream.loop = true
	if not bgm.playing:
		bgm.play()
