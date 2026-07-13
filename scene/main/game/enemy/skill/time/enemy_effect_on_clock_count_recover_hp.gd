class_name EnemyEffectOnClockCountRecoverHp
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 回復量
@export var recovery := 0

