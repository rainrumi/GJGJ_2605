extends Node2D
signal battle_finished(won: bool)
signal seed_depleted(source: Resource)
enum DragMode {
	NONE,
	ENEMY,
	seed,
}
const START_HOUR: int = 22
const END_HOUR: int = 30
const REST_MINUTES: int = 30
const MAX_HP: int = 100
const REST_HP_RATE: float = 0.1
const TIME_OVER_HP_RECOVERY_RATE: float = 0.7
const acid_AUTO_INTERVAL: float = 0.05
const REMOVE_FROM_STOMACH_DAMAGE_RATE: float = 0.05
const START_MESSAGE: String = "６時までにすべての悪夢を消化しましょう"
@export var enemy_definitions: Array[Resource] = []
@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var input_controller: GameInputController = $GameInputController
@onready var click_se: AudioStreamPlayer = $ClickSe
@onready var enemies: Array[Enemy] = [$EnemyLeft as Enemy, $EnemyCenter as Enemy, $EnemyRight as Enemy, $EnemyUpperRight as Enemy]
var minutes := START_HOUR * 60
var hp := MAX_HP
var current_stage_id := 0
var current_stage: StageInfo
var current_day := 1
var current_enemy_preset: NightmarePresetInfo
var battle_active := false
var auto_acid_enabled := false
var auto_acid_paused_for_drag := false
var acid_turn_in_progress := false
var drag_mode := DragMode.NONE
var debug_numbers_visible := false
var Acidion_timer: Timer
var enemy_setup := GameEnemySetupController.new()
var acid_controller := NightmareAcidController.new()
var seed_controller := GameDreamSeedController.new()
var acid_spawn_request_applier := AcidSpawnRequestApplier.new()
var beat_conductor: BeatConductor
var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_Aciding := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy
var last_time_over_recovery_percent := 0
var effective_max_hp := MAX_HP
# 初期化
func _ready() -> void:
	randomize()
	enemy_setup.setup(self, input_controller, stomach, enemy_definitions)
	seed_controller.setup(self, stomach, input_controller)
	_connect_ui()
	_connect_input()
	_create_Acidion_timer()
	ui.hide_enemy_tooltip()
# 拍conductor設定
func set_beat_conductor(conductor: BeatConductor) -> void:
	beat_conductor = conductor
# 戦闘開始
func start_battle(context: BattleStartContext = null) -> void:
	# 戦闘文脈
	var battle_context := context if context != null else BattleStartContext.new()
	minutes = START_HOUR * 60
	effective_max_hp = MAX_HP
	hp = clampi(battle_context.starting_hp, 0, effective_max_hp)
	current_day = battle_context.day
	current_stage_id = battle_context.stage_id
	current_stage = battle_context.stage
	current_enemy_preset = battle_context.enemy_preset
	stomach.set_grid_size(battle_context.stomach_columns, battle_context.stomach_rows)
	last_time_over_recovery_percent = 0
	debug_numbers_visible = DebugState.debug_enabled
	_set_battle_flags(false)
	_clear_scheduled_acid_events()
	seed_controller.set_flowers(battle_context.flowers)
	_apply_seed_stomach_size_effects()
	acid_controller.setup(seed_controller.get_flowers())
	acid_controller.set_day(current_day)
	_refresh_effective_max_hp(false)
	dragging_enemy = null
	seed_controller.cancel_drag()
	drag_mode = DragMode.NONE
	hovered_enemy = null
	enemy_setup.setup(
		self,
		input_controller,
		stomach,
		_get_battle_enemy_definitions(),
		_get_battle_enemy_preset()
	)
	enemy_setup.setup_enemies(enemies)
	ui.reset_for_battle(
		MAX_HP,
		minutes,
		START_MESSAGE,
		REST_MINUTES,
		REST_HP_RATE,
		acid_controller.get_rest_recovery_bonus_rate()
	)
	ui.set_seed_sources(seed_controller.get_flowers())
	ui.set_seed_debug_numbers_visible(debug_numbers_visible)
	stomach.hide_preview()
	battle_active = true
	input_controller.set_active(true)
	_refresh_ui()
# HP取得
func get_current_hp() -> int:
	return hp
# clear分数取得
func get_clear_minutes() -> int:
	return minutes
# 最大HP取得
func get_max_hp() -> int:
	return effective_max_hp
# 時間over回復割合取得
func get_last_time_over_recovery_percent() -> int:
	return last_time_over_recovery_percent


# 戦闘取消
func cancel_battle() -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_acid_enabled = false
	auto_acid_paused_for_drag = false
	acid_turn_in_progress = false
	_clear_scheduled_acid_events()
	_update_auto_acid_timer()


# 胃袋列取得
func get_stomach_columns() -> int:
	return stomach.columns


# 胃袋行取得
func get_stomach_rows() -> int:
	return stomach.rows


# UI接続
func _connect_ui() -> void:
	ui.Acidion_requested.connect(_on_Acidion_requested)
	ui.debug_message_requested.connect(_on_debug_message_requested)
	ui.debug_reroll_requested.connect(_on_debug_reroll_requested)
	ui.debug_stomach_size_requested.connect(_on_debug_stomach_size_requested)
	ui.debug_seed_requested.connect(_on_debug_seed_requested)
	ui.seed_drag_started.connect(_on_seed_drag_started)
	ui.seed_drag_moved.connect(_on_seed_drag_moved)
	ui.seed_drag_released.connect(_on_seed_drag_released)
# 入力接続
func _connect_input() -> void:
	input_controller.setup(enemies)
	input_controller.enemy_drag_started.connect(_on_enemy_drag_started)
	input_controller.enemy_drag_moved.connect(_on_enemy_drag_moved)
	input_controller.enemy_drag_released.connect(_on_enemy_drag_released)
	input_controller.enemy_hover_requested.connect(_set_hovered_enemy)
# 戦闘flags設定
func _set_battle_flags(is_active: bool) -> void:
	battle_active = is_active
	input_controller.set_active(is_active)
	auto_acid_enabled = false
	auto_acid_paused_for_drag = false
	acid_turn_in_progress = false
	drag_mode = DragMode.NONE
	seed_controller.cancel_drag()
	if Acidion_timer != null and not Acidion_timer.is_stopped():
		Acidion_timer.stop()
# 消化timer作成
func _create_Acidion_timer() -> void:
	Acidion_timer = Timer.new()
	Acidion_timer.name = "AutoAcidionTimer"
	Acidion_timer.wait_time = acid_AUTO_INTERVAL
	Acidion_timer.one_shot = false
	Acidion_timer.timeout.connect(_on_Acidion_timer_timeout)
	add_child(Acidion_timer)
# 開始処理
func _on_enemy_drag_started(enemy: Enemy, _mouse_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i) -> void:
	if not _can_start_enemy_drag():
		input_controller.clear_drag()
		return
	drag_mode = DragMode.ENEMY
	dragging_enemy = enemy
	drag_offset = pointer_offset
	drag_grab_cell = grab_cell
	dragged_enemy_was_Aciding = enemy.is_Aciding()
	dragged_enemy_original_cell = enemy.stomach_cell
	dragged_enemy_original_global_position = enemy.global_position
	auto_acid_paused_for_drag = auto_acid_enabled
	_update_auto_acid_timer()
	_play_click_se()
# 移動処理
func _on_enemy_drag_moved(enemy: Enemy, mouse_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i) -> void:
	if not battle_active or drag_mode != DragMode.ENEMY or enemy != dragging_enemy:
		return
	dragging_enemy.global_position = mouse_position + pointer_offset
	stomach.show_preview(dragging_enemy, mouse_position, grab_cell, enemies)
	_update_hp_damage_preview(mouse_position)
	_set_hovered_enemy(null)
# 離上処理
func _on_enemy_drag_released(enemy: Enemy, mouse_position: Vector2) -> void:
	if not battle_active or drag_mode != DragMode.ENEMY or dragging_enemy == null or enemy != dragging_enemy:
		return
	_finish_enemy_drag_release(enemy, mouse_position)
	_finish_drag_operation()


# 敵ドラッグrelease終了
func _finish_enemy_drag_release(enemy: Enemy, mouse_position: Vector2) -> void:
	dragging_enemy = null
	_play_click_se()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	if stomach.contains_global_position(mouse_position):
		_try_start_Aciding(enemy, mouse_position)
	else:
		if acid_controller.is_remove_from_stomach_disabled():
			_return_dragged_enemy(enemy)
			_refresh_after_battle_event()
			return
		_remove_enemy_from_stomach(enemy)


# 要求処理
func _on_Acidion_requested() -> void:
	if not battle_active:
		return
	if _active_acid_count() == 0:
		_advance_acid_turn()
		return
	auto_acid_enabled = true
	auto_acid_paused_for_drag = false
	if not stomach.has_bottom_touching_enemy(enemies):
		stomach.apply_gravity(enemies)
	_refresh_ui()
	_advance_acid_turn()
# イベント処理
func _on_Acidion_timer_timeout() -> void:
	if not auto_acid_enabled or auto_acid_paused_for_drag:
		_update_auto_acid_timer()
		return
	_advance_acid_turn()
# 要求処理
func _on_debug_message_requested(is_active: bool) -> void:
	debug_numbers_visible = is_active
	ui.set_seed_debug_numbers_visible(debug_numbers_visible)
	if hovered_enemy != null:
		ui.show_enemy_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
# 要求処理
func _on_debug_reroll_requested() -> void:
	if not _can_use_debug_action():
		return
	_prepare_debug_battle_change()
	acid_controller.reset_acid_order()
	enemy_setup.setup_enemies(enemies)
	input_controller.setup(enemies)
	_refresh_ui()


# 要求処理
func _on_debug_stomach_size_requested(delta_columns: int, delta_rows: int) -> void:
	if not _can_use_debug_action():
		return
	_prepare_debug_battle_change()
	stomach.set_grid_size(stomach.columns + delta_columns, stomach.rows + delta_rows)
	_refresh_enemy_stomach_display_sizes()
	_refresh_ui()


# 要求処理
func _on_debug_seed_requested() -> void:
	if not _can_use_debug_action():
		return
	if not seed_controller.add_random_debug_seed():
		return
	_sync_seed_sources()
	_refresh_ui()


# 開始処理
func _on_seed_drag_started(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	if not _can_start_seed_drag():
		return
	# 結果
	var result := seed_controller.start_drag(button, seed, mouse_position)
	if not result.started:
		return
	drag_mode = DragMode.seed
	auto_acid_paused_for_drag = auto_acid_enabled
	_update_auto_acid_timer()
	_play_click_se()


# 移動処理
func _on_seed_drag_moved(
	_button: SeedButton,
	_seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	if not battle_active or drag_mode != DragMode.seed:
		return
	seed_controller.move_drag(mouse_position, enemies)
	_set_hovered_enemy(null)


# 離上処理
func _on_seed_drag_released(
	_button: SeedButton,
	_seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	if drag_mode != DragMode.seed:
		return
	# 結果
	var result := seed_controller.release_drag(mouse_position, enemies)
	_handle_seed_drag_result(result)
	_finish_drag_operation()


# handle種ドラッグ結果処理
func _handle_seed_drag_result(result: DreamSeedDragResult) -> void:
	if result.started:
		_play_click_se()
	if result.placed:
		_apply_placed_seed_drag_result(result)


# placed種ドラッグ結果適用
func _apply_placed_seed_drag_result(result: DreamSeedDragResult) -> void:
	_refresh_after_battle_event()
	if result.source_button == null or not is_instance_valid(result.source_button):
		return
	result.source_button.consume_sub_skill_use()
	seed_controller.remove_source_while_in_stomach(result.source_button, result.seed_block)
	_sync_seed_sources()


# ドラッグoperation終了
func _finish_drag_operation() -> void:
	if auto_acid_enabled:
		auto_acid_paused_for_drag = false
	drag_mode = DragMode.NONE
	_update_auto_acid_timer()


# 夢種sources同期
func _sync_seed_sources() -> void:
	# 花値
	var flowers := seed_controller.get_flowers()
	acid_controller.set_seed_effect_flowers(flowers)
	ui.set_seed_sources(flowers)


# start敵ドラッグ判定
func _can_start_enemy_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not acid_turn_in_progress


# start種ドラッグ判定
func _can_start_seed_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not acid_turn_in_progress


# useデバッグaction判定
func _can_use_debug_action() -> bool:
	return battle_active and debug_numbers_visible and drag_mode == DragMode.NONE and not acid_turn_in_progress


# デバッグ戦闘change準備
func _prepare_debug_battle_change() -> void:
	auto_acid_enabled = false
	auto_acid_paused_for_drag = false
	_update_auto_acid_timer()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	_set_hovered_enemy(null)


# 敵胃袋displaysizes更新
func _refresh_enemy_stomach_display_sizes() -> void:
	for enemy in enemies:
		if enemy.definition == null or enemy.is_Acided():
			continue
		enemy.update_stomach_display_size(Vector2(
			stomach.get_span_size(enemy.get_stomach_size().x),
			stomach.get_span_size(enemy.get_stomach_size().y)
		))
		if enemy.is_active_in_stomach():
			stomach.place_enemy(enemy, enemy.stomach_cell)


# 戦闘敵定義取得
func _get_battle_enemy_definitions() -> Array[Resource]:
	return enemy_definitions


# 戦闘敵編成取得
func _get_battle_enemy_preset() -> NightmarePresetInfo:
	return current_enemy_preset


# setup敵編成処理
func _setup_enemy_preset(enemy_preset: NightmarePresetInfo) -> void:
	enemy_setup.setup(
		self,
		input_controller,
		stomach,
		_get_battle_enemy_definitions(),
		enemy_preset
	)
	enemy_setup.setup_enemies(enemies)
	input_controller.setup(enemies)
	_refresh_ui()


# startAciding試行
func _try_start_Aciding(enemy: Enemy, mouse_position: Vector2) -> void:
	# fullness
	var next_fullness := stomach.get_current_fullness(enemies)
	if not dragged_enemy_was_Aciding:
		next_fullness += enemy.get_size()
	if next_fullness > stomach.get_capacity():
		_return_dragged_enemy(enemy)
		_refresh_after_battle_event()
		return
	# topleft
	var top_left := stomach.get_drop_cell(enemy, mouse_position, drag_grab_cell, enemies)
	if not stomach.can_place(enemy, top_left, enemies):
		_return_dragged_enemy(enemy)
		_refresh_after_battle_event()
		return
	enemy.set_Aciding(true)
	stomach.place_enemy(enemy, top_left)
	_refresh_after_battle_event()
# dragged敵返却
func _return_dragged_enemy(enemy: Enemy) -> void:
	if dragged_enemy_was_Aciding:
		enemy.set_Aciding(true)
		enemy.set_stomach_cell(dragged_enemy_original_cell)
		enemy.global_position = dragged_enemy_original_global_position
		return
	enemy.return_to_origin()
# 敵from胃袋削除
func _remove_enemy_from_stomach(enemy: Enemy) -> void:
	if not dragged_enemy_was_Aciding:
		enemy.return_to_origin()
		return
	enemy.set_Aciding(false)
	enemy.return_to_origin()
	_apply_remove_from_stomach_acid_damage(enemy)
	# ダメージ
	var damage := _get_remove_from_stomach_damage()
	# ダメージvalues
	var damage_values: Array[int] = [damage]
	if damage > 0:
		ui.show_hp_damage_values(damage_values)
		hp = maxi(0, hp - damage)
	_refresh_after_battle_event()
# advance消化turn処理
func _advance_acid_turn() -> void:
	if not _begin_acid_turn():
		return
	_apply_time_seed_hp_recovery()
	acid_controller.apply_turn_start_effects(enemies, stomach, minutes)
	# elapsed分数
	var elapsed_minutes := acid_controller.get_step_minutes(enemies, minutes)
	await _wait_for_next_acid_beat()
	# 消化結果
	var acid_result := _run_acid_core(minutes, elapsed_minutes)
	_apply_acid_damage_seed_heal()
	_apply_Acided_nightmare_seed_effects(acid_result.Acided_enemies)
	_apply_Acided_seed_effects(acid_result.Acided_enemies)
	_apply_player_damage_values()
	_apply_elapsed_time(elapsed_minutes + acid_result.extra_elapsed_minutes)
	if acid_result.time_override_minutes >= 0:
		minutes = acid_result.time_override_minutes
		_refresh_after_battle_event()
	await _resolve_post_acid_visuals(acid_result.Acided_enemies)
	_finish_acid_turn()


# begin消化turn処理
func _begin_acid_turn() -> bool:
	if acid_turn_in_progress:
		return false
	acid_turn_in_progress = true
	if _active_acid_count() == 0:
		_finish_empty_acid_turn()
		return false
	return true


# run消化core処理
func _run_acid_core(current_minutes: int, elapsed_minutes: int) -> AcidTurnResult:
	# 消化済み敵
	var Acided_enemies: Array[Enemy] = acid_controller.acid_nightmares(enemies, stomach, current_minutes, elapsed_minutes)
	# 消化結果
	var acid_result := acid_controller.build_turn_result(Acided_enemies)
	_apply_acid_spawn_requests(acid_result.spawn_requests)
	return acid_result


# empty消化turn終了
func _finish_empty_acid_turn() -> void:
	auto_acid_enabled = false
	_refresh_after_battle_event()
	acid_turn_in_progress = false
# elapsed時間適用
func _apply_elapsed_time(elapsed_minutes: int) -> void:
	minutes += elapsed_minutes
	if hp <= 0:
		acid_controller.add_revive_event()
		_refresh_effective_max_hp(true)
		hp = acid_controller.get_rest_hp(effective_max_hp, REST_HP_RATE)
		if not seed_controller.consume_rest_time_skip():
			minutes += REST_MINUTES
			elapsed_minutes += REST_MINUTES
		_refresh_after_battle_event()
	else:
		_refresh_after_battle_event()
	ui.show_time_elapsed(elapsed_minutes)


# 消化turn終了
func _finish_acid_turn() -> void:
	_check_battle_end()
	_update_auto_acid_timer()
	acid_controller.activate_deferred_nuisance_enemies(enemies)
	acid_turn_in_progress = false


# depleted夢種sources発火
func _emit_depleted_seed_sources(Acided_enemies: Array[Enemy]) -> void:
	for source in seed_controller.collect_depleted_sources(Acided_enemies):
		seed_depleted.emit(source)


# check戦闘end処理
func _check_battle_end() -> void:
	if _all_nightmares_Acided():
		_finish_battle(true, "すべての悪夢を消化しました")
		return
	if minutes >= END_HOUR * 60:
		_apply_time_over_recovery()
		_finish_battle(false, "朝までに消化しきれませんでした")
# 戦闘終了
func _finish_battle(won: bool, _message: String) -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_acid_enabled = false
	_clear_scheduled_acid_events()
	_update_auto_acid_timer()
	_refresh_after_battle_event()
	battle_finished.emit(won)
# 時間over回復適用
func _apply_time_over_recovery() -> void:
	# HP
	var previous_hp := hp
	hp = mini(effective_max_hp, hp + ceili(float(effective_max_hp) * TIME_OVER_HP_RECOVERY_RATE))
	last_time_over_recovery_percent = roundi(float(hp - previous_hp) / float(effective_max_hp) * 100.0)
# auto消化timer更新
func _update_auto_acid_timer() -> void:
	# active消化数
	var active_acid_count := _active_acid_count()
	if auto_acid_enabled and active_acid_count == 0:
		auto_acid_enabled = false
		auto_acid_paused_for_drag = false
	if auto_acid_enabled and battle_active and not auto_acid_paused_for_drag and active_acid_count > 0:
		if Acidion_timer.is_stopped():
			Acidion_timer.start()
	else:
		if not Acidion_timer.is_stopped():
			Acidion_timer.stop()
	_refresh_ui()
# hovered敵設定
func _set_hovered_enemy(enemy: Enemy) -> void:
	if hovered_enemy == enemy:
		return
	if hovered_enemy != null:
		hovered_enemy.set_hovered(false)
	hovered_enemy = enemy
	if hovered_enemy != null:
		hovered_enemy.set_hovered(true)
		ui.show_enemy_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
	else:
		ui.hide_enemy_tooltip()
# HPダメージpreview更新
func _update_hp_damage_preview(mouse_position: Vector2) -> void:
	if (
		dragged_enemy_was_Aciding
		and not acid_controller.is_remove_from_stomach_disabled()
		and not stomach.contains_global_position(mouse_position)
	):
		ui.show_hp_damage_preview(_get_remove_from_stomach_damage())
	else:
		ui.hide_hp_damage_preview()
# UI更新
func _refresh_ui() -> void:
	acid_controller.refresh_enemy_status_display(enemies, stomach, minutes)
	_refresh_acid_ui()
	_refresh_status_ui()
	_refresh_hover_tooltip()


# 消化UI更新
func _refresh_acid_ui() -> void:
	# 消化ダメージ
	var acid_damage := _get_acid_damage_info()
	# 消化interval
	var acid_interval := _get_acid_interval_info()
	ui.set_acid_damage_info(int(acid_damage["total"]), int(acid_damage["base"]), int(acid_damage["seed_buff"]), float(acid_damage["seed_rate"]), int(acid_damage["nightmare_buff"]), float(acid_damage["nightmare_rate"]))
	ui.set_acid_interval_minutes(float(acid_interval["total"]), float(acid_interval["base"]), int(acid_interval["seed_buff"]), float(acid_interval["seed_rate"]), int(acid_interval["nightmare_buff"]), float(acid_interval["nightmare_rate"]))
	ui.set_rest_recovery_bonus_rate(acid_controller.get_rest_recovery_bonus_rate())


# 状態UI更新
func _refresh_status_ui() -> void:
	ui.set_hp(hp, effective_max_hp)
	ui.set_time(minutes)
	ui.set_Acidion_count(_active_acid_count())
	ui.set_acid_button_visible(battle_active and not auto_acid_enabled)


# hoverツール更新
func _refresh_hover_tooltip() -> void:
	if hovered_enemy != null:
		ui.show_enemy_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
# after戦闘イベント更新
func _refresh_after_battle_event() -> void:
	_refresh_ui()
# ツールデバッグ番号文言取得
func _get_tooltip_debug_number_text(enemy: Enemy) -> String:
	if enemy.has_seed():
		return "ID:%s" % _get_enemy_skill_id_text(enemy)
	return "悪夢:%s" % _get_enemy_skill_id_text(enemy)
# 敵スキルID文言取得
func _get_enemy_skill_id_text(enemy: Enemy) -> String:
	if enemy.has_seed():
		return str(enemy.get_seed().skill_id)
	if not enemy.has_nightmare_skill():
		return "-"
	return str(enemy.get_nightmare_skill().skill_id)
# all悪夢消化済み処理
func _all_nightmares_Acided() -> bool:
	for enemy in enemies:
		if not enemy.should_count_for_battle_clear():
			continue
		if not enemy.is_Acided():
			return false
	return true
# active消化数処理
func _active_acid_count() -> int:
	# 数値
	var count := 0
	for enemy in enemies:
		if enemy.is_stomach_piece():
			count += 1
	return count
# removefrom胃袋ダメージ取得
func _get_remove_from_stomach_damage() -> int:
	# ダメージ率
	var damage_rate := acid_controller.get_remove_from_stomach_damage_rate(REMOVE_FROM_STOMACH_DAMAGE_RATE)
	return ceili(float(effective_max_hp) * damage_rate)
# sumダメージvalues処理
func _sum_damage_values(damage_values: Array[int]) -> int:
	# 合計
	var total := 0
	for damage in damage_values:
		total += damage
	return total


# for消化拍待機
func _wait_for_next_acid_beat() -> void:
	if beat_conductor == null or not is_instance_valid(beat_conductor):
		await get_tree().process_frame
		return
	if beat_conductor.audio_player == null or not beat_conductor.audio_player.playing:
		await get_tree().process_frame
		return
	await beat_conductor.wait_until_next_beat()


# scheduled消化events消去
func _clear_scheduled_acid_events() -> void:
	if beat_conductor != null and is_instance_valid(beat_conductor):
		beat_conductor.clear_scheduled_events()


# 消化生成要求適用
func _apply_acid_spawn_requests(spawn_requests: Array[AcidSpawnRequest]) -> void:
	acid_spawn_request_applier.apply_requests(spawn_requests, enemies, enemy_setup)


# 消化済み種effects適用
func _apply_Acided_seed_effects(Acided_enemies: Array[Enemy]) -> void:
	# HP
	var previous_hp := hp
	hp = seed_controller.apply_direct_Acided_seed_effects(Acided_enemies, hp, effective_max_hp)
	if hp > previous_hp:
		hp = mini(effective_max_hp, hp + acid_controller.add_heal_event(hp - previous_hp))
	for seed in seed_controller.collect_Acided_seeds(Acided_enemies):
		acid_controller.add_Acided_seed_effect(seed)
	_apply_Acided_seed_hp_effects(Acided_enemies)
	_emit_depleted_seed_sources(Acided_enemies)


# playerダメージvalues適用
func _apply_player_damage_values() -> void:
	# playerダメージvalues
	var player_damage_values := acid_controller.apply_acid_damage_values(enemies, stomach, minutes)
	if player_damage_values.is_empty():
		return
	ui.show_hp_damage_values(player_damage_values)
	hp = maxi(0, hp - _sum_damage_values(player_damage_values))


# effective最大HP更新
func _refresh_effective_max_hp(keep_rate: bool) -> void:
	# 最大
	var previous_max := effective_max_hp
	# HP率
	var hp_rate := 1.0 if previous_max <= 0 else float(hp) / float(previous_max)
	effective_max_hp = maxi(1, roundi(float(MAX_HP) * (1.0 + acid_controller.get_max_hp_bonus_rate())))
	if keep_rate:
		hp = clampi(roundi(float(effective_max_hp) * hp_rate), 0, effective_max_hp)
	else:
		hp = clampi(hp, 0, effective_max_hp)


# 時間種HP回復適用
func _apply_time_seed_hp_recovery() -> void:
	# 回復率
	var recovery_rate := acid_controller.get_time_hp_recovery_rate(_active_acid_count())
	recovery_rate += acid_controller.get_hour_hp_recovery_rate(minutes)
	if recovery_rate <= 0.0:
		return
	_heal_player_by_rate(recovery_rate)


# 消化ダメージ種回復適用
func _apply_acid_damage_seed_heal() -> void:
	# 回復量
	var heal_amount := acid_controller.consume_acid_damage_heal_amount()
	if heal_amount <= 0:
		return
	heal_amount += acid_controller.add_heal_event(heal_amount)
	hp = mini(effective_max_hp, hp + heal_amount)


# removefrom胃袋消化ダメージ適用
func _apply_remove_from_stomach_acid_damage(enemy: Enemy) -> void:
	if enemy == null or enemy.is_Acided():
		return
	# ダメージ率
	var damage_rate := acid_controller.get_remove_from_stomach_acid_damage_rate()
	if damage_rate <= 0.0:
		return
	# 消化ダメージ
	var acid_damage := int(_get_acid_damage_info().get("total", 0))
	# ダメージ
	var damage := maxi(1, roundi(float(acid_damage) * damage_rate))
	enemy.show_acid_damage_values([damage])
	if enemy.take_acid_damage(damage, false):
		_check_battle_end()
	else:
		enemy.pulse_damage()


# 消化済み種HPeffects適用
func _apply_Acided_seed_hp_effects(Acided_enemies: Array[Enemy]) -> void:
	for enemy in Acided_enemies:
		if enemy == null or not enemy.has_seed():
			continue
		# 種スキル
		var seed := enemy.get_seed()
		match seed.skill_id:
			2121:
				_heal_player_by_rate(0.05 * float(enemy.get_size()))
			2125:
				_heal_player_by_rate(clampf(float(minutes % 60), 1.0, 60.0) / 100.0)
			2126:
				acid_controller.add_max_hp_bonus_rate(0.10)
				_refresh_effective_max_hp(false)
			2127:
				_heal_player_by_rate(0.50)
			2128:
				_heal_player_by_rate(1.00)


# 消化済み悪夢種effects適用
func _apply_Acided_nightmare_seed_effects(Acided_enemies: Array[Enemy]) -> void:
	# 回復率
	var heal_rate := acid_controller.get_Acided_nightmare_heal_rate()
	# 最大HP率
	var max_hp_rate := acid_controller.get_Acided_nightmare_max_hp_rate()
	if heal_rate <= 0.0 and max_hp_rate <= 0.0:
		return
	for enemy in Acided_enemies:
		if enemy == null or enemy.has_seed():
			continue
		if heal_rate > 0.0:
			# 回復量
			var heal_amount := ceili(float(enemy.get_max_hp()) * heal_rate)
			heal_amount += acid_controller.add_heal_event(heal_amount)
			hp = mini(effective_max_hp, hp + heal_amount)
		if max_hp_rate > 0.0:
			acid_controller.add_max_hp_bonus_rate(max_hp_rate)
			_refresh_effective_max_hp(false)


# 回復playerby率処理
func _heal_player_by_rate(rate: float) -> void:
	if rate <= 0.0:
		return
	# 回復量
	var heal_amount := ceili(float(effective_max_hp) * rate)
	heal_amount += acid_controller.add_heal_event(heal_amount)
	hp = mini(effective_max_hp, hp + heal_amount)


# 種胃袋サイズeffects適用
func _apply_seed_stomach_size_effects() -> void:
	# has列補正
	var has_column_bonus := false
	# has行補正
	var has_row_bonus := false
	for flower in seed_controller.get_flowers():
		if flower == null:
			continue
		match flower.skill_id:
			2118:
				has_column_bonus = true
			2119:
				has_row_bonus = true
	# 列値
	var next_columns := stomach.columns + (1 if has_column_bonus else 0)
	# 行値
	var next_rows := stomach.rows + (1 if has_row_bonus else 0)
	if next_columns != stomach.columns or next_rows != stomach.rows:
		stomach.set_grid_size(next_columns, next_rows)


# resolvepost消化visua処理
func _resolve_post_acid_visuals(Acided_enemies: Array[Enemy]) -> void:
	if Acided_enemies.is_empty():
		return
	await get_tree().create_timer(Enemy.AcidED_TWEEN_DURATION).timeout
	acid_controller.unlock_deferred_nuisance_gravity(enemies)
	stomach.apply_gravity(enemies)


# 消化ダメージ情報取得
func _get_acid_damage_info() -> Dictionary:
	return acid_controller.get_acid_damage_breakdown(enemies, minutes)


# 消化interval情報取得
func _get_acid_interval_info() -> Dictionary:
	return acid_controller.get_step_minutes_breakdown(enemies, false, minutes)
# clickSE再生
func _play_click_se() -> void:
	if click_se == null:
		return
	click_se.stop()
	click_se.play()
