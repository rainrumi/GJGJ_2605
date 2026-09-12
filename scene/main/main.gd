extends Node

const STAGE_CLEAR_RETURN_DELAY := 1.0
const STORY_CLEAR_DAY := 20
const INITIAL_STAGE_ID := 11
const HIGH_DIFFICULTY_DAY_INTERVAL := 4
const FIRST_NIGHTMARE_EVENT_DAY := 4
const RECURRING_STAGE_NOVEL_STAGE_ID := 0
const RECURRING_STAGE_NOVEL_SCENARIO_INDEX := 1
const AREA_COMPLETION_BOSS_DEFEAT_COUNT := 3
const CLEAR_RECOVERY_START_HOUR := 22
const CLEAR_RECOVERY_END_HOUR := 27
const CLEAR_RECOVERY_BASE_RATE := 1.0
const CLEAR_RECOVERY_HOURLY_LOSS_RATE := 0.1
const CLEAR_RECOVERY_MINIMUM_RATE := 0.5

enum NovelFlow {
	NONE,
	OPENING,
	END_GAMEOVER,
	GAME_CLEAR,
	STAGE_UNLOCK,
	AREA_COMPLETION,
	FIRST_NIGHTMARE_EVENT,
	LARA_INTERACTION,
	LARA_INTERACTION_REWARD,
	LARA_JUDGE_SETUP,
	LARA_JUDGE_RESULT,
	LARA_JUDGE_REWARD,
	DEBUG_PREVIEW,
}

@export var end_gameover_novel_text: NovelTextInfo
@export var true_ending_novel_text: NovelTextInfo
@export var normal_ending_novel_text: NovelTextInfo
@export var bad_ending_novel_text: NovelTextInfo
@export var first_nightmare_event_novel_text: NovelTextInfo
@export var lara_location_catalog: StageCatalogInfo
@export var lara_schedule: LaraScheduleInfo

@onready var title: Node = $Title
@onready var opening_novel: OpeningNovel = $OpeningNovel
@onready var day_intro: DayIntro = $DayIntro
@onready var stage_select: Node = $StageSelect
@onready var game: Node = $Game
@onready var game_ui: CanvasLayer = $Game/UI
@onready var stage_clear: Node = $StageClear
@onready var bgm: BeatConductor = $BGM
@onready var se_click: AudioStreamPlayer = $SeClick
@onready var se_select: AudioStreamPlayer = $SeSelect
@onready var settings_screen: SettingsScreen = $SettingsScreen
@onready var _mouse_drag_state: MouseDragTracker = get_node("/root/MouseDragState")

var run_state := RunState.new()
var should_reset_player_state := true
var active_novel_flow := NovelFlow.NONE
var pending_stage_novel_texts: Array[NovelTextInfo] = []
var pending_area_completion_novel_text: NovelTextInfo
var _settings_paused_tree := false
var _screen_flow_id := 0
var _last_battle_progress_snapshot: Dictionary = {}
var _lara_first_interaction := false
var _lara_judge_pending := false
var _day_change_time_recovery_pending := false
var _lara_judge_result := 0


# 初期化
func _ready() -> void:
	assert(lara_schedule != null, "Main: lara_scheduleを設定してください")
	assert(lara_schedule.days.size() >= STORY_CLEAR_DAY, "Main: ラーラの予定は20日分必要です")
	assert(lara_schedule.validate().is_empty(), "Main: lara_scheduleの時刻・エリア・消化数が不正です")
	get_tree().node_added.connect(_on_node_added)
	_connect_ui_buttons(self)
	settings_screen.closed.connect(_on_settings_screen_closed)
	settings_screen.title_requested.connect(_on_settings_title_requested)
	# 戦闘finishedコール
	var battle_finished_callback := Callable(self, "_on_game_battle_finished")
	if game.has_signal("battle_finished") and not game.is_connected("battle_finished", battle_finished_callback):
		game.connect("battle_finished", battle_finished_callback)
	if game.has_signal("seed_depleted"):
		game.connect("seed_depleted", Callable(self, "_on_game_seed_depleted"))
	if game.has_signal("seed_inventory_changed"):
		game.connect("seed_inventory_changed", Callable(self, "_on_game_seed_inventory_changed"))
	_play_bgm()
	show_title()


func _connect_ui_buttons(node: Node) -> void:
	if node is BaseButton:
		_connect_ui_button(node as BaseButton)
	for child in node.get_children():
		_connect_ui_buttons(child)


func _connect_ui_button(button: BaseButton) -> void:
	var pressed_callback := _on_ui_button_pressed.bind(button)
	if not button.pressed.is_connected(pressed_callback):
		button.pressed.connect(pressed_callback)
	var mouse_entered_callback := _on_ui_button_mouse_entered.bind(button)
	if not button.mouse_entered.is_connected(mouse_entered_callback):
		button.mouse_entered.connect(mouse_entered_callback)


func _on_node_added(node: Node) -> void:
	if node is BaseButton and is_ancestor_of(node):
		_connect_ui_button(node as BaseButton)


func _on_ui_button_pressed(button: BaseButton) -> void:
	if settings_screen.is_ancestor_of(button):
		return
	if _mouse_drag_state.is_dragging():
		return
	_play_se_click()


func _on_ui_button_mouse_entered(button: BaseButton) -> void:
	if button.disabled:
		return
	_play_se_select()


func _play_se_click() -> void:
	if se_click.stream == null:
		return
	se_click.stop()
	se_click.play()


func _play_se_select() -> void:
	if se_select.stream == null:
		return
	se_select.stop()
	se_select.play()


# 未処理入力
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		# keyイベント
		var key_event := event as InputEventKey
		if key_event.keycode == KEY_ESCAPE and key_event.pressed and not key_event.echo:
			get_viewport().set_input_as_handled()
			if settings_screen.visible:
				settings_screen.close()
			else:
				_open_settings_screen()


# title表示
func show_title() -> void:
	title.visible = true
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false


# ステージselect表示
func show_stage_select() -> void:
	_sync_lara_progress()
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = true
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	if stage_select.has_method("setup_stage_choices"):
		stage_select.call(
			"setup_stage_choices",
			run_state.current_area_stage,
			run_state.current_day,
			_get_unlocked_high_difficulty_stage_ids(),
			run_state,
			run_state.current_minutes
		)


# ゲーム表示
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


# ステージclear表示
func show_stage_clear() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	_sync_seed_inventory_from_game()
	_sync_stage_clear_seed_inventory()
	if stage_clear.has_method("set_continuous_play_enabled"):
		stage_clear.set_continuous_play_enabled(
			run_state.is_continuous_play_unlocked and not _is_high_difficulty_day(run_state.current_day)
		)
	if stage_clear.has_method("setup_clear_result") and game.has_method("get_current_hp") and game.has_method("get_clear_minutes"):
		stage_clear.setup_clear_result(
			game.get_current_hp(),
			game.get_clear_minutes(),
			run_state.selected_stage,
			run_state.stomach_columns,
			run_state.stomach_rows
		)
	elif stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	stage_clear.visible = true


# イベント処理
func _on_title_start_game() -> void:
	_screen_flow_id += 1
	run_state.reset()
	_lara_judge_pending = false
	_day_change_time_recovery_pending = false
	pending_area_completion_novel_text = null
	_setup_initial_stage_position()
	should_reset_player_state = true
	if stage_clear.has_method("reset_player_state"):
		stage_clear.reset_player_state()
	_sync_run_state_from_stage_clear()
	title.visible = false
	active_novel_flow = NovelFlow.OPENING
	opening_novel.start()


# 要求処理
func _on_settings_requested() -> void:
	_open_settings_screen()


# 要求処理
func _on_quit_requested() -> void:
	get_tree().quit()


# デバッグノベル要求処理
func _on_title_debug_novel_requested(novel_text: NovelTextInfo) -> void:
	if not DebugState.debug_enabled or novel_text == null:
		return
	_screen_flow_id += 1
	title.visible = false
	active_novel_flow = NovelFlow.DEBUG_PREVIEW
	opening_novel.start_with_text(novel_text)


# open設定画面処理
func _open_settings_screen() -> void:
	if settings_screen.visible:
		return
	_settings_paused_tree = not get_tree().paused
	get_tree().paused = true
	settings_screen.open()


# イベント処理
func _on_settings_screen_closed() -> void:
	if _settings_paused_tree:
		get_tree().paused = false
	_settings_paused_tree = false


# 要求処理
func _on_settings_title_requested() -> void:
	_return_to_title()


# totitle返却
func _return_to_title() -> void:
	_screen_flow_id += 1
	active_novel_flow = NovelFlow.NONE
	_day_change_time_recovery_pending = false
	pending_stage_novel_texts.clear()
	if game.has_method("cancel_battle"):
		game.cancel_battle()
	if settings_screen.visible:
		settings_screen.close()
	elif _settings_paused_tree:
		_on_settings_screen_closed()
	show_title()


# 完了処理
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
				_start_selected_stage_with_lara()
		NovelFlow.LARA_INTERACTION:
			if _lara_first_interaction:
				active_novel_flow = NovelFlow.LARA_INTERACTION_REWARD
				var reward_text := NovelTextInfo.new()
				reward_text.text = _grant_lara_interaction_reward() + "\n@lcm"
				opening_novel.start_with_text(reward_text)
			else:
				_start_selected_battle()
		NovelFlow.LARA_INTERACTION_REWARD:
			_start_selected_battle()
		NovelFlow.LARA_JUDGE_SETUP:
			_show_lara_judge_result()
		NovelFlow.LARA_JUDGE_RESULT:
			var after_text := NovelTextInfo.new()
			after_text.script_path = "res://resource/novel/event/judge/novel_event_rara_judge_after"
			var reward_text := NovelTextInfo.new()
			reward_text.text = after_text.get_script_text() + "\n"
			if run_state.current_day >= STORY_CLEAR_DAY:
				reward_text.text += (
					"@name \"ラーラ\"\n"
					+ "……今日が最後ね。あとは合格を祈りましょう……。\n@lcm"
				)
			else:
				var next_judge_text := (
					"次は%d日目が終わったときよ！"
					% (run_state.current_day + HIGH_DIFFICULTY_DAY_INTERVAL)
				)
				reward_text.text += (
					_grant_lara_judge_reward()
					+ "\n@lcm\n@name \"ラーラ\"\n%s\n@lcm" % next_judge_text
				)
			active_novel_flow = NovelFlow.LARA_JUDGE_REWARD
			opening_novel.start_with_text(reward_text)
		NovelFlow.LARA_JUDGE_REWARD:
			active_novel_flow = NovelFlow.NONE
			_finish_current_day()
		NovelFlow.AREA_COMPLETION:
			active_novel_flow = NovelFlow.NONE
			pending_area_completion_novel_text = null
			_finish_current_day()
		NovelFlow.FIRST_NIGHTMARE_EVENT:
			active_novel_flow = NovelFlow.NONE
			run_state.unlock_lara()
			run_state.unlock_continuous_play()
			_finish_current_day()
		NovelFlow.DEBUG_PREVIEW:
			active_novel_flow = NovelFlow.NONE
			show_title()
		_:
			active_novel_flow = NovelFlow.NONE
			show_day_intro()


# 日数intro表示
func show_day_intro() -> void:
	# flowID
	var flow_id := _screen_flow_id
	title.visible = false
	opening_novel.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	await day_intro.show_day(run_state.current_day, run_state.planted_flowers)
	if flow_id != _screen_flow_id:
		return
	show_stage_select()


# 選択処理
func _on_stage_select_stage_selected(stage: StageInfo) -> void:
	if stage == null:
		return
	run_state.select_stage(stage)
	run_state.mark_area_challenged_today()
	if _try_show_selected_stage_unlock_novels(stage):
		return
	_start_selected_stage_with_lara()


func _start_selected_battle() -> void:
	active_novel_flow = NovelFlow.NONE
	show_game(should_reset_player_state)
	should_reset_player_state = false


func _start_selected_stage_with_lara() -> void:
	var location := run_state.lara_current_location
	if not run_state.is_lara_unlocked or location == null \
		or run_state.selected_stage.stage_area != location.stage_area:
		_start_selected_battle()
		return
	_lara_first_interaction = run_state.lara_interaction_day != run_state.current_day
	var scenario := "false/novel_event_rara_false_001"
	if _lara_first_interaction:
		run_state.lara_interaction_day = run_state.current_day
		scenario = "common/novel_event_rara_common_%03d" % randi_range(1, 8)
		var area_names := {
			StageInfo.StageArea.COROTTA_STREET: "corotta",
			StageInfo.StageArea.ERAMIA_DISTRICT: "eramia",
			StageInfo.StageArea.FELIS_GARDEN_DISTRICT: "felis",
			StageInfo.StageArea.GONSAL_DISTRICT: "gonsal",
			StageInfo.StageArea.MIRUNE_STREET: "mirune",
			StageInfo.StageArea.NERIX_MAGIC_SCHOOL: "nerix",
			StageInfo.StageArea.ZAIKA_ADMIN_DISTRICT: "zaika",
		}
		var previous := run_state.previous_area_stage
		if previous != null and area_names.has(previous.stage_area) \
			and not run_state.played_lara_area_novels.has(previous.stage_area):
			scenario = "area/novel_event_rara_%s_001" % area_names[previous.stage_area]
			run_state.played_lara_area_novels[previous.stage_area] = true
	title.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.LARA_INTERACTION
	var novel_text := NovelTextInfo.new()
	novel_text.script_path = "res://resource/novel/event/" + scenario
	opening_novel.start_with_text(novel_text)


func _get_lara_reward_candidates(rarity: int = -1) -> Array[SeedInfo]:
	var owned := run_state.planted_flowers.duplicate()
	owned.append_array(run_state.stored_seeds)
	return LaraReward.get_seed_candidates(_get_stage_definitions_for_progress(), owned, rarity)


func _grant_lara_interaction_reward() -> String:
	var message: String
	if randi_range(1, 100) <= 33:
		var percent: int = [50, 80, 100].pick_random()
		LaraReward.recover_hp(run_state, percent)
		message = "HPが%d%%回復した。" % percent
	else:
		var candidates := _get_lara_reward_candidates()
		if candidates.is_empty():
			push_error("Main: ラーラの交流報酬候補がありません。StageInfo.drop_seed_poolを確認してください")
			return "獲得できる夢の種がありません。"
		message = LaraReward.grant_seed(run_state, candidates.pick_random())
	_sync_stage_clear_seed_inventory()
	stage_clear.setup_hp(run_state.current_hp)
	return message


# 完了処理
func _on_game_battle_finished(won: bool) -> void:
	_sync_player_stomach_size()
	run_state.current_minutes = game.get_clear_minutes()
	run_state.day_elapsed_minutes = game.day_elapsed_minutes
	_sync_lara_progress()
	_day_change_time_recovery_pending = won
	if won:
		_queue_area_completion_novel_if_needed(run_state.selected_stage)
		_last_battle_progress_snapshot = {
			"normal_enemy_preset_indices": run_state.normal_enemy_preset_indices.duplicate(),
			"strengthened_enemy_preset_indices": run_state.strengthened_enemy_preset_indices.duplicate(),
			"normal_enemy_defeat_counts": run_state.normal_enemy_defeat_counts.duplicate(),
			"strengthened_enemy_defeat_counts": run_state.strengthened_enemy_defeat_counts.duplicate(),
		}
		run_state.record_stage_clear(run_state.selected_stage)
		_lara_judge_pending = (
			run_state.selected_stage.is_high_difficulty
			and _is_high_difficulty_day(run_state.current_day)
			and run_state.current_day > FIRST_NIGHTMARE_EVENT_DAY
		)
		show_stage_clear()
	else:
		show_end_gameover_novel()


func _on_stage_clear_debug_retry_requested() -> void:
	if not DebugState.debug_enabled or not stage_clear.visible:
		return
	_restore_last_battle_progress()
	stage_clear.visible = false
	game.visible = true
	game_ui.visible = true
	if not bool(game.call("retry_last_battle")):
		game.visible = false
		game_ui.visible = false
		stage_clear.visible = true


func _restore_last_battle_progress() -> void:
	if _last_battle_progress_snapshot.is_empty():
		return
	run_state.normal_enemy_preset_indices = _last_battle_progress_snapshot["normal_enemy_preset_indices"].duplicate()
	run_state.strengthened_enemy_preset_indices = _last_battle_progress_snapshot["strengthened_enemy_preset_indices"].duplicate()
	run_state.normal_enemy_defeat_counts = _last_battle_progress_snapshot["normal_enemy_defeat_counts"].duplicate()
	run_state.strengthened_enemy_defeat_counts = _last_battle_progress_snapshot["strengthened_enemy_defeat_counts"].duplicate()
	_lara_judge_pending = false
	pending_area_completion_novel_text = null


# 枯渇処理
func _on_game_seed_depleted(source: Resource) -> void:
	if source != null:
		_sync_seed_inventory_from_game()
		_sync_stage_clear_seed_inventory()


# 戦闘種inventory変更
func _on_game_seed_inventory_changed(
	equipped_seeds: Array[SeedInfo],
	stored_seeds: Array[SeedInfo]
) -> void:
	run_state.planted_flowers = equipped_seeds.duplicate()
	run_state.stored_seeds = stored_seeds.duplicate()
	_sync_stage_clear_seed_inventory()


# endgameoverノベル表示
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


# endgameoverノベル終了
func _finish_end_gameover_novel() -> void:
	if stage_clear.has_method("setup_hp") and game.has_method("get_current_hp"):
		stage_clear.setup_hp(game.get_current_hp())
	_sync_run_state_from_stage_clear()
	run_state.current_minutes = game.get_clear_minutes()
	run_state.day_elapsed_minutes = game.day_elapsed_minutes
	_sync_lara_progress()
	_finish_current_day()


# endgameoverノベル文言取得
func _get_end_gameover_novel_text() -> NovelTextInfo:
	# ノベル文言
	var novel_text := NovelTextInfo.new()
	novel_text.text = end_gameover_novel_text.get_script_text() if end_gameover_novel_text != null else ""
	# 回復割合
	var recovery_percent := 0
	if game.has_method("get_last_time_over_recovery_percent"):
		recovery_percent = game.get_last_time_over_recovery_percent()
	if not novel_text.text.is_empty() and not novel_text.text.ends_with("\n"):
		novel_text.text += "\n"
	novel_text.text += "（HPが%d%%回復した）\n@lcm" % recovery_percent
	return novel_text


# 完了処理
func _on_stage_clear_selection_finished(_recovered_hp_rate: float) -> void:
	# flowID
	var flow_id := _screen_flow_id
	_sync_run_state_from_stage_clear()
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	if flow_id != _screen_flow_id:
		return
	_finish_current_day()

func _on_stage_clear_continuation_requested() -> void:
	var flow_id := _screen_flow_id
	_sync_run_state_from_stage_clear()
	await get_tree().create_timer(STAGE_CLEAR_RETURN_DELAY).timeout
	if flow_id != _screen_flow_id:
		return
	show_stage_select()


func _on_stage_select_today_rest_requested() -> void:
	var can_rest_on_first_day := run_state.current_day == 1 and run_state.current_hp < 100
	if not run_state.is_continuous_play_unlocked and not can_rest_on_first_day:
		return
	_day_change_time_recovery_pending = true
	_finish_current_day()


# 日数終了
func _finish_current_day() -> void:
	if pending_area_completion_novel_text != null:
		show_area_completion_novel()
		return
	if run_state.current_day == FIRST_NIGHTMARE_EVENT_DAY and not run_state.is_lara_unlocked:
		show_first_nightmare_event_novel()
		return
	if _lara_judge_pending and run_state.last_lara_judge_day != run_state.current_day:
		_show_lara_judge_setup()
		return
	_advance_to_next_day()


func _advance_to_next_day() -> void:
	_lara_judge_pending = false
	_apply_day_change_time_recovery()
	run_state.apply_day_finished_seed_effects()
	run_state.day_elapsed_minutes = 0
	run_state.current_day += 1
	run_state.current_minutes = RunState.BATTLE_START_MINUTES
	run_state.reset_daily_challenge_state()
	if run_state.current_day > STORY_CLEAR_DAY:
		run_state.lara_digestion_count = lara_schedule.get_total_digestion_count(STORY_CLEAR_DAY, 30 * 60)
		show_game_clear_novel()
		return
	_sync_lara_progress()
	show_day_intro()


func _apply_day_change_time_recovery() -> void:
	if not _day_change_time_recovery_pending:
		return
	_day_change_time_recovery_pending = false
	var recovery_rate := StageClearCalculatorRecovery.get_clear_time_recovery_rate(
		run_state.planted_flowers,
		run_state.current_minutes,
		CLEAR_RECOVERY_START_HOUR,
		CLEAR_RECOVERY_END_HOUR,
		CLEAR_RECOVERY_BASE_RATE,
		CLEAR_RECOVERY_HOURLY_LOSS_RATE,
		CLEAR_RECOVERY_MINIMUM_RATE
	)
	if recovery_rate <= 0.0:
		return
	run_state.current_hp = mini(
		run_state.max_hp,
		run_state.current_hp + ceili(float(run_state.max_hp) * recovery_rate)
	)


func _sync_lara_progress() -> void:
	run_state.update_lara_progress(lara_schedule, _get_lara_location_candidates())


func _show_lara_judge_setup() -> void:
	_sync_lara_progress()
	_lara_judge_pending = false
	run_state.last_lara_judge_day = run_state.current_day
	_lara_judge_result = signi(run_state.get_player_digestion_count() - run_state.lara_digestion_count)
	title.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.LARA_JUDGE_SETUP
	var text := NovelTextInfo.new()
	text.script_path = "res://resource/novel/event/judge/novel_event_rara_judge_setup_001"
	opening_novel.start_with_text(text)


func _show_lara_judge_result() -> void:
	var result_name := "draw"
	if _lara_judge_result > 0:
		result_name = "win"
	elif _lara_judge_result < 0:
		result_name = "lose"
	var text := NovelTextInfo.new()
	text.script_path = "res://resource/novel/event/judge/novel_event_rara_judge_%s_%03d" % [result_name, randi_range(1, 3)]
	active_novel_flow = NovelFlow.LARA_JUDGE_RESULT
	opening_novel.start_with_text(text)


func _grant_lara_judge_reward() -> String:
	var rarity := -1
	if _lara_judge_result > 0:
		rarity = SeedInfo.Rarity.RARE
	elif _lara_judge_result < 0:
		rarity = SeedInfo.Rarity.NORMAL
	var candidates := _get_lara_reward_candidates(rarity)
	assert(not candidates.is_empty(), "Main: ラーラ勝負の報酬候補がありません。出現プールを確認してください")
	var message := LaraReward.grant_seed(run_state, candidates.pick_random())
	if run_state.current_hp < run_state.max_hp:
		LaraReward.recover_hp(run_state, 100)
		message += "更にHPが全回復した。"
	_sync_stage_clear_seed_inventory()
	stage_clear.setup_hp(run_state.current_hp)
	return message


func _queue_area_completion_novel_if_needed(stage: StageInfo) -> void:
	if stage == null or not stage.is_high_difficulty or stage.completion_novel_text == null:
		return
	var progress_key := "%d:%d" % [stage.stage_id, stage.stage_area]
	var defeated_boss_count := int(run_state.strengthened_enemy_defeat_counts.get(progress_key, 0))
	if defeated_boss_count + 1 == AREA_COMPLETION_BOSS_DEFEAT_COUNT:
		pending_area_completion_novel_text = stage.completion_novel_text


func show_area_completion_novel() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.AREA_COMPLETION
	opening_novel.start_with_text(pending_area_completion_novel_text)


func _get_lara_location_candidates() -> Array[StageInfo]:
	if lara_location_catalog == null:
		var candidates: Array[StageInfo] = []
		return candidates
	return lara_location_catalog.stages


func show_first_nightmare_event_novel() -> void:
	title.visible = false
	opening_novel.visible = false
	day_intro.visible = false
	stage_select.visible = false
	game.visible = false
	game_ui.visible = false
	stage_clear.visible = false
	active_novel_flow = NovelFlow.FIRST_NIGHTMARE_EVENT
	opening_novel.start_with_text(first_nightmare_event_novel_text)


# setupinitialステージ位置処理
func _setup_initial_stage_position() -> void:
	if not stage_select.has_method("get_stage_definition_by_id"):
		return
	# initialステージ
	var initial_stage := stage_select.call("get_stage_definition_by_id", INITIAL_STAGE_ID) as StageInfo
	if initial_stage == null:
		return
	run_state.select_stage(initial_stage)


# ゲームclearノベル表示
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


# ゲームclearノベル文言取得
func _get_game_clear_novel_text() -> NovelTextInfo:
	if run_state.get_lunova_boss_defeat_count() >= 3:
		return true_ending_novel_text
	if run_state.get_player_digestion_count() >= 25:
		return normal_ending_novel_text
	return bad_ending_novel_text


# 選択ステージ解放novels表示試行
func _try_show_selected_stage_unlock_novels(stage: StageInfo) -> bool:
	if stage == null or not stage.is_high_difficulty:
		return false
	pending_stage_novel_texts = _collect_unplayed_selected_stage_unlock_novels(stage)
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


# ステージ解放ノベル再生
func _play_next_stage_unlock_novel() -> bool:
	if pending_stage_novel_texts.is_empty():
		active_novel_flow = NovelFlow.NONE
		return false
	# ノベル文言
	var novel_text := pending_stage_novel_texts.pop_front() as NovelTextInfo
	opening_novel.start_with_text(novel_text)
	return true


# 選択ステージの未再生解放novels取得
func _collect_unplayed_selected_stage_unlock_novels(stage: StageInfo) -> Array[NovelTextInfo]:
	# ノベルtexts
	var novel_texts: Array[NovelTextInfo] = []
	if stage == null:
		return novel_texts
	if stage.stage_id == RECURRING_STAGE_NOVEL_STAGE_ID:
		var recurring_novel_text := _get_recurring_stage_unlock_novel_text()
		if recurring_novel_text != null:
			novel_texts.append(recurring_novel_text)
		return novel_texts
	# 通常難度の進行状態とノベル定義を参照する
	var source_stage := _get_normal_stage_definition_by_id(stage.stage_id)
	if source_stage == null:
		return novel_texts
	# 次に挑むボスと同じ番号のノベルだけを再生する
	var progress_key := "%d:%d" % [source_stage.stage_id, source_stage.stage_area]
	var scenario_index := int(run_state.strengthened_enemy_defeat_counts.get(progress_key, 0)) + 1
	if scenario_index not in run_state.get_unplayed_unlocked_stage_novel_indices(source_stage):
		return novel_texts
	# ノベル文言
	var novel_text := _load_stage_unlock_novel_text(source_stage.stage_id, scenario_index)
	if novel_text == null:
		return novel_texts
	novel_texts.append(novel_text)
	run_state.mark_stage_novel_played(source_stage, scenario_index)
	return novel_texts


# 通常難度ステージ定義取得
func _get_normal_stage_definition_by_id(stage_id: int) -> StageInfo:
	for stage in _get_stage_definitions_for_progress():
		if stage != null and not stage.is_high_difficulty and stage.stage_id == stage_id:
			return stage
	return null


# recurringステージ解放ノベル取得
func _get_recurring_stage_unlock_novel_text() -> NovelTextInfo:
	# template
	var template := _load_stage_unlock_novel_text(RECURRING_STAGE_NOVEL_STAGE_ID, RECURRING_STAGE_NOVEL_SCENARIO_INDEX)
	if template == null:
		return null
	# ノベル文言
	var novel_text := NovelTextInfo.new()
	# high難度数
	var high_difficulty_count := int(run_state.current_day / HIGH_DIFFICULTY_DAY_INTERVAL)
	novel_text.text = template.get_script_text() % high_difficulty_count
	return novel_text


# ステージ解放ノベル文言読込
func _load_stage_unlock_novel_text(stage_id: int, scenario_index: int) -> NovelTextInfo:
	if not stage_select.has_method("get_stage_definition_by_id"):
		return null
	# ステージ
	var stage := stage_select.call("get_stage_definition_by_id", stage_id) as StageInfo
	if stage == null:
		return null
	# ノベル番号
	var novel_index := scenario_index - 1
	if novel_index < 0 or novel_index >= stage.stage_unlock_novel_texts.size():
		return null
	return stage.stage_unlock_novel_texts[novel_index]


# ステージ定義forprogress取得
func _get_stage_definitions_for_progress() -> Array[StageInfo]:
	if stage_select.has_method("get_stage_definitions_for_progress"):
		# raw定義
		var raw_definitions: Array = stage_select.call("get_stage_definitions_for_progress")
		# 定義
		var definitions: Array[StageInfo] = []
		for stage in raw_definitions:
			if stage is StageInfo:
				definitions.append(stage as StageInfo)
		return definitions
	# 定義
	var definitions: Array[StageInfo] = []
	return definitions


# ステージids取得
func _get_unlocked_high_difficulty_stage_ids() -> Array[int]:
	# ステージids
	var stage_ids: Array[int] = []
	for stage in _get_stage_definitions_for_progress():
		if stage == null or stage.is_high_difficulty:
			continue
		if run_state.has_pending_strengthened_enemy(stage):
			stage_ids.append(stage.stage_id)
	return stage_ids


# high難度日数判定
func _is_high_difficulty_day(day: int) -> bool:
	return day > 0 and day % HIGH_DIFFICULTY_DAY_INTERVAL == 0


# 戦闘start文脈作成
func _create_battle_start_context(reset_player_state: bool) -> BattleInfo:
	# 文脈
	var context := BattleInfo.new()
	context.starting_hp = _get_starting_hp(reset_player_state)
	context.starting_minutes = run_state.current_minutes
	context.day = run_state.current_day
	context.stage_id = run_state.selected_stage_id
	context.stage = run_state.selected_stage
	context.enemy_preset = run_state.pick_enemy_preset(run_state.selected_stage)
	context.stomach_columns = run_state.stomach_columns
	context.stomach_rows = run_state.stomach_rows
	context.flowers = run_state.planted_flowers.duplicate()
	context.stored_seeds = run_state.stored_seeds.duplicate()
	context.permanent_acid_damage_bonus_rate = run_state.permanent_acid_damage_bonus_rate
	context.day_seed_acid_bonus = run_state.day_seed_acid_bonus
	context.day_elapsed_minutes = run_state.day_elapsed_minutes
	context.day_start_minutes = run_state.day_start_minutes
	return context


# player胃袋サイズ同期
func _sync_player_stomach_size() -> void:
	if game.has_method("get_base_stomach_columns"):
		run_state.stomach_columns = game.get_base_stomach_columns()
	if game.has_method("get_base_stomach_rows"):
		run_state.stomach_rows = game.get_base_stomach_rows()


# ステージclear同期
func _sync_run_state_from_stage_clear() -> void:
	if stage_clear.has_method("get_current_hp"):
		run_state.current_hp = stage_clear.get_current_hp()
	if stage_clear.has_method("get_clear_minutes"):
		run_state.current_minutes = stage_clear.get_clear_minutes()
	if stage_clear.has_method("get_equipped_seed_slots"):
		run_state.planted_flowers = stage_clear.get_equipped_seed_slots()
	elif stage_clear.has_method("get_planted_flowers"):
		run_state.planted_flowers = stage_clear.get_planted_flowers()
	if stage_clear.has_method("get_stored_seed_slots"):
		run_state.stored_seeds = stage_clear.get_stored_seed_slots()
	elif stage_clear.has_method("get_stored_seeds"):
		run_state.stored_seeds = stage_clear.get_stored_seeds()
	if stage_clear.has_method("get_permanent_acid_damage_bonus_rate"):
		run_state.permanent_acid_damage_bonus_rate = stage_clear.get_permanent_acid_damage_bonus_rate()
	_sync_lara_progress()


# startingHP取得
func _get_starting_hp(reset_player_state: bool) -> int:
	if reset_player_state:
		if game.has_method("get_max_hp"):
			return game.get_max_hp()
		return 100
	return run_state.current_hp


# planted花取得
func _get_planted_flowers() -> Array[SeedInfo]:
	# 花値
	var flowers: Array[SeedInfo] = []
	for flower in run_state.planted_flowers:
		if flower != null:
			flowers.append(flower)
	return flowers


# 戦闘から種inventory同期
func _sync_seed_inventory_from_game() -> void:
	if game.has_method("get_equipped_seeds"):
		run_state.planted_flowers = game.get_equipped_seeds()
	if game.has_method("get_stored_seeds"):
		run_state.stored_seeds = game.get_stored_seeds()


# stageclearへ種inventory同期
func _sync_stage_clear_seed_inventory() -> void:
	if stage_clear.has_method("set_seed_inventory"):
		stage_clear.set_seed_inventory(run_state.planted_flowers, run_state.stored_seeds)


# BGM再生
func _play_bgm() -> void:
	if bgm.bgm_stream is AudioStreamMP3:
		# mp3stream
		var mp3_stream := bgm.bgm_stream as AudioStreamMP3
		mp3_stream.loop = true
	if bgm.audio_player != null and not bgm.audio_player.playing:
		bgm.play()
