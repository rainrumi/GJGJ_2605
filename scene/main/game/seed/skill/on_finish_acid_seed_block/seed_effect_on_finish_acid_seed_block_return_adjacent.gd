class_name SeedEffectOnFinishAcidSeedBlockReturnAdjacent
extends SeedEffect


func is_lethal_on_acid_damage() -> bool:
	return true


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	if seed_block == null:
		return
	for adjacent_enemy in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies, true):
		if adjacent_enemy == null or adjacent_enemy.is_Acided() or not adjacent_enemy.is_enemy():
			continue
		adjacent_enemy.set_Aciding(false)
		adjacent_enemy.return_to_origin()
		adjacent_enemy.forcibly_returned.emit()
