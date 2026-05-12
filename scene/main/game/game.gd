extends Node2D

signal battle_finished(won: bool)

const START_HOUR := 22
const END_HOUR := 30
const STEP_MINUTES := 30
const REST_MINUTES := 60
const MAX_HP := 100
const REST_HP_RATE := 0.1
const DIGEST_DAMAGE := 200
const DIGEST_AUTO_INTERVAL := 0.6
const REMOVE_FROM_STOMACH_DAMAGE_RATE := 0.05
const START_MESSAGE := "６時までにすべての悪夢を消化しましょう"
const ENEMY_TOP_Y := 280.0
const ENEMY_MIDDLE_Y := 390.0
const ENEMY_BOTTOM_Y := 505.0
const ENEMY_LEFT_X := 850.0
const ENEMY_CENTER_X := 1000.0
const ENEMY_RIGHT_X := 1150.0
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")

@export var enemy_definitions: Array[Resource] = []
@export var nightmare_skill_catalog: NightmareSkillCatalog

@onready var ui: BattleUI = $UI
@onready var stomach: StomachBoard = $Stomach
@onready var input_controller: GameInputController = $GameInputController
@onready var click_se: AudioStreamPlayer = $ClickSe
@onready var enemies: Array[Enemy] = [
	$EnemyLeft as Enemy,
	$EnemyCenter as Enemy,
	$EnemyRight as Enemy,
	$EnemyUpperRight as Enemy,
]

var minutes := START_HOUR * 60
var hp := MAX_HP
var battle_active := false
var auto_digest_enabled := false
var auto_digest_paused_for_drag := false
var digest_turn_in_progress := false
var digestion_timer: Timer
var current_message := START_MESSAGE
var planted_flowers: Array[FlowerDefinition] = []
var digest_order := 0
var next_digest_damage_bonus_rate := 0.0
var rest_recovery_bonus_rate := 0.0
var debug_numbers_visible := false

var dragging_enemy: Enemy
var drag_offset := Vector2.ZERO
var drag_grab_cell := Vector2i.ZERO
var dragged_enemy_was_digesting := false
var dragged_enemy_original_cell := Vector2i.ZERO
var dragged_enemy_original_global_position := Vector2.ZERO
var hovered_enemy: Enemy


func _ready() -> void:
	randomize()
	ui.digestion_requested.connect(_on_digestion_requested)
	ui.debug_message_requested.connect(_on_debug_message_requested)
	ui.debug_reroll_requested.connect(_on_debug_reroll_requested)
	input_controller.setup(enemies)
	input_controller.enemy_drag_started.connect(_on_enemy_drag_started)
	input_controller.enemy_drag_moved.connect(_on_enemy_drag_moved)
	input_controller.enemy_drag_released.connect(_on_enemy_drag_released)
	input_controller.enemy_hover_requested.connect(_set_hovered_enemy)
	_create_digestion_timer()
	ui.hide_nightmare_tooltip()


func start_battle(starting_hp: int = MAX_HP, _day: int = 1, flowers: Array = []) -> void:
	minutes = START_HOUR * 60
	hp = clampi(starting_hp, 0, MAX_HP)
	_set_planted_flowers(flowers)
	next_digest_damage_bonus_rate = 0.0
	rest_recovery_bonus_rate = 0.0
	debug_numbers_visible = false
	battle_active = false
	input_controller.set_active(false)
	auto_digest_enabled = false
	auto_digest_paused_for_drag = false
	digest_turn_in_progress = false
	if digestion_timer != null and not digestion_timer.is_stopped():
		digestion_timer.stop()
	dragging_enemy = null
	hovered_enemy = null
	_setup_enemies()
	current_message = START_MESSAGE
	ui.reset_for_battle(MAX_HP, minutes, current_message)
	_refresh_ui()
	stomach.hide_preview()
	battle_active = true
	input_controller.set_active(true)
	_refresh_ui()


func _set_planted_flowers(flowers: Array) -> void:
	planted_flowers.clear()
	for flower in flowers:
		if flower is FlowerDefinition:
			planted_flowers.append(flower as FlowerDefinition)


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


func _setup_enemies() -> void:
	digest_order = 0
	var selected_skills := _get_random_nightmare_skills()
	var enemy_positions := _get_enemy_positions(selected_skills.size())
	var main_effect_enemy_index := randi() % selected_skills.size() if not selected_skills.is_empty() else -1
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if i >= selected_skills.size():
			enemy.visible = false
			enemy.digested = true
			enemy.digesting = false
			enemy.has_main_effect = false
			continue
		var definition := _get_enemy_template(i)
		if definition == null:
			continue
		enemy.setup(
			definition,
			Vector2(
				stomach.get_span_size(definition.stomach_size.x),
				stomach.get_span_size(definition.stomach_size.y)
			),
			selected_skills[i],
			i == main_effect_enemy_index,
			enemy_positions[i]
		)


func _get_random_nightmare_skills() -> Array[NightmareSkillDefinition]:
	if nightmare_skill_catalog == null or nightmare_skill_catalog.skills.is_empty():
		return []
	var skills_by_category: Dictionary = {}
	for skill in nightmare_skill_catalog.skills:
		if skill == null:
			continue
		var category := skill.category
		if category.is_empty():
			category = "通常"
		if not skills_by_category.has(category):
			skills_by_category[category] = []
		skills_by_category[category].append(skill)
	var categories := skills_by_category.keys()
	if categories.is_empty():
		return []
	var category = categories[randi() % categories.size()]
	var category_skills: Array = skills_by_category[category].duplicate()
	category_skills.shuffle()
	var max_count := mini(4, category_skills.size())
	var min_count := mini(2, max_count)
	var count := randi_range(min_count, max_count)
	var selected: Array[NightmareSkillDefinition] = []
	for i in range(count):
		selected.append(category_skills[i] as NightmareSkillDefinition)
	return selected


func _get_enemy_template(enemy_index: int) -> EnemyDefinition:
	if enemy_definitions.is_empty():
		return null
	var template := enemy_definitions[enemy_index % enemy_definitions.size()] as EnemyDefinition
	return template


func _get_enemy_positions(enemy_count: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []
	match enemy_count:
		2:
			positions = [
				Vector2(ENEMY_LEFT_X, ENEMY_MIDDLE_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_MIDDLE_Y),
			]
		4:
			positions = [
				Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_TOP_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_LEFT_X, ENEMY_TOP_Y),
			]
		_:
			positions = [
				Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
				Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y),
				Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
			]
	return positions


func _create_digestion_timer() -> void:
	digestion_timer = Timer.new()
	digestion_timer.name = "AutoDigestionTimer"
	digestion_timer.wait_time = DIGEST_AUTO_INTERVAL
	digestion_timer.one_shot = false
	digestion_timer.timeout.connect(_on_digestion_timer_timeout)
	add_child(digestion_timer)


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
	_setup_enemies()
	input_controller.setup(enemies)
	_refresh_ui()


func _try_start_digesting(enemy: Enemy, mouse_position: Vector2) -> void:
	var next_fullness := stomach.get_current_fullness(enemies)
	if not dragged_enemy_was_digesting:
		next_fullness += enemy.get_size()
	if next_fullness > stomach.get_capacity():
		_return_dragged_enemy(enemy)
		_set_status_message("胃袋がいっぱいで置けません")
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
	hp = maxi(0, hp - _get_remove_from_stomach_damage())
	_set_status_message("悪夢を外したのでダメージを受けました")


func _advance_digest_turn() -> void:
	if digest_turn_in_progress:
		return
	digest_turn_in_progress = true
	if _active_digest_count() == 0:
		auto_digest_enabled = false
		_set_status_message("消化中の悪夢がありません")
		digest_turn_in_progress = false
		return
	_apply_turn_start_effects()
	var elapsed_minutes := _get_step_minutes()
	var digested_enemies := _digest_nightmares()
	_apply_digest_damage()
	if not digested_enemies.is_empty():
		await get_tree().create_timer(Enemy.DIGESTED_TWEEN_DURATION).timeout
		stomach.apply_gravity(enemies)
	minutes += elapsed_minutes
	if hp <= 0:
		hp = _get_rest_hp()
		minutes += REST_MINUTES
		elapsed_minutes += REST_MINUTES
		_set_status_message("HPが尽きたため休憩しました")
	else:
		_set_status_message("")
	ui.show_time_elapsed(elapsed_minutes)
	_check_battle_end()
	_update_auto_digest_timer()
	_activate_deferred_nuisance_enemies()
	digest_turn_in_progress = false


func _digest_nightmares() -> Array[Enemy]:
	var digested_enemies: Array[Enemy] = []
	var shared_damage: Dictionary = {}
	var received_digest_damage: Dictionary = {}
	var digest_damage_per_cell := _get_digest_damage_per_cell()
	for enemy in enemies:
		if not enemy.can_take_stomach_turn():
			continue
		var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
		if bottom_cell_count == 0:
			continue
		var damage := digest_damage_per_cell * bottom_cell_count
		received_digest_damage[enemy] = received_digest_damage.get(enemy, 0) + damage
		_apply_digest_damage_share(enemy, damage, shared_damage)
		if enemy.take_digest_damage(damage):
			digested_enemies.append(enemy)
		_apply_digest_heal_reaction(enemy)
		enemy.pulse_cost_label()
	for target in shared_damage.keys():
		var target_enemy := target as Enemy
		if target_enemy == null or target_enemy.digested:
			continue
		received_digest_damage[target_enemy] = received_digest_damage.get(target_enemy, 0) + shared_damage[target]
		if target_enemy.take_digest_damage(shared_damage[target]) and not digested_enemies.has(target_enemy):
			digested_enemies.append(target_enemy)
	return _resolve_digested_enemy_effects(digested_enemies, received_digest_damage)


func _apply_digest_damage() -> void:
	var damage := 0
	for enemy in enemies:
		if enemy.can_take_stomach_turn():
			damage += _get_enemy_attack_damage(enemy)
	_take_player_damage(damage)


func _apply_turn_start_effects() -> void:
	for enemy in enemies:
		if enemy.digested:
			continue
		if enemy.can_take_stomach_turn():
			enemy.stomach_elapsed_minutes += STEP_MINUTES
		if _has_nightmare_effect(enemy, 7) and not enemy.is_active_in_stomach():
			var next_multiplier := enemy.attack_multiplier
			if randi() % 2 == 0:
				next_multiplier -= 0.2
			else:
				next_multiplier += 0.2
			enemy.set_attack_multiplier(clampf(next_multiplier, 0.0, 2.0))


func _get_digest_damage_per_cell() -> int:
	var breakdown := _get_digest_damage_breakdown(true)
	return int(breakdown["total"])


func _get_digest_damage_breakdown(consume_pending_bonus: bool = false) -> Dictionary:
	var seed_rate := _get_dream_seed_digest_damage_rate()
	if next_digest_damage_bonus_rate > 0.0:
		seed_rate += next_digest_damage_bonus_rate
	if consume_pending_bonus:
		next_digest_damage_bonus_rate = 0.0
	var base_damage := DIGEST_DAMAGE
	var seed_buff := roundi(float(base_damage) * seed_rate)
	var damage_after_seed := base_damage + seed_buff
	var nightmare_rate := _get_nightmare_digest_damage_rate()
	var total_damage := maxi(1, roundi(float(damage_after_seed) * (1.0 + nightmare_rate)))
	var nightmare_buff := total_damage - damage_after_seed
	return {
		"total": total_damage,
		"base": base_damage,
		"seed_buff": seed_buff,
		"seed_rate": seed_rate,
		"nightmare_buff": nightmare_buff,
		"nightmare_rate": nightmare_rate,
	}


func _get_nightmare_digest_damage_rate() -> float:
	if not _has_active_nightmare_effect(5) or minutes < 25 * 60:
		return 0.0
	var passed_hours := maxi(0, floori(float(minutes - 25 * 60) / 60.0))
	var reduction := 0.3 + float(passed_hours) * 0.05
	return -minf(0.9, reduction)


func _get_step_minutes() -> int:
	var step_minutes := STEP_MINUTES
	for enemy in enemies:
		if _has_nightmare_effect(enemy, 6) and enemy.stomach_elapsed_minutes > 0 and enemy.stomach_elapsed_minutes % 60 == 0:
			step_minutes += 30
	var time_rate := 1.0 - _get_dream_seed_time_reduction_rate()
	return maxi(1, roundi(float(step_minutes) * time_rate))


func _get_enemy_attack_damage(enemy: Enemy) -> int:
	var damage := enemy.get_damage()
	if _has_nightmare_effect(enemy, 1):
		damage = roundi(float(damage) * maxf(0.0, 1.0 - float(_get_adjacent_enemies(enemy).size()) * 0.25))
	if _has_nightmare_effect(enemy, 4):
		var bottom_cells := stomach.get_bottom_row_cell_count(enemy)
		var upper_cells := maxi(0, enemy.get_size() - bottom_cells)
		damage = roundi(float(damage) * maxf(0.0, 1.0 + float(bottom_cells - upper_cells) * 0.2))
	return damage


func _take_player_damage(amount: int) -> void:
	if amount <= 0:
		return
	var final_damage := maxi(0, roundi(float(amount) * _get_dream_seed_player_damage_multiplier()))
	hp -= final_damage
	next_digest_damage_bonus_rate += _get_dream_seed_reflect_digest_rate(final_damage)


func _apply_digest_damage_share(enemy: Enemy, damage: int, shared_damage: Dictionary) -> void:
	if _has_nightmare_effect(enemy, 2):
		var adjacent_enemies := _get_adjacent_enemies(enemy)
		if not adjacent_enemies.is_empty():
			var split_damage := maxi(1, roundi(float(damage) * 0.4 / float(adjacent_enemies.size())))
			for adjacent_enemy in adjacent_enemies:
				shared_damage[adjacent_enemy] = shared_damage.get(adjacent_enemy, 0) + split_damage


func _apply_digest_heal_reaction(enemy: Enemy) -> void:
	if _has_nightmare_effect(enemy, 3) and not enemy.digested:
		var heal_rate := minf(1.0, float(_get_open_side_count(enemy)) * 0.1)
		enemy.heal(roundi(float(enemy.max_hp) * heal_rate))


func _resolve_digested_enemy_effects(digested_enemies: Array[Enemy], received_digest_damage: Dictionary) -> Array[Enemy]:
	var final_digested: Array[Enemy] = []
	for enemy in digested_enemies:
		digest_order += 1
		if _has_nightmare_effect(enemy, 10) and digest_order % 2 == 1:
			_take_player_damage(enemy.get_damage() * 3)
		if _has_nightmare_effect(enemy, 11) and digest_order % 2 == 0 and not enemy.revive_used:
			enemy.revive_with_half_hp()
			continue
		final_digested.append(enemy)
	_apply_chain_reactions(final_digested)
	_apply_spawn_reactions(final_digested, received_digest_damage)
	return final_digested


func _apply_chain_reactions(digested_enemies: Array[Enemy]) -> void:
	for watcher in enemies:
		if not _has_nightmare_effect(watcher, 9) or watcher.digested:
			continue
		for digested_enemy in digested_enemies:
			if watcher == digested_enemy:
				continue
			watcher.change_max_hp(roundi(float(watcher.max_hp) * 0.9))
			watcher.add_damage(roundi(float(digested_enemy.get_damage()) * 0.5))


func _apply_spawn_reactions(digested_enemies: Array[Enemy], received_digest_damage: Dictionary) -> void:
	for enemy in digested_enemies:
		if _has_nightmare_effect(enemy, 8):
			var nuisance_damage := roundi(float(received_digest_damage.get(enemy, 0)) * 0.2)
			for cell in enemy.get_occupied_cells(enemy.stomach_cell):
				if not _spawn_nuisance_nightmare(enemy, cell, 0.2, nuisance_damage):
					break
		if _has_nightmare_effect(enemy, 12) and digested_enemies.size() == 1:
			var spawn_cells := enemy.get_occupied_cells(enemy.stomach_cell)
			if not spawn_cells.is_empty():
				_spawn_nuisance_nightmare(enemy, spawn_cells[0], 0.3, 0)


func _spawn_nuisance_nightmare(source_enemy: Enemy, spawn_cell: Vector2i, hp_rate: float, damage_value: int) -> bool:
	var nuisance_enemy := _get_available_nuisance_enemy(source_enemy)
	if nuisance_enemy == null:
		return false
	var source_definition := source_enemy.definition
	var source_origin_position := source_enemy.origin_position
	var source_max_hp := source_enemy.max_hp
	nuisance_enemy.setup(
		source_definition,
		Vector2.ONE * stomach.get_span_size(1),
		null,
		false,
		source_origin_position
	)
	nuisance_enemy.setup_as_one_cell_stomach_block(Vector2.ONE * stomach.get_span_size(1))
	nuisance_enemy.change_max_hp(maxi(1, roundi(float(source_max_hp) * hp_rate)))
	nuisance_enemy.current_hp = nuisance_enemy.max_hp
	nuisance_enemy.set_damage_value(maxi(0, damage_value))
	nuisance_enemy.set_digesting(true)
	stomach.place_enemy(nuisance_enemy, spawn_cell)
	return true


func _get_available_nuisance_enemy(source_enemy: Enemy) -> Enemy:
	for enemy in enemies:
		if enemy.visible or not enemy.digested:
			continue
		return enemy
	if source_enemy.digested:
		return source_enemy
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	add_child(enemy)
	enemies.append(enemy)
	input_controller.setup(enemies)
	return enemy


func _activate_deferred_nuisance_enemies() -> void:
	for enemy in enemies:
		enemy.activate_stomach_turn()


func _has_nightmare_effect(enemy: Enemy, skill_id: int) -> bool:
	return enemy.has_main_effect and enemy.skill_definition != null and enemy.skill_definition.skill_id == skill_id


func _has_active_nightmare_effect(skill_id: int) -> bool:
	for enemy in enemies:
		if _has_nightmare_effect(enemy, skill_id) and not enemy.digested:
			return true
	return false


func _get_adjacent_enemies(enemy: Enemy) -> Array[Enemy]:
	var adjacent_enemies: Array[Enemy] = []
	if not enemy.is_active_in_stomach():
		return adjacent_enemies
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		if _are_enemies_adjacent(enemy, other):
			adjacent_enemies.append(other)
	return adjacent_enemies


func _are_enemies_adjacent(enemy: Enemy, other: Enemy) -> bool:
	var other_cells := other.get_occupied_cells(other.stomach_cell)
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if other_cells.has(cell + Vector2i(-1, 0)) or other_cells.has(cell + Vector2i(1, 0)):
			return true
		if other_cells.has(cell + Vector2i(0, -1)) or other_cells.has(cell + Vector2i(0, 1)):
			return true
	return false


func _get_open_side_count(enemy: Enemy) -> int:
	var open_side_count := 0
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if not _has_adjacent_enemy_in_direction(enemy, direction):
			open_side_count += 1
	return open_side_count


func _has_adjacent_enemy_in_direction(enemy: Enemy, direction: Vector2i) -> bool:
	var occupied_cells := enemy.get_occupied_cells(enemy.stomach_cell)
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		var other_cells := other.get_occupied_cells(other.stomach_cell)
		for cell in occupied_cells:
			if other_cells.has(cell + direction):
				return true
	return false


func _get_dream_seed_digest_damage_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 1 and skill.category == "夢の花系統":
			rate += 0.1
		if skill.skill_id == 5 and skill.category == "反射系統":
			rate += 0.1
		if skill.skill_id == 4 and skill.category == "時間系統" and minutes >= 27 * 60:
			rate += 2.0
	return rate


func _get_dream_seed_player_damage_multiplier() -> float:
	var multiplier := 1.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 2 and skill.category == "反射系統":
			multiplier += 0.3
	return multiplier


func _get_dream_seed_reflect_digest_rate(taken_damage: int) -> float:
	if taken_damage <= 0:
		return 0.0
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 2 and skill.category == "反射系統":
			rate += float(taken_damage) * 0.3 / float(DIGEST_DAMAGE)
	return rate


func _get_dream_seed_time_reduction_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 3 and skill.category == "夢の花系統":
			rate += 0.05
	return minf(0.2, rate)


func _get_planted_seed_skills() -> Array[DreamSeedSkillDefinition]:
	var skills: Array[DreamSeedSkillDefinition] = []
	for flower in planted_flowers:
		if flower != null and flower.dream_seed_skill != null:
			skills.append(flower.dream_seed_skill)
	return skills


func _get_tooltip_debug_number_text(enemy: Enemy) -> String:
	return "悪夢:%s\n種:%s" % [_get_enemy_skill_id_text(enemy), _get_seed_skill_id_text()]


func _get_enemy_skill_id_text(enemy: Enemy) -> String:
	if enemy.skill_definition == null:
		return "-"
	return str(enemy.skill_definition.skill_id)


func _get_seed_skill_id_text() -> String:
	var seed_ids: Array[String] = []
	for flower in planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		seed_ids.append(str(flower.dream_seed_skill.skill_id))
	if seed_ids.is_empty():
		return "-"
	return ",".join(seed_ids)


func _check_battle_end() -> void:
	if _all_enemies_digested():
		battle_active = false
		input_controller.set_active(false)
		auto_digest_enabled = false
		_update_auto_digest_timer()
		_set_status_message("すべての悪夢を消化しました")
		battle_finished.emit(true)
		return
	if minutes >= END_HOUR * 60:
		battle_active = false
		input_controller.set_active(false)
		auto_digest_enabled = false
		_update_auto_digest_timer()
		_set_status_message("朝までに消化しきれませんでした")
		battle_finished.emit(false)


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


func _get_rest_hp() -> int:
	var recovery_rate := REST_HP_RATE + _get_dream_seed_rest_recovery_bonus_rate()
	if rest_recovery_bonus_rate > 0.0:
		rest_recovery_bonus_rate = maxf(0.0, rest_recovery_bonus_rate - 0.1)
	return ceili(float(MAX_HP) * recovery_rate)


func _get_dream_seed_rest_recovery_bonus_rate() -> float:
	if rest_recovery_bonus_rate > 0.0:
		return rest_recovery_bonus_rate
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 4 and skill.category == "夢の花系統":
			rest_recovery_bonus_rate = 0.5
			return rest_recovery_bonus_rate
	return 0.0


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


func _set_status_message(message: String) -> void:
	ui.set_message(START_MESSAGE)
	ui.set_debug_message(message)
	_refresh_ui()


func _play_click_se() -> void:
	if click_se == null:
		return
	click_se.stop()
	click_se.play()


func _refresh_ui() -> void:
	var digest_damage := _get_digest_damage_breakdown()
	ui.set_digest_damage_info(
		int(digest_damage["total"]),
		int(digest_damage["base"]),
		int(digest_damage["seed_buff"]),
		float(digest_damage["seed_rate"]),
		int(digest_damage["nightmare_buff"]),
		float(digest_damage["nightmare_rate"])
	)
	ui.set_hp(hp, MAX_HP)
	ui.set_time(minutes)
	ui.set_digestion_count(_active_digest_count())
	ui.set_digestion_button_visible(battle_active and not auto_digest_enabled)


func get_current_hp() -> int:
	return hp


func get_clear_minutes() -> int:
	return minutes


func get_max_hp() -> int:
	return MAX_HP
