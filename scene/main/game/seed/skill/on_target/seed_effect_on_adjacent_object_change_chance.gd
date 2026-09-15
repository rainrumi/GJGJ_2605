class_name SeedEffectOnAdjacentObjectChangeChance
extends SeedEffect

@export_range(0.0, 10.0, 0.1) var chance_multiplier := 1.0


# 種ブロック由来の再評価時補正
func apply_seed_block_refresh_modifiers(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy
	var enemies: Array = context.get("enemies", [])
	if seed_block == null or chance_multiplier == 1.0:
		return
	for target in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies):
		EnemyEffectStatChanges.multiply_chance(target, chance_multiplier)
