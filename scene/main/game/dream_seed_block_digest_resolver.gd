class_name DreamSeedBlockDigestResolver
extends RefCounted

const DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE := 2002
const DREAM_SEED_RARE_LATE_DIGEST_DAMAGE := 2004
const DREAM_SEED_RARE_ADJACENT_DAMAGE_UP := 2005
const PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE_BIG := 2103
const PROPOSAL_RARE_REVIVE_TIME_DAMAGE := 2104
const PROPOSAL_RARE_EXTRA_DIGEST_HIT := 2107
const PROPOSAL_RARE_RANDOM_EXTRA_DIGEST := 2108
const PROPOSAL_RARE_RANDOM_DOUBLE_DIGEST := 2109
const PROPOSAL_RARE_INTERVAL_DAMAGE := 2110
const PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE := 2112
const PROPOSAL_RARE_LINE_PLUS := 2113
const PROPOSAL_RARE_LINE_CELL_DAMAGE := 2114
const PROPOSAL_RARE_EDGE_LINE_DAMAGE := 2115
const PROPOSAL_RARE_LINE_COUNT_DAMAGE := 2116
const PROPOSAL_RARE_SELF_DAMAGE_FROM_DIGEST := 2117
const PROPOSAL_RARE_DIGEST_DAMAGE_HEAL := 2123
const PROPOSAL_RARE_DIGESTED_NIGHTMARE_HEAL := 2124
const PROPOSAL_RARE_HP_INTERVAL_UP := 2127
const PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE := 2129
const PROPOSAL_RARE_ATTACK_UP := 2130
const PROPOSAL_RARE_HP_LOSS_INTERVAL_UP := 2132
const PROPOSAL_RARE_SAFE_RETURN := 2137
const LATE_DIGEST_DAMAGE_RATE := 1.0
const LATE_DIGEST_DAMAGE_START_HOUR := 28
const BASE_DIGEST_DAMAGE := 300


# 消化ダメージ率取得
func get_digest_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	if minutes < LATE_DIGEST_DAMAGE_START_HOUR * 60:
		return 0.0
	# 率値
	var rate := 0.0
	for enemy in enemies:
		if enemy == null or not enemy.is_active_in_stomach() or not enemy.has_seed_skill():
			continue
		if enemy.get_seed_skill().skill_id == DREAM_SEED_RARE_LATE_DIGEST_DAMAGE:
			rate += LATE_DIGEST_DAMAGE_RATE
	return rate


# 消化済みby種ブロックeffects追加
func append_digested_by_seed_block_effects(
	seed_block: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	minutes: int,
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	if seed_block == null or not seed_block.has_seed_skill():
		return
	match seed_block.get_seed_skill().skill_id:
		DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE, DREAM_SEED_RARE_ADJACENT_DAMAGE_UP:
			_apply_adjacent_damage(
				seed_block,
				enemies,
				int(received_digest_damage.get(seed_block, 0)),
				digested_enemies
			)
		PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE_BIG:
			_apply_line_damage(enemies, stomach, 500, digested_enemies)
		PROPOSAL_RARE_REVIVE_TIME_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, _get_hour_damage(minutes), digested_enemies, true)
		PROPOSAL_RARE_INTERVAL_DAMAGE:
			_apply_line_damage(enemies, stomach, BASE_DIGEST_DAMAGE * 30, digested_enemies, true)
		PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, BASE_DIGEST_DAMAGE * 60, digested_enemies, true)
		PROPOSAL_RARE_LINE_PLUS:
			pass
		PROPOSAL_RARE_LINE_CELL_DAMAGE:
			_apply_line_damage(enemies, stomach, 1000, digested_enemies, false)
		PROPOSAL_RARE_EDGE_LINE_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, 1000, digested_enemies, false)
		PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE:
			_apply_adjacent_damage(seed_block, enemies, 300, digested_enemies, true)
		PROPOSAL_RARE_SAFE_RETURN:
			_return_adjacent_nightmares(seed_block, enemies)


# new消化済み適用
func apply_digested_effect_and_append_new_digested(
	seed_block: Enemy,
	enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	append_digested_by_seed_block_effects(seed_block, enemies, null, 0, received_digest_damage, digested_enemies)


# 対象消化ダメージ倍率取得
func get_target_digest_damage_multiplier(target: Enemy, enemies: Array[Enemy]) -> float:
	if target == null:
		return 1.0
	# 倍率
	var multiplier := 1.0
	for enemy in enemies:
		if enemy == null or enemy == target or not enemy.is_active_in_stomach() or not enemy.has_seed_skill():
			continue
		if not NightmarePlacementQuery.are_enemies_adjacent(enemy, target):
			continue
		match enemy.get_seed_skill().skill_id:
			PROPOSAL_RARE_RANDOM_EXTRA_DIGEST:
				multiplier *= 2.0
			PROPOSAL_RARE_RANDOM_DOUBLE_DIGEST:
				if randi() % 5 == 0:
					multiplier *= 0.0
			PROPOSAL_RARE_DIGEST_DAMAGE_HEAL:
				multiplier *= 1.10
			PROPOSAL_RARE_HP_INTERVAL_UP:
				multiplier *= 0.80
			DREAM_SEED_RARE_ADJACENT_DAMAGE_UP:
				multiplier *= 2.0
	return multiplier


# 隣接ダメージ適用
func _apply_adjacent_damage(
	seed_block: Enemy,
	enemies: Array[Enemy],
	damage: int,
	digested_enemies: Array[Enemy],
	split := true
) -> void:
	if damage <= 0:
		return
	# 隣接敵
	var adjacent_enemies := NightmarePlacementQuery.get_adjacent_enemies(seed_block, enemies)
	if adjacent_enemies.is_empty():
		return
	# splitダメージ
	var split_damage := maxi(1, roundi(float(damage) / float(adjacent_enemies.size()))) if split else damage
	for adjacent_enemy in adjacent_enemies:
		if adjacent_enemy == seed_block or adjacent_enemy.is_digested():
			continue
		adjacent_enemy.show_digest_damage_values([split_damage])
		if adjacent_enemy.take_digest_damage(split_damage, false) and not digested_enemies.has(adjacent_enemy):
			digested_enemies.append(adjacent_enemy)


# 列ダメージ適用
func _apply_line_damage(
	enemies: Array[Enemy],
	stomach: StomachBoard,
	damage: int,
	digested_enemies: Array[Enemy],
	split := false
) -> void:
	if stomach == null or damage <= 0:
		return
	# 対象
	var targets: Array[Enemy] = []
	for enemy in enemies:
		if enemy == null or enemy.is_digested() or not enemy.is_active_in_stomach() or enemy.has_seed_skill():
			continue
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			targets.append(enemy)
	if targets.is_empty():
		return
	# 対象ダメージ
	var target_damage := maxi(1, roundi(float(damage) / float(targets.size()))) if split else damage
	for target in targets:
		target.show_digest_damage_values([target_damage])
		if target.take_digest_damage(target_damage, false) and not digested_enemies.has(target):
			digested_enemies.append(target)


# 隣接悪夢返却
func _return_adjacent_nightmares(seed_block: Enemy, enemies: Array[Enemy]) -> void:
	for adjacent_enemy in NightmarePlacementQuery.get_adjacent_enemies(seed_block, enemies):
		if adjacent_enemy == null or adjacent_enemy.is_digested() or not adjacent_enemy.is_nightmare():
			continue
		adjacent_enemy.set_digesting(false)
		adjacent_enemy.return_to_origin()


# 時ダメージ取得
func _get_hour_damage(minutes: int) -> int:
	# 時値
	var hour := int(minutes / 60) % 24
	return BASE_DIGEST_DAMAGE * hour * 10
