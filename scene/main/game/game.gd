extends Node2D
signal battle_finished(won: bool)
const START_HOUR := 22
const END_HOUR := 30
const REST_MINUTES := 30
const MAX_HP := 100
const REST_HP_RATE := 0.1
const TIME_OVER_HP_RECOVERY_RATE := 0.7
const DIGEST_AUTO_INTERVAL := 0.6
const REMOVE_FROM_STOMACH_DAMAGE_RATE := 0.05
const START_MESSAGE := "６時までにすべての悪夢を消化しましょう"
@export var enemy_definitions: Array[Resource] = []
@export var nightmare_skill_catalog: NightmareSkillCatalog
@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var input_controller: GameInputController = $GameInputController
@onready var passive_flower: PassiveFlowerSpawner = $PassiveFlower
@onready var click_se: AudioStreamPlayer = $ClickSe
@onready var enemies: Array[Enemy] = [$EnemyLeft as Enemy, $EnemyCenter as Enemy, $EnemyRight as Enemy, $EnemyUpperRight as Enemy]
var minutes := START_HOUR * 60
var hp := MAX_HP
var battle_active := false
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digest_turn_in_progress := false
var debug_numbers_visible := false
var digestion_timer: Timer
var enemy_setup := GameEnemySetupController.new()
var digest_controller := NightmareDigestController.new()
var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy
var last_time_over_recovery_percent := 0
func _ready() -> void:
	randomize()
	enemy_setup.setup(self, input_controller, stomach, enemy_definitions, nightmare_skill_catalog)
	_connect_ui()
	_connect_input()
	_create_digestion_timer()
	ui.hide_nightmare_tooltip()
func start_battle(starting_hp: int = MAX_HP, _day: int = 1, flowers: Array = []) -> void:
	minutes = START_HOUR * 60
	hp = clampi(starting_hp, 0, MAX_HP)
	last_time_over_recovery_percent = 0
	debug_numbers_visible = false
	_set_battle_flags(false)
	digest_controller.setup(flowers)
	passive_flower.setup_flowers(flowers)
	dragging_enemy = null
	hovered_enemy = null
	enemy_setup.setup_enemies(enemies)
	ui.reset_for_battle(
		MAX_HP,
		minutes,
		START_MESSAGE,
		REST_MINUTES,
		REST_HP_RATE,
		digest_controller.get_rest_recovery_bonus_rate()
	)
	stomach.hide_preview()
	battle_active = true
	input_controller.set_active(true)
	_refresh_ui()
func get_current_hp() -> int:
	return hp
func get_clear_minutes() -> int:
	return minutes
func get_max_hp() -> int:
	return MAX_HP
func get_last_time_over_recovery_percent() -> int:
	return last_time_over_recovery_percent
func _connect_ui() -> void:
	ui.digestion_requested.connect(_on_digestion_requested)
	ui.debug_message_requested.connect(_on_debug_message_requested)
	ui.debug_reroll_requested.connect(_on_debug_reroll_requested)
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
	if not battle_active:
		return
	dragging_enemy = enemy
	drag_offset = pointer_offset
	drag_grab_cell = grab_cell
	dragged_enemy_was_digesting = enemy.digesting
	dragged_enemy_original_cell = enemy.stomach_cell
	dragged_enemy_original_global_position = enemy.global_position
	auto_digest_paused_for_drag = auto_digest_enabled
	_update_auto_digest_timer()
	_play_click_se()
func _on_enemy_drag_moved(enemy: Enemy, mouse_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i) -> void:
	if not battle_active or enemy != dragging_enemy:
		return
	dragging_enemy.global_position = mouse_position + pointer_offset
	stomach.show_preview(dragging_enemy, mouse_position, grab_cell, enemies)
	_update_hp_damage_preview(mouse_position)
	_set_hovered_enemy(null)
func _on_enemy_drag_released(enemy: Enemy, mouse_position: Vector2) -> void:
	if not battle_active or dragging_enemy == null or enemy != dragging_enemy:
		return
	dragging_enemy = null
	_play_click_se()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	if stomach.contains_global_position(mouse_position):
		_try_start_digesting(enemy, mouse_position)
	else:
		_remove_enemy_from_stomach(enemy)
	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	_update_auto_digest_timer()
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
	if hovered_enemy != null:
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
func _on_debug_reroll_requested() -> void:
	if not battle_active or not debug_numbers_visible or digest_turn_in_progress or dragging_enemy != null:
		return
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	_update_auto_digest_timer()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	_set_hovered_enemy(null)
	digest_controller.reset_digest_order()
	enemy_setup.setup_enemies(enemies)
	input_controller.setup(enemies)
	_refresh_ui()
func _try_start_digesting(enemy: Enemy, mouse_position: Vector2) -> void:
	var next_fullness := stomach.get_current_fullness(enemies)
	if not dragged_enemy_was_digesting:
		next_fullness += enemy.get_size()
	if next_fullness > stomach.get_capacity():
		_return_dragged_enemy(enemy)
		_set_status_message("胃がいっぱいで置けません")
		return
	var top_left := stomach.get_drop_cell(enemy, mouse_position, drag_grab_cell, enemies)
	if not stomach.can_place(enemy, top_left, enemies):
		_return_dragged_enemy(enemy)
		_set_status_message("その場所には置けません")
		return
	enemy.set_digesting(true)
	stomach.place_enemy(enemy, top_left)
	_set_status_message("")
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
	var damage := _get_remove_from_stomach_damage()
	var damage_values: Array[int] = [damage]
	ui.show_hp_damage_values(damage_values)
	hp = maxi(0, hp - damage)
	_set_status_message("悪夢を外したのでダメージを受けました")
func _advance_digest_turn() -> void:
	if digest_turn_in_progress:
		return
	digest_turn_in_progress = true
	if _active_digest_count() == 0:
		_finish_empty_digest_turn()
		return
	digest_controller.apply_turn_start_effects(enemies)
	var elapsed_minutes := digest_controller.get_step_minutes(enemies)
	var digested_enemies := digest_controller.digest_nightmares(enemies, stomach, minutes, enemy_setup)
	var player_damage_values := digest_controller.apply_digest_damage_values(enemies, stomach)
	if not player_damage_values.is_empty():
		ui.show_hp_damage_values(player_damage_values)
		hp = maxi(0, hp - _sum_damage_values(player_damage_values))
	if not digested_enemies.is_empty():
		await get_tree().create_timer(Enemy.DIGESTED_TWEEN_DURATION).timeout
		digest_controller.unlock_deferred_nuisance_gravity(enemies)
		stomach.apply_gravity(enemies)
	_finish_digest_turn(elapsed_minutes)
func _finish_empty_digest_turn() -> void:
	auto_digest_enabled = false
	_set_status_message("消化中の悪夢がありません")
	digest_turn_in_progress = false
func _finish_digest_turn(elapsed_minutes: int) -> void:
	minutes += elapsed_minutes
	if hp <= 0:
		hp = digest_controller.get_rest_hp(MAX_HP, REST_HP_RATE)
		minutes += REST_MINUTES
		elapsed_minutes += REST_MINUTES
		_set_status_message("HPが尽きたため休憩しました")
	else:
		_set_status_message("")
	ui.show_time_elapsed(elapsed_minutes)
	_check_battle_end()
	_update_auto_digest_timer()
	digest_controller.activate_deferred_nuisance_enemies(enemies)
	digest_turn_in_progress = false
func _check_battle_end() -> void:
	if _all_enemies_digested():
		_finish_battle(true, "すべての悪夢を消化しました")
		return
	if minutes >= END_HOUR * 60:
		_apply_time_over_recovery()
		_finish_battle(false, "朝までに消化しきれませんでした")
func _finish_battle(won: bool, message: String) -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_digest_enabled = false
	_update_auto_digest_timer()
	_set_status_message(message)
	battle_finished.emit(won)
func _apply_time_over_recovery() -> void:
	var previous_hp := hp
	hp = mini(MAX_HP, hp + ceili(float(MAX_HP) * TIME_OVER_HP_RECOVERY_RATE))
	last_time_over_recovery_percent = roundi(float(hp - previous_hp) / float(MAX_HP) * 100.0)
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
	if dragged_enemy_was_digesting and not stomach.contains_global_position(mouse_position):
		ui.show_hp_damage_preview(_get_remove_from_stomach_damage())
	else:
		ui.hide_hp_damage_preview()
func _refresh_ui() -> void:
	digest_controller.refresh_enemy_status_display(enemies, stomach)
	var digest_damage := digest_controller.get_digest_damage_breakdown(enemies, minutes)
	var digest_efficiency := digest_controller.get_step_minutes_breakdown(enemies)
	ui.set_digest_damage_info(int(digest_damage["total"]), int(digest_damage["base"]), int(digest_damage["seed_buff"]), float(digest_damage["seed_rate"]), int(digest_damage["nightmare_buff"]), float(digest_damage["nightmare_rate"]))
	ui.set_digest_efficiency_minutes(float(digest_efficiency["total"]), float(digest_efficiency["base"]), int(digest_efficiency["seed_buff"]), float(digest_efficiency["seed_rate"]), int(digest_efficiency["nightmare_buff"]), float(digest_efficiency["nightmare_rate"]))
	ui.set_rest_recovery_bonus_rate(digest_controller.get_rest_recovery_bonus_rate())
	ui.set_hp(hp, MAX_HP)
	ui.set_time(minutes)
	ui.set_digestion_count(_active_digest_count())
	ui.set_digestion_button_visible(battle_active and not auto_digest_enabled)
	if hovered_enemy != null:
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
func _set_status_message(message: String) -> void:
	ui.set_message(START_MESSAGE)
	ui.set_debug_message(message)
	_refresh_ui()
func _get_tooltip_debug_number_text(enemy: Enemy) -> String:
	return "悪夢:%s\n種:%s" % [_get_enemy_skill_id_text(enemy), digest_controller.get_seed_skill_id_text()]
func _get_enemy_skill_id_text(enemy: Enemy) -> String:
	if enemy.skill_definition == null:
		return "-"
	return str(enemy.skill_definition.skill_id)
func _all_enemies_digested() -> bool:
	for enemy in enemies:
		if not enemy.digested:
			return false
	return true
func _active_digest_count() -> int:
	var count := 0
	for enemy in enemies:
		if enemy.is_active_in_stomach():
			count += 1
	return count
func _get_remove_from_stomach_damage() -> int:
	return ceili(float(MAX_HP) * REMOVE_FROM_STOMACH_DAMAGE_RATE)
func _sum_damage_values(damage_values: Array[int]) -> int:
	var total := 0
	for damage in damage_values:
		total += damage
	return total
func _play_click_se() -> void:
	if click_se == null:
		return
	click_se.stop()
	click_se.play()
