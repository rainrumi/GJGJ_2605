class_name EnemyEffectOnAdjacentObjectCountChangeSelfAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	var count := context.get_adjacent_objects().size() # 隣接数
	if count >= minimum_count: context.add_attack_delta(context.source, attack_delta * count)
