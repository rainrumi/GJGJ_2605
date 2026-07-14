class_name EnemyEffectOnAdjacentObjectScaleTargetHp
extends EnemyEffect

# HP倍率
@export var hp_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var targets := get_adjacent_objects() # 隣接対象
	if targets.size() < required_count: return
	for enemy in targets: multiply_hp(enemy, hp_multiplier)
