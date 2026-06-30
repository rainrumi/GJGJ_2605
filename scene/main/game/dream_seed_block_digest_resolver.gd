class_name DreamSeedBlockAcidResolver
extends RefCounted

const seed_RARE_REFLECT_acid_DAMAGE := 2002
const seed_RARE_LATE_acid_DAMAGE := 2004
const seed_RARE_ADJACENT_DAMAGE_UP := 2005
const PROPOSAL_RARE_REVIVE_acid_DAMAGE_BIG := 2103
const PROPOSAL_RARE_REVIVE_TIME_DAMAGE := 2104
const PROPOSAL_RARE_EXTRA_acid_HIT := 2107
const PROPOSAL_RARE_RANDOM_EXTRA_Acid := 2108
const PROPOSAL_RARE_RANDOM_DOUBLE_Acid := 2109
const PROPOSAL_RARE_INTERVAL_DAMAGE := 2110
const PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE := 2112
const PROPOSAL_RARE_LINE_PLUS := 2113
const PROPOSAL_RARE_LINE_CELL_DAMAGE := 2114
const PROPOSAL_RARE_EDGE_LINE_DAMAGE := 2115
const PROPOSAL_RARE_LINE_COUNT_DAMAGE := 2116
const PROPOSAL_RARE_SELF_DAMAGE_FROM_Acid := 2117
const PROPOSAL_RARE_acid_DAMAGE_HEAL := 2123
const PROPOSAL_RARE_AcidED_NIGHTMARE_HEAL := 2124
const PROPOSAL_RARE_HP_INTERVAL_UP := 2127
const PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE := 2129
const PROPOSAL_RARE_ATTACK_UP := 2130
const PROPOSAL_RARE_HP_LOSS_INTERVAL_UP := 2132
const PROPOSAL_RARE_SAFE_RETURN := 2137
const LATE_acid_DAMAGE_RATE := 1.0
const LATE_acid_DAMAGE_START_HOUR := 28
const BASE_acid_DAMAGE := 300


# 消化ダメージ率取得
func get_acid_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	if minutes < LATE_acid_DAMAGE_START_HOUR * 60:
		return 0.0
	# 率値
	var rate := 0.0
	for enemy in enemies:
		if enemy == null or not enemy.is_active_in_stomach() or not enemy.has_seed():
			continue
		if enemy.get_seed().skill_id == seed_RARE_LATE_acid_DAMAGE:
			rate += LATE_acid_DAMAGE_RATE
	return rate


# 消化済みby種ブロックeffects追加
func append_Acided_by_seed_block_effects(
	seed_block: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	received_acid_damage: Dictionary,
	Acided_enemies: Array[Enemy]
) -> void:
	if seed_block == null or not seed_block.has_seed():
		return
	match seed_block.get_seed().skill_id:
		seed_RARE_REFLECT_acid_DAMAGE, seed_RARE_ADJACENT_DAMAGE_UP:
			_apply_adjacent_damage(
				seed_block,
				enemies,
				int(received_acid_damage.get(seed_block, 0)),
				Acided_enemies
			)
		PROPOSAL_RARE_REVIVE_acid_DAMAGE_BIG:
			_apply_line_damage(enemies, stomach, 500, Acided_enemies)
		PROPOSAL_RARE_REVIVE_TIME_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, _get_hour_damage(minutes), Acided_enemies, true)
		PROPOSAL_RARE_INTERVAL_DAMAGE:
			_apply_line_damage(enemies, stomach, BASE_acid_DAMAGE * 30, Acided_enemies, true)
		PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, BASE_acid_DAMAGE * 60, Acided_enemies, true)
		PROPOSAL_RARE_LINE_PLUS:
			pass
		PROPOSAL_RARE_LINE_CELL_DAMAGE:
			_apply_line_damage(enemies, stomach, 1000, Acided_enemies, false)
		PROPOSAL_RARE_EDGE_LINE_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, 1000, Acided_enemies, false)
		PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, 300, Acided_enemies, true)
		PROPOSAL_RARE_SAFE_RETURN:
			_return_adjacent_nightmares(seed_block, enemies)


# new消化済み適用
func apply_Acided_effect_and_append_new_Acided(
	seed_block: Enemy,
	enemies: Array[Enemy],
	received_acid_damage: Dictionary,
	Acided_enemies: Array[Enemy]
) -> void:
	append_Acided_by_seed_block_effects(seed_block, enemies, null, 0, received_acid_damage, Acided_enemies)


# 対象消化ダメージ倍率取得
func get_target_acid_damage_multiplier(target: Enemy, enemies: Array[Enemy]) -> float:
	if target == null:
		return 1.0
	# 倍率
	var multiplier := 1.0
	for enemy in enemies:
		if enemy == null or enemy == target or not enemy.is_active_in_stomach() or not enemy.has_seed():
			continue
		if not EnemyPlacementQuery.are_enemies_adjacent(enemy, target):
			continue
		match enemy.get_seed().skill_id:
			PROPOSAL_RARE_RANDOM_EXTRA_Acid:
				multiplier *= 2.0
			PROPOSAL_RARE_RANDOM_DOUBLE_Acid:
				if randi() % 5 == 0:
					multiplier *= 0.0
			PROPOSAL_RARE_acid_DAMAGE_HEAL:
				multiplier *= 1.10
			PROPOSAL_RARE_HP_INTERVAL_UP:
				multiplier *= 0.80
			seed_RARE_ADJACENT_DAMAGE_UP:
				multiplier *= 2.0
	return multiplier


# 隣接ダメージ適用
func _apply_adjacent_damage(
	seed_block: Enemy,
	enemies: Array[Enemy],
	damage: int,
	Acided_enemies: Array[Enemy],
	split := true
) -> void:
	if damage <= 0:
		return
	# 隣接敵
	var adjacent_enemies := EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies)
	if adjacent_enemies.is_empty():
		return
	# splitダメージ
	var split_damage := maxi(1, roundi(float(damage) / float(adjacent_enemies.size()))) if split else damage
	for adjacent_enemy in adjacent_enemies:
		if adjacent_enemy == seed_block or adjacent_enemy.is_Acided():
			continue
		adjacent_enemy.show_acid_damage_values([split_damage])
		if adjacent_enemy.take_acid_damage(split_damage, false) and not Acided_enemies.has(adjacent_enemy):
			Acided_enemies.append(adjacent_enemy)


# 列ダメージ適用
func _apply_line_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	damage: int,
	Acided_enemies: Array[Enemy],
	split := false
) -> void:
	if stomach == null or damage <= 0:
		return
	# 対象
	var targets: Array[Enemy] = []
	for enemy in enemies:
		if enemy == null or enemy.is_Acided() or not enemy.is_active_in_stomach() or enemy.has_seed():
			continue
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			targets.append(enemy)
	if targets.is_empty():
		return
	# 対象ダメージ
	var target_damage := maxi(1, roundi(float(damage) / float(targets.size()))) if split else damage
	for target in targets:
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not Acided_enemies.has(target):
			Acided_enemies.append(target)


# 隣接悪夢返却
func _return_adjacent_nightmares(seed_block: Enemy, enemies: Array[Enemy]) -> void:
	for adjacent_enemy in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies):
		if adjacent_enemy == null or adjacent_enemy.is_Acided() or not adjacent_enemy.is_nightmare():
			continue
		adjacent_enemy.set_Aciding(false)
		adjacent_enemy.return_to_origin()


# 時ダメージ取得
func _get_hour_damage(minutes: int) -> int:
	# 時値
	var hour := int(minutes / 60) % 24
	return BASE_acid_DAMAGE * hour * 10
