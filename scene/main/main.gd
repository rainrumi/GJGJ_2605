extends Node

const STAGE_CLEAR_RETURN_DELAY := 1.0
const STORY_CLEAR_DAY := 20
const INITIAL_STAGE_ID := 11
const HIGH_DIFFICULTY_DAY_INTERVAL := 4
const RECURRING_STAGE_NOVEL_STAGE_ID := 0
const RECURRING_STAGE_NOVEL_SCENARIO_INDEX := 1

enum NovelFlow {
	NONE,
	OPENING,
	END_GAMEOVER,
	GAME_CLEAR,
	STAGE_UNLOCK,
}

@export var end_gameover_novel_text: NovelTextResource
@export var game_clear_novel_text: NovelTextResource

@onready var title: Node = $Title
@onready var opening_novel: OpeningNovel = $OpeningNovel
@onready var day_intro: DayIntro = $DayIntro
@onready var stage_select: Node = $StageSelect
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var stage_clear: Node = $StageClear
@onready var bgm: BeatConductor = $BGM
@onready var settings_screen: SettingsScreen = $SettingsScreen

var run_state := RunState.new()
var should_reset_player_state := true
var active_novel_flow := NovelFlow.NONE
var pending_stage_novel_texts: Array[NovelTextResource] = []
var _settings_paused_tree := false
var _screen_flow_id := 0


func _ready() -> void:
	settings_screen.closed.connect(_on_settings_screen_closed)
	settings_screen.title_requested.connect(_on_settings_title_requested)
	if game.has_method("set_beat_conductor"):
		game.set_beat_conductor(bgm)
	if game.has_signal("dream_seed_depleted"):
		game.connect("dream_seed_depleted", Callable(self, "_on_game_dream_seed_depleted"))
	_play_bgm()
	show_title()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and key_event.pressed and not key_event.echo:
			get_viewport().set_input_as_handled()
			if settings_screen.visible:
				settings_screen.close()
			else:
				_open_settings_screen()


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
		stage_select.call("setup_stage_choices", run_state.selected_stage, run_state.current_day, _get_unlocked_high_difficulty_stage_ids(), run_state)


func show_game(reset_player_state: bool = true) -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = true
	game_ui.visible = true
	stage_clear.visible = false
	if game.has_method("start_battle"):
		game.start_battle(_create_battle_start_context(reset_player_state))


func show_stage_clear() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	if stage_clear.has_method("setup_clear_result") and game.has_method("get_current_hp") and game.has_method("get_clear_minutes"):
		stage_clear.setup_clear_result(game.get_current_hp(), game.get_clear_minutes(), run_state.selected_stage)
	elif stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	stage_clear.visible = true


func _on_title_start_game() -> void:
	_screen_flow_id += 1
	run_state.reset()
	_setup_initial_stage_position()
	should_reset_player_state = true
	if stage_clear.has_method("reset_player_state"):
		stage_clear.reset_player_state()
	_sync_run_state_from_stage_clear()
	title.visible = false
	active_novel_flow = NovelFlow.OPENING
	opening_novel.start()


func _on_settings_requested() -> void:
	_open_settings_screen()


func _on_quit_requested() -> void:
	get_tree().quit()


func _open_settings_screen() -> void:
	if settings_screen.visible:
		return
	_settings_paused_tree = not get_tree().paused
	get_tree().paused = true
	settings_screen.open()


func _on_settings_screen_closed() -> void:
	if _settings_paused_tree:
		get_tree().paused = false
	_settings_paused_tree = false


func _on_settings_title_requested() -> void:
	_return_to_title()


func _return_to_title() -> void:
	_screen_flow_id += 1
	active_novel_flow = NovelFlow.NONE
	pending_stage_novel_texts.clear()
	if game.has_method("cancel_battle"):
		game.cancel_battle()
	if settings_screen.visible:
		settings_screen.close()
	elif _settings_paused_tree:
		_on_settings_screen_closed()
	show_title()


func _on_opening_novel_finished() -> void:
	if title.visible and active_novel_flow == NovelFlow.NONE:
		return
	match active_novel_flow:
		NovelFlow.END_GAMEOVER:
			active_novel_flow = NovelFlow.NONE
			_finish_end_gameover_novel()
		NovelFlow.GAME_CLEAR:
			active_novel_flow = NovelFlow.NONE
			show_title()
		NovelFlow.STAGE_UNLOCK:
			if not _play_next_stage_unlock_novel():
				show_stage_select()
		_:
			active_novel_flow = NovelFlow.NONE
			show_day_intro()


func show_day_intro() -> void:
	var flow_id := _screen_flow_id
	title.visible = false
	opening_novel.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	await day_intro.show_day(run_state.current_day)
	if flow_id != _screen_flow_id:
		return
	if _try_show_stage_unlock_novels():
		return
	show_stage_select()


func _on_stage_select_stage_selected(stage: StageDefinition) -> void:
	if stage == null:
		return
	run_state.selected_stage_id = stage.stage_id
	run_state.selected_stage = stage
	show_game(should_reset_player_state)
	should_reset_player_state = false


func _on_game_battle_finished(won: bool) -> void:
	_sync_player_stomach_size()
	if won:
		run_state.record_stage_clear(run_state.selected_stage)
		show_stage_clear()
	else:
		show_end_gameover_novel()


func _on_game_dream_seed_depleted(source: Resource) -> void:
	if stage_clear.has_method("remove_planted_flower"):
		stage_clear.remove_planted_flower(source)
	_sync_run_state_from_stage_clear()


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
	_sync_run_state_from_stage_clear()
	_finish_current_day()


func _get_end_gameover_novel_text() -> NovelTextResource:
	var novel_text := NovelTextResource.new()
	novel_text.text = end_gameover_novel_text.text if end_gameover_novel_text != null else ""
	var recovery_percent := 0
	if game.has_method("get_last_time_over_recovery_percent"):
		recovery_percent = game.get_last_time_over_recovery_percent()
	novel_text.text += "\n（HPが%d%%回復した）" % recovery_percent
	return novel_text


func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	var flow_id := _screen_flow_id
	_sync_run_state_from_stage_clear()
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	if flow_id != _screen_flow_id:
		return
	_finish_current_day()


func _finish_current_day() -> void:
	run_state.current_day += 1
	if run_state.current_day > STORY_CLEAR_DAY:
		show_game_clear_novel()
		return
	show_day_intro()


func _setup_initial_stage_position() -> void:
	if not stage_select.has_method("get_stage_definition_by_id"):
		return
	var initial_stage := stage_select.call("get_stage_definition_by_id", INITIAL_STAGE_ID) as StageDefinition
	if initial_stage == null:
		return
	run_state.selected_stage_id = initial_stage.stage_id
	run_state.selected_stage = initial_stage


func show_game_clear_novel() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.GAME_CLEAR
	opening_novel.start_with_text(_get_game_clear_novel_text())


func _get_game_clear_novel_text() -> NovelTextResource:
	if game_clear_novel_text != null:
		return game_clear_novel_text
	var novel_text := NovelTextResource.new()
	novel_text.text = "ゲームクリア！7"
	return novel_text


func _try_show_stage_unlock_novels() -> bool:
	if not _is_high_difficulty_day(run_state.current_day):
		return false
	pending_stage_novel_texts = _collect_unplayed_stage_unlock_novels()
	if pending_stage_novel_texts.is_empty():
		return false
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.STAGE_UNLOCK
	return _play_next_stage_unlock_novel()


func _play_next_stage_unlock_novel() -> bool:
	if pending_stage_novel_texts.is_empty():
		active_novel_flow = NovelFlow.NONE
		return false
	var novel_text := pending_stage_novel_texts.pop_front() as NovelTextResource
	opening_novel.start_with_text(novel_text)
	return true


func _collect_unplayed_stage_unlock_novels() -> Array[NovelTextResource]:
	var novel_texts: Array[NovelTextResource] = []
	var unlocked_stage_novel_texts := _collect_unplayed_non_recurring_stage_unlock_novels()
	if not unlocked_stage_novel_texts.is_empty():
		return unlocked_stage_novel_texts
	var recurring_novel_text := _get_recurring_stage_unlock_novel_text()
	if recurring_novel_text != null:
		novel_texts.append(recurring_novel_text)
	return novel_texts


func _collect_unplayed_non_recurring_stage_unlock_novels() -> Array[NovelTextResource]:
	var novel_texts: Array[NovelTextResource] = []
	for stage in _get_stage_definitions_for_progress():
		if stage == null or stage.is_high_difficulty:
			continue
		if stage.stage_id == RECURRING_STAGE_NOVEL_STAGE_ID:
			continue
		for scenario_index in run_state.get_unplayed_unlocked_stage_novel_indices(stage):
			var novel_text := _load_stage_unlock_novel_text(stage.stage_id, scenario_index)
			if novel_text == null:
				continue
			novel_texts.append(novel_text)
			run_state.mark_stage_novel_played(stage, scenario_index)
	return novel_texts


func _get_recurring_stage_unlock_novel_text() -> NovelTextResource:
	var template := _load_stage_unlock_novel_text(RECURRING_STAGE_NOVEL_STAGE_ID, RECURRING_STAGE_NOVEL_SCENARIO_INDEX)
	if template == null:
		return null
	var novel_text := NovelTextResource.new()
	var high_difficulty_count := int(run_state.current_day / HIGH_DIFFICULTY_DAY_INTERVAL)
	novel_text.text = template.text % high_difficulty_count
	return novel_text


func _load_stage_unlock_novel_text(stage_id: int, scenario_index: int) -> NovelTextResource:
	if not stage_select.has_method("get_stage_definition_by_id"):
		return null
	var stage := stage_select.call("get_stage_definition_by_id", stage_id) as StageDefinition
	if stage == null:
		return null
	var novel_index := scenario_index - 1
	if novel_index < 0 or novel_index >= stage.stage_unlock_novel_texts.size():
		return null
	return stage.stage_unlock_novel_texts[novel_index]


func _get_stage_definitions_for_progress() -> Array[StageDefinition]:
	if stage_select.has_method("get_stage_definitions_for_progress"):
		var raw_definitions: Array = stage_select.call("get_stage_definitions_for_progress")
		var definitions: Array[StageDefinition] = []
		for stage in raw_definitions:
			if stage is StageDefinition:
				definitions.append(stage as StageDefinition)
		return definitions
	var definitions: Array[StageDefinition] = []
	return definitions


func _get_unlocked_high_difficulty_stage_ids() -> Array[int]:
	var stage_ids: Array[int] = []
	for stage in _get_stage_definitions_for_progress():
		if stage == null or stage.is_high_difficulty:
			continue
		if run_state.get_strengthened_enemy_unlock_count(stage) > 0:
			stage_ids.append(stage.stage_id)
	return stage_ids


func _is_high_difficulty_day(day: int) -> bool:
	return day > 0 and day % HIGH_DIFFICULTY_DAY_INTERVAL == 0


func _create_battle_start_context(reset_player_state: bool) -> BattleStartContext:
	var context := BattleStartContext.new()
	context.starting_hp = _get_starting_hp(reset_player_state)
	context.day = run_state.current_day
	context.stage_id = run_state.selected_stage_id
	context.stage = run_state.selected_stage
	context.enemy_preset = run_state.pick_enemy_preset(run_state.selected_stage)
	context.stomach_columns = run_state.stomach_columns
	context.stomach_rows = run_state.stomach_rows
	context.flowers = run_state.planted_flowers.duplicate()
	return context


func _sync_player_stomach_size() -> void:
	if game.has_method("get_stomach_columns"):
		run_state.stomach_columns = game.get_stomach_columns()
	if game.has_method("get_stomach_rows"):
		run_state.stomach_rows = game.get_stomach_rows()


func _sync_run_state_from_stage_clear() -> void:
	if stage_clear.has_method("get_current_hp"):
		run_state.current_hp = stage_clear.get_current_hp()
	if stage_clear.has_method("get_planted_flowers"):
		run_state.planted_flowers = stage_clear.get_planted_flowers()


func _get_starting_hp(reset_player_state: bool) -> int:
	if reset_player_state:
		if game.has_method("get_max_hp"):
			return game.get_max_hp()
		return 100
	return run_state.current_hp


func _get_planted_flowers() -> Array[FlowerDefinition]:
	var flowers: Array[FlowerDefinition] = []
	for flower in run_state.planted_flowers:
		if flower != null:
			flowers.append(flower)
	return flowers


func _play_bgm() -> void:
	if bgm.bgm_stream is AudioStreamMP3:
		var mp3_stream := bgm.bgm_stream as AudioStreamMP3
		mp3_stream.loop = true
	if bgm.audio_player != null and not bgm.audio_player.playing:
		bgm.play()
