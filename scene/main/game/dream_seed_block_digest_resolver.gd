class_name DreamSeedBlockAcidResolver
extends RefCounted


# 消化ダメージ率取得
func get_acid_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	var rate := 0.0
	for enemy in enemies:
		if enemy == null or not enemy.is_active_in_stomach() or not enemy.has_seed():
			continue
		for effect in _get_seed_block_effects(enemy):
			rate += effect.get_seed_block_acid_damage_rate({
				"seed_block": enemy,
				"enemies": enemies,
				"minutes": minutes,
			})
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
	var context := {
		"seed_block": seed_block,
		"enemies": enemies,
		"stomach": stomach,
		"minutes": minutes,
		"received_acid_damage": received_acid_damage,
		"acided_enemies": Acided_enemies,
	}
	for effect in _get_seed_block_effects(seed_block):
		effect.on_finish_acid_seed_block(context)


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
	var multiplier := 1.0
	for enemy in enemies:
		if enemy == null or enemy == target or not enemy.is_active_in_stomach() or not enemy.has_seed():
			continue
		if not EnemyPlacementQuery.are_enemies_adjacent(enemy, target):
			continue
		for effect in _get_seed_block_effects(enemy):
			multiplier *= effect.get_seed_block_target_acid_multiplier({
				"seed_block": enemy,
				"target": target,
				"enemies": enemies,
			})
	return multiplier


# block効果取得
func _get_seed_block_effects(seed_block: Enemy) -> Array[SeedEffect]:
	var effects: Array[SeedEffect] = []
	if seed_block == null or not seed_block.has_seed():
		return effects
	var seed := seed_block.get_seed()
	if seed == null:
		return effects
	var skill := seed.get_sub_skill()
	if skill == null:
		return effects
	effects.append_array(skill.get_effects())
	return effects
