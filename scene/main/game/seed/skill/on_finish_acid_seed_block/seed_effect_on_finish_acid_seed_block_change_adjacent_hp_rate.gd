class_name SeedEffectOnFinishAcidSeedBlockChangeAdjacentHpRate
extends SeedEffect

@export var rate := 1.0 # HP倍率


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	if seed_block == null or rate <= 0.0:
		return
	for target in EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies):
		if target == seed_block or target == null or target.is_Acided():
			continue
		var next_max_hp := maxi(1, roundi(float(target.get_max_hp()) * rate)) # 次最大HP
		var next_current_hp := maxi(1, roundi(float(target.get_current_hp()) * rate)) # 次HP
		target.set_hp_values(next_max_hp, next_current_hp)
