class_name EnemyEffectOnElapsedTimeChangeAttack
extends EnemyEffectOnTimeProgressed


# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	source.add_damage(roundi(EnemyEffectValueCalculator.scale(source, float(attack_delta * consume_interval(interval_seconds)))))
