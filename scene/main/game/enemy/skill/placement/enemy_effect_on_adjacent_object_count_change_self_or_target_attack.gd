class_name EnemyEffectOnAdjacentObjectCountChangeSelfOrTargetAttack
extends EnemyEffect

# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.SELF
# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply() -> void:
	if not is_refresh_activation(): return
	var count := get_adjacent_objects().size() # 隣接数
	if count < minimum_count: return
	for enemy in get_targets(target): add_attack_delta(enemy, attack_delta * count)
