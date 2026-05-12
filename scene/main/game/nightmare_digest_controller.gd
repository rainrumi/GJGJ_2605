class_name NightmareDigestController
extends RefCounted

const STEP_MINUTES := 30
const DIGEST_DAMAGE := 200
const SKILL_7_HP_STEP_RATE := 0.2
const SKILL_7_MIN_HP_RATE := 0.2
const SKILL_7_MAX_HP_RATE := 2.0

var seed_effects := DreamSeedEffectCalculator.new()
var digest_order := 0
var _pending_player_damage_values: Array[int] = []
var _skill_7_base_hp: Dictionary = {}
var _skill_7_hp_rate: Dictionary = {}


func setup(flowers: Array) -> void:
	digest_order = 0
	_pending_player_damage_values.clear()
	_skill_7_base_hp.clear()
	_skill_7_hp_rate.clear()
	seed_effects.setup(flowers)


func reset_digest_order() -> void:
	digest_order = 0
	_skill_7_base_hp.clear()
	_skill_7_hp_rate.clear()


func get_digest_damage_breakdown(
	enemies: Array[Enemy],
	minutes: int,
	consume_pending_bonus: bool = false
) -> Dictionary:
	return seed_effects.get_digest_damage_breakdown(
		DIGEST_DAMAGE,
		_get_nightmare_digest_damage_rate(enemies, minutes),
		minutes,
		consume_pending_bonus
	)


func get_step_minutes(enemies: Array[Enemy]) -> int:
	var step_minutes := STEP_MINUTES
	for enemy in enemies:
		if _has_nightmare_effect(enemy, 6) and enemy.stomach_elapsed_minutes > 0 and enemy.stomach_elapsed_minutes % 60 == 0:
			step_minutes += 30
	var time_rate := 1.0 - seed_effects.get_time_reduction_rate()
	return maxi(1, roundi(float(step_minutes) * time_rate))


func apply_turn_start_effects(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy.digested:
			continue
		if enemy.can_take_stomach_turn():
			enemy.stomach_elapsed_minutes += STEP_MINUTES
		if _has_nightmare_effect(enemy, 7) and not enemy.is_active_in_stomach():
			_apply_outside_stomach_hp_variation(enemy)


func digest_nightmares(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	enemy_setup: GameEnemySetupController
) -> Array[Enemy]:
	var digested_enemies: Array[Enemy] = []
	var shared_damage: Dictionary = {}
	var received_digest_damage: Dictionary = {}
	var digest_damage_per_cell := int(get_digest_damage_breakdown(enemies, minutes, true)["total"])
	for enemy in enemies:
		_digest_enemy(enemy, enemies, stomach, digest_damage_per_cell, shared_damage, received_digest_damage, digested_enemies)
	_apply_shared_damage(shared_damage, received_digest_damage, digested_enemies)
	return _resolve_digested_enemy_effects(enemies, digested_enemies, received_digest_damage, enemy_setup)


func apply_digest_damage_values(enemies: Array[Enemy], stomach: StomachBoard) -> Array[int]:
	var raw_damage_values: Array[int] = []
	var total_damage := 0
	for enemy in enemies:
		if enemy.can_take_stomach_turn():
			var damage := _get_enemy_attack_damage(enemy, enemies, stomach)
			if damage > 0:
				raw_damage_values.append(damage)
				total_damage += damage
	var final_damage := seed_effects.apply_player_damage(total_damage, DIGEST_DAMAGE)
	var damage_values := _split_damage_values(raw_damage_values, final_damage)
	damage_values.append_array(consume_pending_player_damage_values())
	return damage_values


func refresh_enemy_status_display(enemies: Array[Enemy], stomach: StomachBoard) -> void:
	for enemy in enemies:
		if enemy == null or enemy.digested:
			continue
		enemy.set_display_damage(_get_enemy_attack_damage(enemy, enemies, stomach))


func get_rest_hp(max_hp: int, rest_hp_rate: float) -> int:
	return seed_effects.get_rest_hp(max_hp, rest_hp_rate)


func activate_deferred_nuisance_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		enemy.activate_stomach_turn()


func has_active_nightmare_effect(enemies: Array[Enemy], skill_id: int) -> bool:
	for enemy in enemies:
		if _has_nightmare_effect(enemy, skill_id) and not enemy.digested:
			return true
	return false


func get_seed_skill_id_text() -> String:
	return seed_effects.get_seed_skill_id_text()


func apply_direct_player_damage(amount: int) -> int:
	return seed_effects.apply_player_damage(amount, DIGEST_DAMAGE)


func consume_pending_player_damage_values() -> Array[int]:
	var damage_values: Array[int] = []
	damage_values.append_array(_pending_player_damage_values)
	_pending_player_damage_values.clear()
	return damage_values


func _digest_enemy(
	enemy: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	digest_damage_per_cell: int,
	shared_damage: Dictionary,
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	if not enemy.can_take_stomach_turn():
		return
	var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
	if bottom_cell_count == 0:
		return
	var damage := digest_damage_per_cell * bottom_cell_count
	received_digest_damage[enemy] = received_digest_damage.get(enemy, 0) + damage
	_apply_digest_damage_share(enemy, enemies, damage, shared_damage)
	if enemy.take_digest_damage(damage):
		digested_enemies.append(enemy)
	_apply_digest_heal_reaction(enemy, enemies)
	enemy.pulse_cost_label()


func _apply_shared_damage(
	shared_damage: Dictionary,
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	for target in shared_damage.keys():
		var target_enemy := target as Enemy
		if target_enemy == null or target_enemy.digested:
			continue
		received_digest_damage[target_enemy] = received_digest_damage.get(target_enemy, 0) + shared_damage[target]
		if target_enemy.take_digest_damage(shared_damage[target]) and not digested_enemies.has(target_enemy):
			digested_enemies.append(target_enemy)


func _resolve_digested_enemy_effects(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	enemy_setup: GameEnemySetupController
) -> Array[Enemy]:
	var final_digested: Array[Enemy] = []
	for enemy in digested_enemies:
		digest_order += 1
		if _has_nightmare_effect(enemy, 10) and digest_order % 2 == 1:
			var damage := seed_effects.apply_player_damage(enemy.get_damage() * 3, DIGEST_DAMAGE)
			if damage > 0:
				_pending_player_damage_values.append(damage)
		if _has_nightmare_effect(enemy, 11) and digest_order % 2 == 0 and not enemy.revive_used:
			enemy.revive_with_half_hp()
			continue
		final_digested.append(enemy)
	_apply_chain_reactions(enemies, final_digested)
	_apply_spawn_reactions(enemies, final_digested, received_digest_damage, enemy_setup)
	return final_digested


func _apply_chain_reactions(enemies: Array[Enemy], digested_enemies: Array[Enemy]) -> void:
	for watcher in enemies:
		if not _has_nightmare_effect(watcher, 9) or watcher.digested:
			continue
		for digested_enemy in digested_enemies:
			if watcher == digested_enemy:
				continue
			watcher.change_max_hp(roundi(float(watcher.max_hp) * 0.9))
			watcher.add_damage(roundi(float(digested_enemy.get_damage()) * 0.5))


func _apply_spawn_reactions(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	enemy_setup: GameEnemySetupController
) -> void:
	for enemy in digested_enemies:
		if _has_nightmare_effect(enemy, 8):
			var nuisance_damage := roundi(float(received_digest_damage.get(enemy, 0)) * 0.2)
			for cell in enemy.get_occupied_cells(enemy.stomach_cell):
				if not enemy_setup.spawn_nuisance_nightmare(enemies, enemy, cell, 0.2, nuisance_damage):
					break
		if _has_nightmare_effect(enemy, 12) and digested_enemies.size() == 1:
			var spawn_cells := enemy.get_occupied_cells(enemy.stomach_cell)
			if not spawn_cells.is_empty():
				enemy_setup.spawn_nuisance_nightmare(enemies, enemy, spawn_cells[0], 0.3, 0)


func _get_enemy_attack_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> int:
	var damage := enemy.get_damage()
	if _has_nightmare_effect(enemy, 1):
		var adjacent_count := NightmarePlacementQuery.get_adjacent_enemies(enemy, enemies).size()
		damage = roundi(float(damage) * maxf(0.0, 1.0 - float(adjacent_count) * 0.25))
	if _has_nightmare_effect(enemy, 4) and enemy.is_active_in_stomach():
		var bottom_cells := stomach.get_bottom_row_cell_count(enemy)
		var upper_cells := maxi(0, enemy.get_size() - bottom_cells)
		damage = roundi(float(damage) * maxf(0.0, 1.0 + float(bottom_cells - upper_cells) * 0.2))
	return damage


func _apply_digest_damage_share(
	enemy: Enemy,
	enemies: Array[Enemy],
	damage: int,
	shared_damage: Dictionary
) -> void:
	if not _has_nightmare_effect(enemy, 2):
		return
	var adjacent_enemies := NightmarePlacementQuery.get_adjacent_enemies(enemy, enemies)
	if adjacent_enemies.is_empty():
		return
	var split_damage := maxi(1, roundi(float(damage) * 0.4 / float(adjacent_enemies.size())))
	for adjacent_enemy in adjacent_enemies:
		shared_damage[adjacent_enemy] = shared_damage.get(adjacent_enemy, 0) + split_damage


func _apply_digest_heal_reaction(enemy: Enemy, enemies: Array[Enemy]) -> void:
	if _has_nightmare_effect(enemy, 3) and not enemy.digested:
		var open_sides := NightmarePlacementQuery.get_open_side_count(enemy, enemies)
		enemy.heal(roundi(float(enemy.max_hp) * minf(1.0, float(open_sides) * 0.1)))


func _apply_outside_stomach_hp_variation(enemy: Enemy) -> void:
	if not _skill_7_base_hp.has(enemy):
		_skill_7_base_hp[enemy] = enemy.max_hp
		_skill_7_hp_rate[enemy] = 1.0
	var next_rate := float(_skill_7_hp_rate[enemy])
	if randi() % 2 == 0:
		next_rate += SKILL_7_HP_STEP_RATE
	else:
		next_rate -= SKILL_7_HP_STEP_RATE
	next_rate = clampf(next_rate, SKILL_7_MIN_HP_RATE, SKILL_7_MAX_HP_RATE)
	_skill_7_hp_rate[enemy] = next_rate
	var next_max_hp := maxi(1, roundi(float(int(_skill_7_base_hp[enemy])) * next_rate))
	var hp_delta := next_max_hp - enemy.max_hp
	enemy.set_hp_values(next_max_hp, maxi(1, enemy.current_hp + hp_delta))


func _split_damage_values(raw_damage_values: Array[int], final_damage: int) -> Array[int]:
	var damage_values: Array[int] = []
	if raw_damage_values.is_empty() or final_damage <= 0:
		return damage_values
	var raw_total := 0
	for damage in raw_damage_values:
		raw_total += damage
	var assigned_damage := 0
	var cumulative_raw_damage := 0
	for damage in raw_damage_values:
		cumulative_raw_damage += damage
		var cumulative_damage := roundi(float(cumulative_raw_damage) / float(raw_total) * float(final_damage))
		var split_damage := maxi(0, cumulative_damage - assigned_damage)
		if split_damage > 0:
			damage_values.append(split_damage)
		assigned_damage = cumulative_damage
	return damage_values


func _get_nightmare_digest_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	if not has_active_nightmare_effect(enemies, 5) or minutes < 25 * 60:
		return 0.0
	var passed_hours := maxi(0, floori(float(minutes - 25 * 60) / 60.0))
	return -minf(0.9, 0.3 + float(passed_hours) * 0.05)


func _has_nightmare_effect(enemy: Enemy, skill_id: int) -> bool:
	return enemy.has_main_effect and enemy.skill_definition != null and enemy.skill_definition.skill_id == skill_id
