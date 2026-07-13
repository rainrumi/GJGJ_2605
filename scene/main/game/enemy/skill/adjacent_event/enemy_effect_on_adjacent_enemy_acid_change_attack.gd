class_name EnemyEffectOnAdjacentEnemyAcidChangeAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.ADJACENT_ACID_DAMAGE) and context.get_adjacent_enemies().has(context.target): context.source.add_damage(roundi(context.scale_value(float(attack_delta))))
