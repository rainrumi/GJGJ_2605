class_name EnemyEffectOnAdjacentObjectCountChanceChangeTargetAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 当選時倍率
@export var chance_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	var targets := context.get_adjacent_objects() # 隣接対象
	if targets.size() < minimum_count: return
	for enemy in targets:
		var value := attack_delta * targets.size() # 攻撃差分
		if context.roll(chance): value = roundi(float(value) * chance_multiplier)
		context.add_attack_delta(enemy, value)
