extends Node2D
signal battle_finished(won: bool)
signal dream_seed_depleted(source: Resource)
const START_HOUR: int = 22
const END_HOUR: int = 30
const REST_MINUTES: int = 30
const MAX_HP: int = 100
const REST_HP_RATE: float = 0.1
const TIME_OVER_HP_RECOVERY_RATE: float = 0.7
const DIGEST_AUTO_INTERVAL: float = 0.05
const REMOVE_FROM_STOMACH_DAMAGE_RATE: float = 0.05
const START_MESSAGE: String = "６時までにすべての悪夢を消化しましょう"
const DREAM_SEED_SKILL_CATALOG: DreamSeedSkillCatalog = preload("res://data/resources/dream_seed_skills/dream_seed_skill_catalog.tres")
const SEED_BLOCK_DRAG_ALPHA := 0.58
const DREAM_SEED_ACTIVATION_HP_RECOVERY := 1002
const DREAM_SEED_ACTIVATION_HP_RECOVERY_RATE := 0.05
const DREAM_SEED_ACTIVATION_SKIP_REST_TIME := 1004
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
@export var enemy_definitions: Array[Resource] = []
@export var nightmare_skill_catalog: NightmareSkillCatalog
@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var input_controller: GameInputController = $GameInputController
@onready var click_se: AudioStreamPlayer = $ClickSe
@onready var enemies: Array[Enemy] = [$EnemyLeft as Enemy, $EnemyCenter as Enemy, $EnemyRight as Enemy, $EnemyUpperRight as Enemy]
var minutes := START_HOUR * 60
var hp := MAX_HP
var current_stage_id := 0
var current_stage: StageDefinition
var current_day := 1
var strengthened_enemy_preset_index := 0
var battle_active := false
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digest_turn_in_progress := false
var debug_numbers_visible := false
var digestion_timer: Timer
var enemy_setup := GameEnemySetupController.new()
var digest_controller := NightmareDigestController.new()
var beat_conductor: BeatConductor
var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy
var last_time_over_recovery_percent := 0
var rest_time_skip_count := 0
var battle_flowers: Array[FlowerDefinition] = []
var dragging_seed_block: Enemy
var dragging_seed_button: DreamSeedSkillButton
func _ready() -> void:
	randomize()
	enemy_setup.setup(self, input_controller, stomach, enemy_definitions, nightmare_skill_catalog)
	digest_controller.set_beat_conductor(beat_conductor)
	_connect_ui()
	_connect_input()
	_create_digestion_timer()
	ui.hide_nightmare_tooltip()
func set_beat_conductor(conductor: BeatConductor) -> void:
	beat_conductor = conductor
	digest_controller.set_beat_conductor(beat_conductor)
func start_battle(context: BattleStartContext = null) -> void:
	var battle_context := context if context != null else BattleStartContext.new()
	minutes = START_HOUR * 60
	hp = clampi(battle_context.starting_hp, 0, MAX_HP)
	current_day = battle_context.day
	current_stage_id = battle_context.stage_id
	current_stage = battle_context.stage
	strengthened_enemy_preset_index = 0
	stomach.set_grid_size(battle_context.stomach_columns, battle_context.stomach_rows)
	last_time_over_recovery_percent = 0
	rest_time_skip_count = 0
	debug_numbers_visible = false
	_set_battle_flags(false)
	digest_controller.clear_scheduled_events()
	_set_battle_flowers(battle_context.flowers)
	digest_controller.setup(battle_flowers)
	dragging_enemy = null
	dragging_seed_block = null
	dragging_seed_button = null
	hovered_enemy = null
	enemy_setup.setup(
		self,
		input_controller,
		stomach,
		_get_battle_enemy_definitions(),
		nightmare_skill_catalog,
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
	ui.set_dream_seed_skill_sources(battle_flowers)
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
	return MAX_HP
func get_last_time_over_recovery_percent() -> int:
	return last_time_over_recovery_percent


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
	ui.seed_skill_activation_requested.connect(_on_seed_skill_activation_requested)
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
	if not battle_active or dragging_seed_block != null:
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
	ui.set_dream_seed_debug_numbers_visible(debug_numbers_visible)
	if hovered_enemy != null:
		ui.show_nightmare_tooltip(hovered_enemy, _get_tooltip_debug_number_text(hovered_enemy), debug_numbers_visible)
func _on_debug_reroll_requested() -> void:
	if not battle_active or not debug_numbers_visible or digest_turn_in_progress or dragging_enemy != null or dragging_seed_block != null:
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


func _on_debug_stomach_size_requested(delta_columns: int, delta_rows: int) -> void:
	if not battle_active or not debug_numbers_visible or digest_turn_in_progress or dragging_enemy != null or dragging_seed_block != null:
		return
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	_update_auto_digest_timer()
	stomach.hide_preview()
	ui.hide_hp_damage_preview()
	_set_hovered_enemy(null)
	stomach.set_grid_size(stomach.columns + delta_columns, stomach.rows + delta_rows)
	_refresh_enemy_stomach_display_sizes()
	_refresh_ui()


func _on_debug_seed_requested() -> void:
	if not battle_active or not debug_numbers_visible or digest_turn_in_progress or dragging_enemy != null or dragging_seed_block != null:
		return
	var flower := _get_random_debug_seed_flower()
	if flower == null:
		return
	battle_flowers.append(flower)
	digest_controller.set_seed_effect_flowers(battle_flowers)
	ui.set_dream_seed_skill_sources(battle_flowers)
	_refresh_ui()


func _on_seed_skill_drag_started(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	if not battle_active or digest_turn_in_progress or dragging_enemy != null or dragging_seed_block != null:
		return
	var seed_block := _create_seed_block(seed_skill)
	if seed_block == null:
		return
	dragging_seed_button = button
	dragging_seed_block = seed_block
	dragging_seed_block.global_position = mouse_position
	dragging_seed_block.modulate.a = SEED_BLOCK_DRAG_ALPHA
	auto_digest_paused_for_drag = auto_digest_enabled
	_update_auto_digest_timer()
	_play_click_se()


func _on_seed_skill_drag_moved(
	_button: DreamSeedSkillButton,
	_seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	if not battle_active or dragging_seed_block == null:
		return
	dragging_seed_block.global_position = mouse_position
	stomach.show_preview(dragging_seed_block, mouse_position, Vector2i.ZERO, enemies)
	_set_hovered_enemy(null)


func _on_seed_skill_drag_released(
	_button: DreamSeedSkillButton,
	_seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	if dragging_seed_block == null:
		return
	var seed_block := dragging_seed_block
	var seed_button := dragging_seed_button
	dragging_seed_block = null
	dragging_seed_button = null
	stomach.hide_preview()
	_play_click_se()
	var placed := battle_active and stomach.contains_global_position(mouse_position) and _try_place_seed_block(seed_block, mouse_position)
	if placed:
		if seed_button != null and is_instance_valid(seed_button):
			seed_button.consume_stock()
			_remove_seed_source_if_depleted(seed_button)
	else:
		_cancel_seed_block(seed_block)
	if auto_digest_enabled:
		auto_digest_paused_for_drag = false
	_update_auto_digest_timer()


func _on_seed_skill_activation_requested(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition
) -> void:
	if not battle_active or digest_turn_in_progress or dragging_enemy != null or dragging_seed_block != null:
		return
	if seed_skill == null or seed_skill.sub_skill_mode != DreamSeedSkillDefinition.SubSkillMode.Activation:
		return
	if not _apply_seed_skill_activation(seed_skill):
		return
	if button != null and is_instance_valid(button):
		button.consume_stock()
		_remove_seed_source_if_depleted(button)
	_play_click_se()
	_refresh_after_battle_event()


func _apply_seed_skill_activation(seed_skill: DreamSeedSkillDefinition) -> bool:
	if seed_skill.skill_id == DREAM_SEED_ACTIVATION_HP_RECOVERY:
		hp = mini(MAX_HP, hp + ceili(float(MAX_HP) * DREAM_SEED_ACTIVATION_HP_RECOVERY_RATE))
		return true
	if seed_skill.skill_id == DREAM_SEED_ACTIVATION_SKIP_REST_TIME:
		rest_time_skip_count += 1
		return true
	return digest_controller.add_seed_activation_effect(seed_skill)


func _set_battle_flowers(flowers: Array) -> void:
	battle_flowers.clear()
	for flower in flowers:
		if flower is FlowerDefinition:
			battle_flowers.append(flower as FlowerDefinition)


func _remove_seed_source_if_depleted(button: DreamSeedSkillButton) -> void:
	if button == null or button.get_remaining_stock() > 0:
		return
	var source := button.get_seed_source()
	if source == null:
		return
	_remove_battle_seed_source(source)
	digest_controller.set_seed_effect_flowers(battle_flowers)
	ui.set_dream_seed_skill_sources(battle_flowers)
	dream_seed_depleted.emit(source)


func _remove_battle_seed_source(source: Resource) -> void:
	for i in range(battle_flowers.size() - 1, -1, -1):
		var flower := battle_flowers[i]
		if flower == source:
			battle_flowers.remove_at(i)
			continue
		if source is DreamSeedSkillDefinition and flower != null and flower.dream_seed_skill == source:
			battle_flowers.remove_at(i)


func _get_random_debug_seed_flower() -> FlowerDefinition:
	var candidates := _get_debug_seed_flower_candidates()
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


func _get_debug_seed_flower_candidates() -> Array[FlowerDefinition]:
	var candidates: Array[FlowerDefinition] = []
	_append_debug_seed_flower_candidates(candidates, DREAM_SEED_SKILL_CATALOG.normal_skills)
	_append_debug_seed_flower_candidates(candidates, DREAM_SEED_SKILL_CATALOG.rare_skills)
	return candidates


func _append_debug_seed_flower_candidates(
	candidates: Array[FlowerDefinition],
	skills: Array
) -> void:
	for skill_resource in skills:
		if not skill_resource is DreamSeedSkillDefinition:
			continue
		var skill := skill_resource as DreamSeedSkillDefinition
		var flower := FlowerDefinition.new()
		flower.display_name = skill.display_name
		flower.texture = skill.texture
		flower.dream_seed_skill = skill
		candidates.append(flower)


func _refresh_enemy_stomach_display_sizes() -> void:
	for enemy in enemies:
		if enemy.definition == null or enemy.digested:
			continue
		enemy.update_stomach_display_size(Vector2(
			stomach.get_span_size(enemy.get_stomach_size().x),
			stomach.get_span_size(enemy.get_stomach_size().y)
		))
		if enemy.is_active_in_stomach():
			stomach.place_enemy(enemy, enemy.stomach_cell)


func _create_seed_block(seed_skill: DreamSeedSkillDefinition) -> Enemy:
	if seed_skill == null:
		return null
	var definition := _get_seed_block_template()
	if definition == null:
		return null
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	add_child(seed_block)
	var block_size := _get_seed_block_stomach_size(seed_skill)
	var target_size := Vector2(
		stomach.get_span_size(block_size.x),
		stomach.get_span_size(block_size.y)
	)
	seed_block.setup(definition, target_size, null, false, Vector2.ZERO)
	seed_block.setup_as_seed_stomach_block(seed_skill, target_size)
	return seed_block


func _get_seed_block_stomach_size(seed_skill: DreamSeedSkillDefinition) -> Vector2i:
	if seed_skill != null and seed_skill.drag_block_definition != null:
		return seed_skill.drag_block_definition.get_stomach_size()
	return Vector2i.ONE


func _try_place_seed_block(seed_block: Enemy, mouse_position: Vector2) -> bool:
	if seed_block == null:
		return false
	var top_left := stomach.get_drop_cell(seed_block, mouse_position, Vector2i.ZERO, enemies)
	if not stomach.can_place(seed_block, top_left, enemies):
		return false
	seed_block.modulate.a = 1.0
	seed_block.set_digesting(true)
	enemies.append(seed_block)
	input_controller.setup(enemies)
	stomach.place_enemy(seed_block, top_left)
	_refresh_after_battle_event()
	return true


func _cancel_seed_block(seed_block: Enemy) -> void:
	if seed_block != null:
		seed_block.queue_free()


func _get_seed_block_template() -> EnemyDefinition:
	for definition in _get_battle_enemy_definitions():
		if definition is EnemyDefinition:
			return definition as EnemyDefinition
	return null


func _get_battle_enemy_definitions() -> Array[Resource]:
	return enemy_definitions


func _get_battle_enemy_preset() -> EnemyPresetDefinition:
	if current_stage == null or current_stage.enemy_data == null:
		return null
	if current_stage.is_high_difficulty:
		var strengthened_preset := current_stage.enemy_data.get_strengthened_enemy_preset(strengthened_enemy_preset_index)
		if strengthened_preset != null:
			return strengthened_preset
	return current_stage.enemy_data.pick_normal_enemy_preset()


func _try_start_next_stage_enemy_preset() -> bool:
	if current_stage == null or current_stage.enemy_data == null:
		return false
	var next_preset: EnemyPresetDefinition
	if current_stage.is_high_difficulty:
		strengthened_enemy_preset_index += 1
		next_preset = current_stage.enemy_data.get_strengthened_enemy_preset(strengthened_enemy_preset_index)
	else:
		next_preset = current_stage.enemy_data.pick_endless_enemy_preset()
	if next_preset == null:
		return false
	_setup_enemy_preset(next_preset)
	return true


func _setup_enemy_preset(enemy_preset: EnemyPresetDefinition) -> void:
	enemy_setup.setup(
		self,
		input_controller,
		stomach,
		_get_battle_enemy_definitions(),
		nightmare_skill_catalog,
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
	var damage := _get_remove_from_stomach_damage()
	var damage_values: Array[int] = [damage]
	ui.show_hp_damage_values(damage_values)
	hp = maxi(0, hp - damage)
	_refresh_after_battle_event()
func _advance_digest_turn() -> void:
	if digest_turn_in_progress:
		return
	digest_turn_in_progress = true
	if _active_digest_count() == 0:
		_finish_empty_digest_turn()
		return
	digest_controller.apply_turn_start_effects(enemies)
	var elapsed_minutes := digest_controller.get_step_minutes(enemies)
	await digest_controller.wait_for_next_beat()
	var digested_enemies: Array[Enemy] = digest_controller.digest_nightmares(enemies, stomach, minutes, enemy_setup)
	var player_damage_values := digest_controller.apply_digest_damage_values(enemies, stomach)
	if not player_damage_values.is_empty():
		ui.show_hp_damage_values(player_damage_values)
		hp = maxi(0, hp - _sum_damage_values(player_damage_values))
	_apply_elapsed_time(elapsed_minutes)
	if not digested_enemies.is_empty():
		await get_tree().create_timer(Enemy.DIGESTED_TWEEN_DURATION).timeout
		digest_controller.unlock_deferred_nuisance_gravity(enemies)
		stomach.apply_gravity(enemies)
	_finish_digest_turn()
func _finish_empty_digest_turn() -> void:
	auto_digest_enabled = false
	_refresh_after_battle_event()
	digest_turn_in_progress = false
func _apply_elapsed_time(elapsed_minutes: int) -> void:
	minutes += elapsed_minutes
	if hp <= 0:
		hp = digest_controller.get_rest_hp(MAX_HP, REST_HP_RATE)
		if rest_time_skip_count > 0:
			rest_time_skip_count -= 1
		else:
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
func _check_battle_end() -> void:
	if _all_enemies_digested():
		if _try_start_next_stage_enemy_preset():
			return
		_finish_battle(true, "すべての悪夢を消化しました")
		return
	if minutes >= END_HOUR * 60:
		_apply_time_over_recovery()
		_finish_battle(false, "朝までに消化しきれませんでした")
func _finish_battle(won: bool, _message: String) -> void:
	battle_active = false
	input_controller.set_active(false)
	auto_digest_enabled = false
	digest_controller.clear_scheduled_events()
	_update_auto_digest_timer()
	_refresh_after_battle_event()
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
func _refresh_after_battle_event() -> void:
	_refresh_ui()
func _get_tooltip_debug_number_text(enemy: Enemy) -> String:
	return "悪夢:%s" % _get_enemy_skill_id_text(enemy)
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
