class_name EnemyEffectOnElapsedTimeChangeAttack
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 攻撃差分
@export var attack_delta := 0

