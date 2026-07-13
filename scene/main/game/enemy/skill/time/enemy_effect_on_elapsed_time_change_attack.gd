class_name EnemyEffectOnElapsedTimeChangeAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.PROGRESS_TIME): context.source.add_damage(roundi(context.scale_value(float(attack_delta * context.consume_interval(interval_seconds)))))
