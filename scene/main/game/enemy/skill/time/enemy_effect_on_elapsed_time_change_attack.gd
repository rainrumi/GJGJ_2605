class_name EnemyEffectOnElapsedTimeChangeAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.PROGRESS_TIME): runtime.source.add_damage(roundi(runtime.scale_value(float(attack_delta * runtime.consume_interval(interval_seconds)))))
