extends Node2D
signal battle_finished(won: bool)
signal dream_seed_depleted(source: Resource)
enum DragMode {
	NONE,
	ENEMY,
	DREAM_SEED,
}
const START_HOUR: int = 22
const END_HOUR: int = 30
const REST_MINUTES: int = 30
const MAX_HP: int = 100
const REST_HP_RATE: float = 0.1
const TIME_OVER_HP_RECOVERY_RATE: float = 0.7
const DIGEST_AUTO_INTERVAL: float = 0.05
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
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digest_turn_in_progress := false
var drag_mode := DragMode.NONE
var debug_numbers_visible := false
var digestion_timer: Timer
var enemy_setup := GameEnemySetupController.new()
var digest_controller := NightmareDigestController.new()
var dream_seed_controller := GameDreamSeedController.new()
var digest_spawn_request_applier := DigestSpawnRequestApplier.new()
var beat_conductor: BeatConductor
var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy
var last_time_over_recovery_percent := 0
var effective_max_hp := MAX_HP
func _ready() -> void:
	randomize()
	enemy_setup.setup(self, input_controller, stomach, enemy_definitions)
	dream_seed_controller.setup(self, stomach, input_controller)
	_connect_ui()
	_connect_input()
	_create_digestion_timer()
	ui.hide_nightmare_tooltip()
func set_beat_conductor(conductor: BeatConductor) -> void:
	beat_conductor = conductor
func start_battle(context: BattleStartContext = null) -> void:
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
	_clear_scheduled_digest_events()
	dream_seed_controller.set_flowers(battle_context.flowers)
	_apply_seed_stomach_size_effects()
	digest_controller.setup(dream_seed_controller.get_flowers())
	digest_controller.set_day(current_day)
	_refresh_effective_max_hp(false)
	dragging_enemy = null
	dream_seed_controller.cancel_drag()
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
		digest_controller.get_rest_recovery_bonus_rate()
	)
	ui.set_dream_seed_skill_sources(dream_seed_controller.get_flowers())
	ui.set_dream_seed_debug_numbers_visible(debug_numbers_visible)
	stomach.hide_preview()
	battle_active = true
	input_controller.set_active(true)
	_refresh_ui()
func get_current_hp() -> int:
	return hp
func get_clear_minutes() -> int:
	return minutes
func get_max_hp() -> int:
	return effective_max_hp
func get_last_time_over_recovery_percent() -> int:
	return last_time_over_recovery_percent


func cancel_battle() -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	digest_turn_in_progress = false
	_clear_scheduled_digest_events()
	_update_auto_digest_timer()


func get_stomach_columns() -> int:
	return stomach.columns


func get_stomach_rows() -> int:
	return stomach.rows


func _connect_ui() -> void:
	ui.digestion_requested.connect(_on_digestion_requested)
	ui.debug_message_requested.connect(_on_debug_message_requested)
	ui.debug_reroll_requested.connect(_on_debug_reroll_requested)
	ui.debug_stomach_size_requested.connect(_on_debug_stomach_size_requested)
	ui.debug_seed_requested.connect(_on_debug_seed_requested)
	ui.seed_skill_drag_started.connect(_on_seed_skill_drag_started)
	ui.seed_skill_drag_moved.connect(_on_seed_skill_drag_moved)
	ui.seed_skill_drag_released.connect(_on_seed_skill_drag_released)
func _connect_input() -> void:
	input_controller.setup(enemies)
	input_controller.enemy_drag_started.connect(_on_enemy_drag_started)
	input_controller.enemy_drag_moved.connect(_on_enemy_drag_moved)
	input_controller.enemy_drag_released.connect(_on_enemy_drag_released)
	input_controller.enemy_hover_requested.connect(_set_hovered_enemy)
func _set_battle_flags(is_active: bool) -> void:
	battle_active = is_active
	input_controller.set_active(is_active)
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	digest_turn_in_progress = false
	drag_mode = DragMode.NONE
	dream_seed_controller.cancel_drag()
	if digestion_timer != null and not digestion_timer.is_stopped():
		digestion_timer.stop()
func _create_digestion_timer() -> void:
	digestion_timer = Timer.new()
	digestion_timer.name = "AutoDigestionTimer"
	digestion_timer.wait_time = DIGEST_AUTO_INTERVAL
	digestion_timer.one_shot = false
	digestion_timer.timeout.connect(_on_digestion_timer_timeout)
	add_child(digestion_timer)
func _on_enemy_drag_started(enemy: Enemy, _mouse_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i) -> void:
	if not _can_start_enemy_drag():
		input_controller.clear_drag()
		return
	drag_mode = DragMode.ENEMY
	dragging_enemy = enemy
	drag_offset = pointer_offset
	drag_grab_cell = grab_cell
	dragged_enemy_was_digesting = enemy.is_digesting()
	dragged_enemy_original_cell = enemy.stomach_cell
	dragged_enemy_original_global_position = enemy.global_position
	auto_digest_paused_for_drag = auto_digest_enabled
	_update_auto_digest_timer()
	_play_click_se()
func _on_enemy_drag_moved(enemy: Enemy, mouse_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i) -> void:
	if not battle_active or drag_mode != DragMode.ENEMY or enemy != dragging_enemy:
		return
	dragging_enemy.global_position = mouse_position + pointer_offset
	stomach.show_preview(dragging_enemy, mouse_position, grab_cell, enemies)
	_update_hp_damage_preview(mouse_position)
	_set_hovered_enemy(null)
func _on_enemy_drag_released(enemy: Enemy, mouse_position: Vector2) -> void:
	if not battle_active or drag_mode != DragMode.ENEMY or dragging_enemy == null or enemy != dragging_enemy:
		return
	_finish_enemy_drag_release(enemy, mouse_position)
	_finish_drag_operation()


func _finish_enemy_drag_release(enemy: Enemy, mouse_position: Vector2) -> void:
	dragging_enemy = null
	_play_click_se()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	if stomach.contains_global_position(mouse_position):
		_try_start_digesting(enemy, mouse_position)
	else:
		if digest_controller.is_remove_from_stomach_disabled():
			_return_dragged_enemy(enemy)
			_refresh_after_battle_event()
			return
		_remove_enemy_from_stomach(enemy)


func _on_digestion_requested() -> void:
	if not battle_active:
		return
	if _active_digest_count() == 0:
		_advance_digest_turn()
		return
	auto_digest_enabled = true
	auto_digest_paused_for_drag = false
	if not stomach.has_bottom_touching_enemy(enemies):
		stomach.apply_gravity(enemies)
	_refresh_ui()
	_advance_digest_turn()
func _on_digestion_timer_timeout() -> void:
	if not auto_digest_enabled or auto_digest_paused_for_drag:
		_update_auto_digest_timer()
		return
	_advance_digest_turn()
func _on_debug_message_requested(is_active: bool) -> void:
	debug_numbers_visible = is_active
	ui.set_dream_seed_debug_numbers_visible(debug_numbers_visible)
	if hovered_enemy != null:
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
func _on_debug_reroll_requested() -> void:
	if not _can_use_debug_action():
		return
	_prepare_debug_battle_change()
	digest_controller.reset_digest_order()
	enemy_setup.setup_enemies(enemies)
	input_controller.setup(enemies)
	_refresh_ui()


func _on_debug_stomach_size_requested(delta_columns: int, delta_rows: int) -> void:
	if not _can_use_debug_action():
		return
	_prepare_debug_battle_change()
	stomach.set_grid_size(stomach.columns + delta_columns, stomach.rows + delta_rows)
	_refresh_enemy_stomach_display_sizes()
	_refresh_ui()


func _on_debug_seed_requested() -> void:
	if not _can_use_debug_action():
		return
	if not dream_seed_controller.add_random_debug_seed():
		return
	_sync_dream_seed_sources()
	_refresh_ui()


func _on_seed_skill_drag_started(
	button: DreamSeedSkillButton,
	seed_skill: SeedInfo,
	mouse_position: Vector2
) -> void:
	if not _can_start_seed_drag():
		return
	var result := dream_seed_controller.start_drag(button, seed_skill, mouse_position)
	if not result.started:
		return
	drag_mode = DragMode.DREAM_SEED
	auto_digest_paused_for_drag = auto_digest_enabled
	_update_auto_digest_timer()
	_play_click_se()


func _on_seed_skill_drag_moved(
	_button: DreamSeedSkillButton,
	_seed_skill: SeedInfo,
	mouse_position: Vector2
) -> void:
	if not battle_active or drag_mode != DragMode.DREAM_SEED:
		return
	dream_seed_controller.move_drag(mouse_position, enemies)
	_set_hovered_enemy(null)


func _on_seed_skill_drag_released(
	_button: DreamSeedSkillButton,
	_seed_skill: SeedInfo,
	mouse_position: Vector2
) -> void:
	if drag_mode != DragMode.DREAM_SEED:
		return
	var result := dream_seed_controller.release_drag(mouse_position, enemies)
	_handle_seed_drag_result(result)
	_finish_drag_operation()


func _handle_seed_drag_result(result: DreamSeedDragResult) -> void:
	if result.started:
		_play_click_se()
	if result.placed:
		_apply_placed_seed_drag_result(result)


func _apply_placed_seed_drag_result(result: DreamSeedDragResult) -> void:
	_refresh_after_battle_event()
	if result.source_button == null or not is_instance_valid(result.source_button):
		return
	result.source_button.consume_sub_skill_use()
	dream_seed_controller.remove_source_while_in_stomach(result.source_button, result.seed_block)
	_sync_dream_seed_sources()


func _finish_drag_operation() -> void:
	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	drag_mode = DragMode.NONE
	_update_auto_digest_timer()


func _sync_dream_seed_sources() -> void:
	var flowers := dream_seed_controller.get_flowers()
	digest_controller.set_seed_effect_flowers(flowers)
	ui.set_dream_seed_skill_sources(flowers)


func _can_start_enemy_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not digest_turn_in_progress


func _can_start_seed_drag() -> bool:
	return battle_active and drag_mode == DragMode.NONE and not digest_turn_in_progress


func _can_use_debug_action() -> bool:
	return battle_active and debug_numbers_visible and drag_mode == DragMode.NONE and not digest_turn_in_progress


func _prepare_debug_battle_change() -> void:
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	_update_auto_digest_timer()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	_set_hovered_enemy(null)


func _refresh_enemy_stomach_display_sizes() -> void:
	for enemy in enemies:
		if enemy.definition == null or enemy.is_digested():
			continue
		enemy.update_stomach_display_size(Vector2(
			stomach.get_span_size(enemy.get_stomach_size().x),
			stomach.get_span_size(enemy.get_stomach_size().y)
		))
		if enemy.is_active_in_stomach():
			stomach.place_enemy(enemy, enemy.stomach_cell)


func _get_battle_enemy_definitions() -> Array[Resource]:
	return enemy_definitions


func _get_battle_enemy_preset() -> NightmarePresetInfo:
	return current_enemy_preset


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


func _try_start_digesting(enemy: Enemy, mouse_position: Vector2) -> void:
	var next_fullness := stomach.get_current_fullness(enemies)
	if not dragged_enemy_was_digesting:
		next_fullness += enemy.get_size()
	if next_fullness > stomach.get_capacity():
		_return_dragged_enemy(enemy)
		_refresh_after_battle_event()
		return
	var top_left := stomach.get_drop_cell(enemy, mouse_position, drag_grab_cell, enemies)
	if not stomach.can_place(enemy, top_left, enemies):
		_return_dragged_enemy(enemy)
		_refresh_after_battle_event()
		return
	enemy.set_digesting(true)
	stomach.place_enemy(enemy, top_left)
	_refresh_after_battle_event()
func _return_dragged_enemy(enemy: Enemy) -> void:
	if dragged_enemy_was_digesting:
		enemy.set_digesting(true)
		enemy.set_stomach_cell(dragged_enemy_original_cell)
		enemy.global_position = dragged_enemy_original_global_position
		return
	enemy.return_to_origin()
func _remove_enemy_from_stomach(enemy: Enemy) -> void:
	if not dragged_enemy_was_digesting:
		enemy.return_to_origin()
		return
	enemy.set_digesting(false)
	enemy.return_to_origin()
	_apply_remove_from_stomach_digest_damage(enemy)
	var damage := _get_remove_from_stomach_damage()
	var damage_values: Array[int] = [damage]
	if damage > 0:
		ui.show_hp_damage_values(damage_values)
		hp = maxi(0, hp - damage)
	_refresh_after_battle_event()
func _advance_digest_turn() -> void:
	if not _begin_digest_turn():
		return
	_apply_time_seed_hp_recovery()
	digest_controller.apply_turn_start_effects(enemies, stomach, minutes)
	var elapsed_minutes := digest_controller.get_step_minutes(enemies, minutes)
	await _wait_for_next_digest_beat()
	var digest_result := _run_digest_core(minutes, elapsed_minutes)
	_apply_digest_damage_seed_heal()
	_apply_digested_nightmare_seed_effects(digest_result.digested_enemies)
	_apply_digested_seed_effects(digest_result.digested_enemies)
	_apply_player_damage_values()
	_apply_elapsed_time(elapsed_minutes + digest_result.extra_elapsed_minutes)
	if digest_result.time_override_minutes >= 0:
		minutes = digest_result.time_override_minutes
		_refresh_after_battle_event()
	await _resolve_post_digest_visuals(digest_result.digested_enemies)
	_finish_digest_turn()


func _begin_digest_turn() -> bool:
	if digest_turn_in_progress:
		return false
	digest_turn_in_progress = true
	if _active_digest_count() == 0:
		_finish_empty_digest_turn()
		return false
	return true


func _run_digest_core(current_minutes: int, elapsed_minutes: int) -> DigestTurnResult:
	var digested_enemies: Array[Enemy] = digest_controller.digest_nightmares(enemies, stomach, current_minutes, elapsed_minutes)
	var digest_result := digest_controller.build_turn_result(digested_enemies)
	_apply_digest_spawn_requests(digest_result.spawn_requests)
	return digest_result


func _finish_empty_digest_turn() -> void:
	auto_digest_enabled = false
	_refresh_after_battle_event()
	digest_turn_in_progress = false
func _apply_elapsed_time(elapsed_minutes: int) -> void:
	minutes += elapsed_minutes
	if hp <= 0:
		digest_controller.add_revive_event()
		_refresh_effective_max_hp(true)
		hp = digest_controller.get_rest_hp(effective_max_hp, REST_HP_RATE)
		if not dream_seed_controller.consume_rest_time_skip():
			minutes += REST_MINUTES
			elapsed_minutes += REST_MINUTES
		_refresh_after_battle_event()
	else:
		_refresh_after_battle_event()
	ui.show_time_elapsed(elapsed_minutes)


func _finish_digest_turn() -> void:
	_check_battle_end()
	_update_auto_digest_timer()
	digest_controller.activate_deferred_nuisance_enemies(enemies)
	digest_turn_in_progress = false


func _emit_depleted_dream_seed_sources(digested_enemies: Array[Enemy]) -> void:
	for source in dream_seed_controller.collect_depleted_sources(digested_enemies):
		dream_seed_depleted.emit(source)


func _check_battle_end() -> void:
	if _all_nightmares_digested():
		_finish_battle(true, "すべての悪夢を消化しました")
		return
	if minutes >= END_HOUR * 60:
		_apply_time_over_recovery()
		_finish_battle(false, "朝までに消化しきれませんでした")
func _finish_battle(won: bool, _message: String) -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_digest_enabled = false
	_clear_scheduled_digest_events()
	_update_auto_digest_timer()
	_refresh_after_battle_event()
	battle_finished.emit(won)
func _apply_time_over_recovery() -> void:
	var previous_hp := hp
	hp = mini(effective_max_hp, hp + ceili(float(effective_max_hp) * TIME_OVER_HP_RECOVERY_RATE))
	last_time_over_recovery_percent = roundi(float(hp - previous_hp) / float(effective_max_hp) * 100.0)
func _update_auto_digest_timer() -> void:
	var active_digest_count := _active_digest_count()
	if auto_digest_enabled and active_digest_count == 0:
		auto_digest_enabled = false
		auto_digest_paused_for_drag = false
	if auto_digest_enabled and battle_active and not auto_digest_paused_for_drag and active_digest_count > 0:
		if digestion_timer.is_stopped():
			digestion_timer.start()
	else:
		if not digestion_timer.is_stopped():
			digestion_timer.stop()
	_refresh_ui()
func _set_hovered_enemy(enemy: Enemy) -> void:
	if hovered_enemy == enemy:
		return
	if hovered_enemy != null:
		hovered_enemy.set_hovered(false)
	hovered_enemy = enemy
	if hovered_enemy != null:
		hovered_enemy.set_hovered(true)
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
	else:
		ui.hide_nightmare_tooltip()
func _update_hp_damage_preview(mouse_position: Vector2) -> void:
	if (
		dragged_enemy_was_digesting
		and not digest_controller.is_remove_from_stomach_disabled()
		and not stomach.contains_global_position(mouse_position)
	):
		ui.show_hp_damage_preview(_get_remove_from_stomach_damage())
	else:
		ui.hide_hp_damage_preview()
func _refresh_ui() -> void:
	digest_controller.refresh_enemy_status_display(enemies, stomach, minutes)
	_refresh_digest_ui()
	_refresh_status_ui()
	_refresh_hover_tooltip()


func _refresh_digest_ui() -> void:
	var digest_damage := _get_digest_damage_info()
	var digest_efficiency := _get_digest_efficiency_info()
	ui.set_digest_damage_info(int(digest_damage["total"]), int(digest_damage["base"]), int(digest_damage["seed_buff"]), float(digest_damage["seed_rate"]), int(digest_damage["nightmare_buff"]), float(digest_damage["nightmare_rate"]))
	ui.set_digest_efficiency_minutes(float(digest_efficiency["total"]), float(digest_efficiency["base"]), int(digest_efficiency["seed_buff"]), float(digest_efficiency["seed_rate"]), int(digest_efficiency["nightmare_buff"]), float(digest_efficiency["nightmare_rate"]))
	ui.set_rest_recovery_bonus_rate(digest_controller.get_rest_recovery_bonus_rate())


func _refresh_status_ui() -> void:
	ui.set_hp(hp, effective_max_hp)
	ui.set_time(minutes)
	ui.set_digestion_count(_active_digest_count())
	ui.set_digestion_button_visible(battle_active and not auto_digest_enabled)


func _refresh_hover_tooltip() -> void:
	if hovered_enemy != null:
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
func _refresh_after_battle_event() -> void:
	_refresh_ui()
func _get_tooltip_debug_number_text(enemy: Enemy) -> String:
	if enemy.has_seed_skill():
		return "ID:%s" % _get_enemy_skill_id_text(enemy)
	return "悪夢:%s" % _get_enemy_skill_id_text(enemy)
func _get_enemy_skill_id_text(enemy: Enemy) -> String:
	if enemy.has_seed_skill():
		return str(enemy.get_seed_skill().skill_id)
	if not enemy.has_nightmare_skill():
		return "-"
	return str(enemy.get_nightmare_skill().skill_id)
func _all_nightmares_digested() -> bool:
	for enemy in enemies:
		if not enemy.should_count_for_battle_clear():
			continue
		if not enemy.is_digested():
			return false
	return true
func _active_digest_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.is_stomach_piece():
			count += 1
	return count
func _get_remove_from_stomach_damage() -> int:
	var damage_rate := digest_controller.get_remove_from_stomach_damage_rate(REMOVE_FROM_STOMACH_DAMAGE_RATE)
	return ceili(float(effective_max_hp) * damage_rate)
func _sum_damage_values(damage_values: Array[int]) -> int:
	var total := 0
	for damage in damage_values:
		total += damage
	return total


func _wait_for_next_digest_beat() -> void:
	if beat_conductor == null or not is_instance_valid(beat_conductor):
		await get_tree().process_frame
		return
	if beat_conductor.audio_player == null or not beat_conductor.audio_player.playing:
		await get_tree().process_frame
		return
	await beat_conductor.wait_until_next_beat()


func _clear_scheduled_digest_events() -> void:
	if beat_conductor != null and is_instance_valid(beat_conductor):
		beat_conductor.clear_scheduled_events()


func _apply_digest_spawn_requests(spawn_requests: Array[DigestSpawnRequest]) -> void:
	digest_spawn_request_applier.apply_requests(spawn_requests, enemies, enemy_setup)


func _apply_digested_seed_effects(digested_enemies: Array[Enemy]) -> void:
	var previous_hp := hp
	hp = dream_seed_controller.apply_direct_digested_seed_effects(digested_enemies, hp, effective_max_hp)
	if hp > previous_hp:
		hp = mini(effective_max_hp, hp + digest_controller.add_heal_event(hp - previous_hp))
	for seed_skill in dream_seed_controller.collect_digested_seed_skills(digested_enemies):
		digest_controller.add_digested_seed_effect(seed_skill)
	_apply_digested_seed_hp_effects(digested_enemies)
	_emit_depleted_dream_seed_sources(digested_enemies)


func _apply_player_damage_values() -> void:
	var player_damage_values := digest_controller.apply_digest_damage_values(enemies, stomach, minutes)
	if player_damage_values.is_empty():
		return
	ui.show_hp_damage_values(player_damage_values)
	hp = maxi(0, hp - _sum_damage_values(player_damage_values))


func _refresh_effective_max_hp(keep_rate: bool) -> void:
	var previous_max := effective_max_hp
	var hp_rate := 1.0 if previous_max <= 0 else float(hp) / float(previous_max)
	effective_max_hp = maxi(1, roundi(float(MAX_HP) * (1.0 + digest_controller.get_max_hp_bonus_rate())))
	if keep_rate:
		hp = clampi(roundi(float(effective_max_hp) * hp_rate), 0, effective_max_hp)
	else:
		hp = clampi(hp, 0, effective_max_hp)


func _apply_time_seed_hp_recovery() -> void:
	var recovery_rate := digest_controller.get_time_hp_recovery_rate(_active_digest_count())
	recovery_rate += digest_controller.get_hour_hp_recovery_rate(minutes)
	if recovery_rate <= 0.0:
		return
	_heal_player_by_rate(recovery_rate)


func _apply_digest_damage_seed_heal() -> void:
	var heal_amount := digest_controller.consume_digest_damage_heal_amount()
	if heal_amount <= 0:
		return
	heal_amount += digest_controller.add_heal_event(heal_amount)
	hp = mini(effective_max_hp, hp + heal_amount)


func _apply_remove_from_stomach_digest_damage(enemy: Enemy) -> void:
	if enemy == null or enemy.is_digested():
		return
	var damage_rate := digest_controller.get_remove_from_stomach_digest_damage_rate()
	if damage_rate <= 0.0:
		return
	var digest_damage := int(_get_digest_damage_info().get("total", 0))
	var damage := maxi(1, roundi(float(digest_damage) * damage_rate))
	enemy.show_digest_damage_values([damage])
	if enemy.take_digest_damage(damage, false):
		_check_battle_end()
	else:
		enemy.pulse_damage()


func _apply_digested_seed_hp_effects(digested_enemies: Array[Enemy]) -> void:
	for enemy in digested_enemies:
		if enemy == null or not enemy.has_seed_skill():
			continue
		var seed_skill := enemy.get_seed_skill()
		match seed_skill.skill_id:
			2121:
				_heal_player_by_rate(0.05 * float(enemy.get_size()))
			2125:
				_heal_player_by_rate(clampf(float(minutes % 60), 1.0, 60.0) / 100.0)
			2126:
				digest_controller.add_max_hp_bonus_rate(0.10)
				_refresh_effective_max_hp(false)
			2127:
				_heal_player_by_rate(0.50)
			2128:
				_heal_player_by_rate(1.00)


func _apply_digested_nightmare_seed_effects(digested_enemies: Array[Enemy]) -> void:
	var heal_rate := digest_controller.get_digested_nightmare_heal_rate()
	var max_hp_rate := digest_controller.get_digested_nightmare_max_hp_rate()
	if heal_rate <= 0.0 and max_hp_rate <= 0.0:
		return
	for enemy in digested_enemies:
		if enemy == null or enemy.has_seed_skill():
			continue
		if heal_rate > 0.0:
			var heal_amount := ceili(float(enemy.get_max_hp()) * heal_rate)
			heal_amount += digest_controller.add_heal_event(heal_amount)
			hp = mini(effective_max_hp, hp + heal_amount)
		if max_hp_rate > 0.0:
			digest_controller.add_max_hp_bonus_rate(max_hp_rate)
			_refresh_effective_max_hp(false)


func _heal_player_by_rate(rate: float) -> void:
	if rate <= 0.0:
		return
	var heal_amount := ceili(float(effective_max_hp) * rate)
	heal_amount += digest_controller.add_heal_event(heal_amount)
	hp = mini(effective_max_hp, hp + heal_amount)


func _apply_seed_stomach_size_effects() -> void:
	var has_column_bonus := false
	var has_row_bonus := false
	for flower in dream_seed_controller.get_flowers():
		if flower == null:
			continue
		match flower.skill_id:
			2118:
				has_column_bonus = true
			2119:
				has_row_bonus = true
	var next_columns := stomach.columns + (1 if has_column_bonus else 0)
	var next_rows := stomach.rows + (1 if has_row_bonus else 0)
	if next_columns != stomach.columns or next_rows != stomach.rows:
		stomach.set_grid_size(next_columns, next_rows)


func _resolve_post_digest_visuals(digested_enemies: Array[Enemy]) -> void:
	if digested_enemies.is_empty():
		return
	await get_tree().create_timer(Enemy.DIGESTED_TWEEN_DURATION).timeout
	digest_controller.unlock_deferred_nuisance_gravity(enemies)
	stomach.apply_gravity(enemies)


func _get_digest_damage_info() -> Dictionary:
	return digest_controller.get_digest_damage_breakdown(enemies, minutes)


func _get_digest_efficiency_info() -> Dictionary:
	return digest_controller.get_step_minutes_breakdown(enemies, false, minutes)
func _play_click_se() -> void:
	if click_se == null:
		return
	click_se.stop()
	click_se.play()
