class_name EnemyEffectOnAdjacentObjectChangeTargetAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 対象毎上限
@export_range(0, 64, 1) var max_activations_per_target := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.REFRESH): return
	for enemy in context.get_activatable_new_adjacent(max_activations_per_target): enemy.add_damage(roundi(context.scale_value(float(attack_delta))))
