class_name EnemyEffectOnAdjacentEnemyAcidChangeAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.ADJACENT_ACID_DAMAGE) and runtime.get_adjacent_enemies().has(runtime.target): runtime.source.add_damage(roundi(runtime.scale_value(float(attack_delta))))
