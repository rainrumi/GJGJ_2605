class_name EnemyEffectOnElapsedTimeRecoverHp
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 固定回復量
@export var recovery := 0
# 割合回復量
@export var recovery_rate := 0.0

