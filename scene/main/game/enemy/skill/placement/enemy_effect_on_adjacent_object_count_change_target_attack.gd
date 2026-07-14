class_name EnemyEffectOnAdjacentObjectCountChangeTargetAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var targets := get_adjacent_objects() # 隣接対象
	if targets.size() < minimum_count: return
	for enemy in targets: add_attack_delta(enemy, attack_delta * targets.size())
