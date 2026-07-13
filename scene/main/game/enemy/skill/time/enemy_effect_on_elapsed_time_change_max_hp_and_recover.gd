class_name EnemyEffectOnElapsedTimeChangeMaxHpAndRecover
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

