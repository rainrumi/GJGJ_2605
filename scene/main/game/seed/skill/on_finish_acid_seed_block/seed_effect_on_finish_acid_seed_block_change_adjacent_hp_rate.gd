class_name SeedEffectOnFinishAcidSeedBlockChangeAdjacentHpRate
extends SeedEffect

@export var rate := 1.0 # HP倍率
@export var seeds_only := false
@export var highest_hp_only := false


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	if seed_block == null or rate <= 0.0:
		return
	var targets := EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies, true)
	if highest_hp_only:
		targets.clear()
		var highest: Enemy
		for candidate: Enemy in enemies:
			if candidate == seed_block or not candidate.is_active_in_stomach() or candidate.is_Acided():
				continue
			if highest == null or candidate.get_current_hp() > highest.get_current_hp():
				highest = candidate
		if highest != null:
			targets.append(highest)
	for target in targets:
		if target == seed_block or target == null or target.is_Acided():
			continue
		if seeds_only and not target.has_seed():
			continue
		var next_max_hp := maxi(1, roundi(float(target.get_max_hp()) * rate)) # 次最大HP
		var next_current_hp := maxi(1, roundi(float(target.get_current_hp()) * rate)) # 次HP
		if highest_hp_only:
			next_max_hp = maxi(target.get_max_hp(), next_current_hp)
		target.set_hp_values(next_max_hp, next_current_hp)
