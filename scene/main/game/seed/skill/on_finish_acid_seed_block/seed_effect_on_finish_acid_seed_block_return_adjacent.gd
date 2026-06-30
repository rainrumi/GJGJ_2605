class_name SeedEffectOnFinishAcidSeedBlockReturnAdjacent
extends SeedEffect


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy
	var enemies: Array = context.get("enemies", [])
	if seed_block == null:
		return
	for adjacent_enemy in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies):
		if adjacent_enemy == null or adjacent_enemy.is_Acided() or not adjacent_enemy.is_nightmare():
			continue
		adjacent_enemy.set_Aciding(false)
		adjacent_enemy.return_to_origin()
