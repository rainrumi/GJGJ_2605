class_name NightmareDigestController
extends RefCounted

const STEP_MINUTES := 30
const DIGEST_DAMAGE := 300
const SKILL_3_DAMAGE_REDUCTION_PER_OPEN_FACE := 0.1
const SKILL_7_HP_STEP_RATE := 0.2
const SKILL_7_MIN_HP_RATE := 0.2
const SKILL_7_MAX_HP_RATE := 2.0
const SKILL_11_REVIVE_START_RATE := 0.5
const SKILL_11_REVIVE_DECAY_RATE := 0.1
const SKILL_11_MIN_REVIVE_RATE := 0.1
const NIGHTMARE_SKILL_OPEN_CELL_ATTACK := 1
const NIGHTMARE_SKILL_DAMAGE_SHARE := 2
const NIGHTMARE_SKILL_OPEN_CELL_DEFENSE := 3
const NIGHTMARE_SKILL_BOTTOM_ATTACK := 4
const NIGHTMARE_SKILL_LATE_DIGEST_WEAKEN := 5
const NIGHTMARE_SKILL_TIME_DELAY := 6
const NIGHTMARE_SKILL_RANDOM_HP := 7
const NIGHTMARE_SKILL_SPAWN_BLOCKS := 8
const NIGHTMARE_SKILL_CHAIN_GROWTH := 9
const NIGHTMARE_SKILL_ODD_ORDER_DAMAGE := 10
const NIGHTMARE_SKILL_EVEN_ORDER_REVIVE := 11
const NIGHTMARE_SKILL_SINGLE_DIGEST_SPAWN := 12
const DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE := 2002
const DREAM_SEED_RARE_LATE_DIGEST_DAMAGE := 2004
const DREAM_SEED_RARE_ADJACENT_DAMAGE_UP := 2005
const SEED_BLOCK_LATE_DIGEST_DAMAGE_RATE := 1.0
const SEED_BLOCK_LATE_DIGEST_DAMAGE_START_HOUR := 28

var seed_effects := DreamSeedEffectCalculator.new()
var digest_order := 0
var _pending_player_damage_values: Array[int] = []
var _skill_7_base_hp: Dictionary = {}
var _skill_7_hp_rate: Dictionary = {}
var _beat_conductor: BeatConductor


func setup(flowers: Array) -> void:
	digest_order = 0
	_pending_player_damage_values.clear()
	_skill_7_base_hp.clear()
	_skill_7_hp_rate.clear()
	seed_effects.setup(flowers)


func set_seed_effect_flowers(flowers: Array) -> void:
	seed_effects.setup(flowers)


func set_beat_conductor(beat_conductor: BeatConductor) -> void:
	_beat_conductor = beat_conductor


func clear_scheduled_events() -> void:
	if _beat_conductor != null and is_instance_valid(_beat_conductor):
		_beat_conductor.clear_scheduled_events()


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
		_get_nightmare_digest_damage_rate(enemies, minutes) + _get_seed_block_digest_damage_rate(enemies, minutes),
		minutes,
		consume_pending_bonus
	)


func get_step_minutes(enemies: Array[Enemy]) -> int:
	return int(get_step_minutes_breakdown(enemies, true)["total"])


func get_step_minutes_breakdown(enemies: Array[Enemy], consume_pending_bonus := false) -> Dictionary:
	var base_minutes := STEP_MINUTES
	var nightmare_minutes := base_minutes
	for enemy in enemies:
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_TIME_DELAY) and enemy.stomach_elapsed_minutes > 0 and enemy.stomach_elapsed_minutes % 60 == 0:
			nightmare_minutes += 30
	var seed_rate := -seed_effects.get_time_reduction_rate(consume_pending_bonus)
	var total_minutes := maxi(1, roundi(float(nightmare_minutes) * (1.0 + seed_rate)))
	return {
		"total": total_minutes,
		"base": base_minutes,
		"seed_buff": total_minutes - nightmare_minutes,
		"seed_rate": seed_rate,
		"nightmare_buff": nightmare_minutes - base_minutes,
		"nightmare_rate": float(nightmare_minutes - base_minutes) / float(base_minutes),
	}


func apply_turn_start_effects(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy.digested:
			continue
		if enemy.can_take_stomach_turn():
			enemy.stomach_elapsed_minutes += STEP_MINUTES
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_RANDOM_HP) and not enemy.is_active_in_stomach():
			_apply_outside_stomach_hp_variation(enemy)


func digest_nightmares(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	enemy_setup: GameEnemySetupController
) -> Array[Enemy]:
	var digested_enemies: Array[Enemy] = []
	var shared_damage: Dictionary = {}
	var damage_display_values: Dictionary = {}
	var received_digest_damage: Dictionary = {}
	var turn_start_hp := _get_turn_start_hp(enemies)
	var digest_damage_per_cell := int(get_digest_damage_breakdown(enemies, minutes, true)["total"])
	for enemy in enemies:
		_digest_enemy(enemy, enemies, stomach, digest_damage_per_cell, shared_damage, damage_display_values, received_digest_damage)
	_apply_shared_damage(shared_damage, enemies, stomach, damage_display_values, received_digest_damage)
	_apply_enemy_damage_values(damage_display_values, digested_enemies)
	return _resolve_digested_enemy_effects(enemies, digested_enemies, received_digest_damage, turn_start_hp, enemy_setup)


func apply_digest_damage_values(enemies: Array[Enemy], stomach: StomachBoard) -> Array[int]:
	var raw_damage_values: Array[int] = []
	var total_damage := 0
	for enemy in enemies:
		if enemy.should_deal_player_damage() and enemy.can_take_stomach_turn():
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


func get_rest_recovery_bonus_rate() -> float:
	return seed_effects.get_rest_recovery_bonus_rate()


func activate_deferred_nuisance_enemies(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		enemy.activate_stomach_turn()


func unlock_deferred_nuisance_gravity(enemies: Array[Enemy]) -> void:
	for enemy in enemies:
		if enemy.is_active_in_stomach() and enemy.activation_deferred:
			enemy.clear_gravity_lock()


func has_active_nightmare_effect(enemies: Array[Enemy], skill_id: int) -> bool:
	for enemy in enemies:
		if _has_nightmare_effect(enemy, skill_id) and not enemy.digested:
			return true
	return false


func get_seed_skill_id_text() -> String:
	return seed_effects.get_seed_skill_id_text()


func apply_direct_player_damage(amount: int) -> int:
	return seed_effects.apply_player_damage(amount, DIGEST_DAMAGE)


func add_digested_seed_effect(seed_skill: DreamSeedSkillDefinition) -> bool:
	return seed_effects.add_digested_seed_effect(seed_skill)


func wait_for_next_beat() -> void:
	await _wait_for_next_beat()


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
	damage_display_values: Dictionary,
	received_digest_damage: Dictionary
) -> void:
	if not enemy.can_take_stomach_turn():
		return
	var bottom_cell_count := stomach.get_bottom_row_cell_count(enemy)
	if bottom_cell_count == 0:
		return
	var damage := _get_final_digest_damage(enemy, enemies, stomach, digest_damage_per_cell * bottom_cell_count)
	received_digest_damage[enemy] = received_digest_damage.get(enemy, 0) + damage
	_append_damage_value(damage_display_values, enemy, damage)
	_apply_digest_damage_share(enemy, enemies, damage, shared_damage)


func _apply_shared_damage(
	shared_damage: Dictionary,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	damage_display_values: Dictionary,
	received_digest_damage: Dictionary
) -> void:
	for target in shared_damage.keys():
		var target_enemy := target as Enemy
		if target_enemy == null or target_enemy.digested:
			continue
		var damage_values: Array = shared_damage[target]
		var total_damage := _sum_damage_values(damage_values)
		total_damage = _get_final_digest_damage(target_enemy, enemies, stomach, total_damage)
		received_digest_damage[target_enemy] = received_digest_damage.get(target_enemy, 0) + total_damage
		_append_damage_value(damage_display_values, target_enemy, total_damage)


func _resolve_digested_enemy_effects(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	turn_start_hp: Dictionary,
	enemy_setup: GameEnemySetupController
) -> Array[Enemy]:
	var final_digested: Array[Enemy] = []
	_sort_digested_enemies(enemies, digested_enemies, received_digest_damage, turn_start_hp)
	for enemy in digested_enemies:
		digest_order += 1
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_ODD_ORDER_DAMAGE) and digest_order % 2 == 1:
			var damage := seed_effects.apply_player_damage(enemy.get_damage() * 3, DIGEST_DAMAGE)
			if damage > 0:
				_pending_player_damage_values.append(damage)
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_EVEN_ORDER_REVIVE) and digest_order % 2 == 0:
			var revive_rate := maxf(
				SKILL_11_MIN_REVIVE_RATE,
				SKILL_11_REVIVE_START_RATE - float(enemy.revive_count) * SKILL_11_REVIVE_DECAY_RATE
			)
			enemy.revive_with_hp_rate(revive_rate)
			continue
		_apply_seed_block_digested_effect(enemy, enemies, received_digest_damage, digested_enemies)
		final_digested.append(enemy)
	_apply_chain_reactions(enemies, final_digested)
	_apply_spawn_reactions(enemies, final_digested, received_digest_damage, enemy_setup)
	return final_digested


func _sort_digested_enemies(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	turn_start_hp: Dictionary
) -> void:
	digested_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		var a_surplus := int(received_digest_damage.get(a, 0)) - int(turn_start_hp.get(a, 0))
		var b_surplus := int(received_digest_damage.get(b, 0)) - int(turn_start_hp.get(b, 0))
		if a_surplus == b_surplus:
			return enemies.find(a) < enemies.find(b)
		return a_surplus > b_surplus
	)


func _apply_chain_reactions(enemies: Array[Enemy], digested_enemies: Array[Enemy]) -> void:
	for watcher in enemies:
		if not _has_nightmare_effect(watcher, NIGHTMARE_SKILL_CHAIN_GROWTH) or watcher.digested:
			continue
		for digested_enemy in digested_enemies:
			if watcher == digested_enemy:
				continue
			watcher.change_max_hp(roundi(float(watcher.max_hp) * 0.9))
			watcher.add_damage(roundi(float(watcher.base_damage) * 0.5))


func _apply_spawn_reactions(
	enemies: Array[Enemy],
	digested_enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	enemy_setup: GameEnemySetupController
) -> void:
	for enemy in digested_enemies:
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SPAWN_BLOCKS):
			var nuisance_damage := roundi(float(enemy.base_damage) * 0.5)
			for cell in enemy.get_occupied_cells(enemy.stomach_cell):
				if not enemy_setup.spawn_nuisance_nightmare(enemies, enemy, cell, 0.5, nuisance_damage):
					break
		if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_SINGLE_DIGEST_SPAWN) and digested_enemies.size() == 1:
			var spawn_cells := enemy.get_occupied_cells(enemy.stomach_cell)
			if not spawn_cells.is_empty():
				enemy_setup.spawn_nuisance_nightmare(enemies, enemy, spawn_cells[0], 0.3, 0)


func _apply_seed_block_digested_effect(
	seed_block: Enemy,
	enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	if seed_block == null or seed_block.seed_skill_definition == null:
		return
	match seed_block.seed_skill_definition.skill_id:
		DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE, DREAM_SEED_RARE_ADJACENT_DAMAGE_UP:
			_apply_seed_block_adjacent_damage(seed_block, enemies, int(received_digest_damage.get(seed_block, 0)), digested_enemies)


func _apply_seed_block_adjacent_damage(
	seed_block: Enemy,
	enemies: Array[Enemy],
	damage: int,
	digested_enemies: Array[Enemy]
) -> void:
	if damage <= 0:
		return
	var adjacent_enemies := NightmarePlacementQuery.get_adjacent_enemies(seed_block, enemies)
	if adjacent_enemies.is_empty():
		return
	var split_damage := maxi(1, roundi(float(damage) / float(adjacent_enemies.size())))
	for adjacent_enemy in adjacent_enemies:
		if adjacent_enemy == seed_block or adjacent_enemy.digested:
			continue
		adjacent_enemy.show_digest_damage_values([split_damage])
		if adjacent_enemy.take_digest_damage(split_damage, false) and not digested_enemies.has(adjacent_enemy):
			digested_enemies.append(adjacent_enemy)


func _get_enemy_attack_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> int:
	var damage := enemy.get_damage()
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_OPEN_CELL_ATTACK):
		var open_adjacent_cells := NightmarePlacementQuery.get_open_adjacent_cell_count(enemy, enemies, stomach.columns, stomach.rows)
		damage += roundi(float(enemy.base_damage) * float(open_adjacent_cells))
	if _has_nightmare_effect(enemy, NIGHTMARE_SKILL_BOTTOM_ATTACK) and enemy.is_active_in_stomach():
		var bottom_cells := stomach.get_bottom_row_cell_count(enemy)
		var upper_cells := maxi(0, enemy.get_size() - bottom_cells)
		damage += roundi(float(enemy.base_damage) * float(bottom_cells - upper_cells) * 0.5)
	return damage


func _apply_digest_damage_share(
	enemy: Enemy,
	enemies: Array[Enemy],
	damage: int,
	shared_damage: Dictionary
) -> void:
	if not _has_nightmare_effect(enemy, NIGHTMARE_SKILL_DAMAGE_SHARE):
		return
	var adjacent_enemies := NightmarePlacementQuery.get_adjacent_enemies(enemy, enemies)
	if adjacent_enemies.is_empty():
		return
	var split_damage := maxi(1, roundi(float(damage) * 0.5 / float(adjacent_enemies.size())))
	for adjacent_enemy in adjacent_enemies:
		_append_damage_value(shared_damage, adjacent_enemy, split_damage)


func _get_final_digest_damage(enemy: Enemy, enemies: Array[Enemy], stomach: StomachBoard, raw_damage: int) -> int:
	if not _has_nightmare_effect(enemy, NIGHTMARE_SKILL_OPEN_CELL_DEFENSE):
		return raw_damage
	var open_adjacent_cells := NightmarePlacementQuery.get_open_adjacent_cell_count(enemy, enemies, stomach.columns, stomach.rows)
	var damage_rate := maxf(
		0.0,
		1.0 - float(open_adjacent_cells) * SKILL_3_DAMAGE_REDUCTION_PER_OPEN_FACE
	)
	return roundi(float(raw_damage) * damage_rate)


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


func _apply_enemy_damage_values(damage_display_values: Dictionary, digested_enemies: Array[Enemy]) -> void:
	for target in damage_display_values.keys():
		var enemy := target as Enemy
		if enemy == null or enemy.digested:
			continue
		var damage_values: Array = damage_display_values[target]
		var total_damage := _sum_damage_values(damage_values)
		enemy.show_digest_damage_values(damage_values)
		if enemy.take_digest_damage(total_damage, false) and not digested_enemies.has(enemy):
			digested_enemies.append(enemy)
		enemy.pulse_damage()


func _wait_for_next_beat() -> void:
	if _beat_conductor == null or not is_instance_valid(_beat_conductor):
		return
	if _beat_conductor.audio_player == null or not _beat_conductor.audio_player.playing:
		return
	await _beat_conductor.wait_until_next_beat()


func _get_turn_start_hp(enemies: Array[Enemy]) -> Dictionary:
	var turn_start_hp := {}
	for enemy in enemies:
		turn_start_hp[enemy] = enemy.current_hp
	return turn_start_hp


func _append_damage_value(damage_values_by_enemy: Dictionary, enemy: Enemy, damage: int) -> void:
	if enemy == null or damage <= 0:
		return
	var damage_values: Array[int] = []
	if damage_values_by_enemy.has(enemy):
		damage_values.append_array(damage_values_by_enemy[enemy])
	damage_values.append(damage)
	damage_values_by_enemy[enemy] = damage_values


func _sum_damage_values(damage_values: Array) -> int:
	var total := 0
	for damage in damage_values:
		total += damage
	return total


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
	if not has_active_nightmare_effect(enemies, NIGHTMARE_SKILL_LATE_DIGEST_WEAKEN) or minutes < 25 * 60:
		return 0.0
	var passed_hours := maxi(0, floori(float(minutes - 25 * 60) / 60.0))
	return -minf(0.9, 0.3 + float(passed_hours) * 0.05)


func _get_seed_block_digest_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	if minutes < SEED_BLOCK_LATE_DIGEST_DAMAGE_START_HOUR * 60:
		return 0.0
	var rate := 0.0
	for enemy in enemies:
		if enemy == null or not enemy.is_active_in_stomach() or enemy.seed_skill_definition == null:
			continue
		if enemy.seed_skill_definition.skill_id == DREAM_SEED_RARE_LATE_DIGEST_DAMAGE:
			rate += SEED_BLOCK_LATE_DIGEST_DAMAGE_RATE
	return rate


func _has_nightmare_effect(enemy: Enemy, skill_id: int) -> bool:
	return (
		enemy.should_apply_nightmare_skill()
		and enemy.has_main_effect
		and enemy.skill_definition != null
		and enemy.skill_definition.skill_id == skill_id
	)
