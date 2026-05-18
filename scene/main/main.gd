extends Node

const STAGE_CLEAR_RETURN_DELAY := 1.0

enum NovelFlow {
	NONE,
	OPENING,
	END_GAMEOVER,
}

@export var end_gameover_novel_text: NovelTextResource

@onready var title: Node = $Title
@onready var opening_novel: OpeningNovel = $OpeningNovel
@onready var day_intro: DayIntro = $DayIntro
@onready var stage_select: Node = $StageSelect
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var stage_clear: Node = $StageClear
@onready var bgm: BeatConductor = $BGM

var current_day := 1
var selected_stage_id := 0
var should_reset_player_state := true
var active_novel_flow := NovelFlow.NONE


func _ready() -> void:
	if game.has_method("set_beat_conductor"):
		game.set_beat_conductor(bgm)
	_play_bgm()
	show_title()


func show_title() -> void:
	title.visible = true
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false


func show_stage_select() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = true
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	if stage_select.has_method("setup_stage_choices"):
		stage_select.call("setup_stage_choices")


func show_game(reset_player_state: bool = true) -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = true
	game_ui.visible = true
	stage_clear.visible = false
	if game.has_method("start_battle"):
		game.start_battle(_get_starting_hp(reset_player_state), current_day, _get_planted_flowers())


func show_stage_clear() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	if stage_clear.has_method("setup_clear_result") and game.has_method("get_current_hp") and game.has_method("get_clear_minutes"):
		stage_clear.setup_clear_result(game.get_current_hp(), game.get_clear_minutes())
	elif stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	stage_clear.visible = true


func _on_title_start_game() -> void:
	current_day = 1
	should_reset_player_state = true
	if stage_clear.has_method("reset_player_state"):
		stage_clear.reset_player_state()
	title.visible = false
	active_novel_flow = NovelFlow.OPENING
	opening_novel.start()


func _on_opening_novel_finished() -> void:
	match active_novel_flow:
		NovelFlow.END_GAMEOVER:
			active_novel_flow = NovelFlow.NONE
			_finish_end_gameover_novel()
		_:
			active_novel_flow = NovelFlow.NONE
			show_day_intro()


func show_day_intro() -> void:
	title.visible = false
	opening_novel.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	await day_intro.show_day(current_day)
	show_stage_select()


func _on_stage_select_stage_selected(stage_id: int) -> void:
	selected_stage_id = stage_id
	show_game(should_reset_player_state)
	should_reset_player_state = false


func _on_game_battle_finished(won: bool) -> void:
	if won:
		show_stage_clear()
	else:
		show_end_gameover_novel()


func show_end_gameover_novel() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.END_GAMEOVER
	opening_novel.start_with_text(_get_end_gameover_novel_text())


func _finish_end_gameover_novel() -> void:
	if stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	current_day += 1
	show_day_intro()


func _get_end_gameover_novel_text() -> NovelTextResource:
	var novel_text := NovelTextResource.new()
	novel_text.text = end_gameover_novel_text.text if end_gameover_novel_text != null else ""
	var recovery_percent := 0
	if game.has_method("get_last_time_over_recovery_percent"):
		recovery_percent = game.get_last_time_over_recovery_percent()
	novel_text.text += "\n（HPが%d%%回復した）" % recovery_percent
	return novel_text


func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	current_day += 1
	show_day_intro()


func _get_starting_hp(reset_player_state: bool) -> int:
	if reset_player_state:
		if game.has_method("get_max_hp"):
			return game.get_max_hp()
		return 100
	if stage_clear.has_method("get_current_hp"):
		return stage_clear.get_current_hp()
	return game.get_current_hp()


func _get_planted_flowers() -> Array[FlowerDefinition]:
	if stage_clear.has_method("get_planted_flowers"):
		return stage_clear.get_planted_flowers()
	var flowers: Array[FlowerDefinition] = []
	return flowers


func _play_bgm() -> void:
	if bgm.bgm_stream is AudioStreamMP3:
		var mp3_stream := bgm.bgm_stream as AudioStreamMP3
		mp3_stream.loop = true
	if bgm.audio_player != null and not bgm.audio_player.playing:
		bgm.play()
