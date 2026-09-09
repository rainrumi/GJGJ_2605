class_name SeedEffectOnFinishAcidSeedBlockChangeAdjacentAcidDamageRate
extends SeedEffect

@export var rate := 1.0 # 受酸倍率
@export var seeds_only := false


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	if seed_block == null or rate < 0.0:
		return
	for target in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies, true):
		if target == seed_block or target == null or target.is_Acided():
			continue
		if seeds_only and not target.has_seed():
			continue
		target.set_acid_damage_taken_multiplier(target.acid_damage_taken_multiplier * rate)
