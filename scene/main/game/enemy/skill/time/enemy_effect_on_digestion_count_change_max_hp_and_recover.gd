class_name EnemyEffectOnDigestionCountChangeMaxHpAndRecover
extends EnemyEffect

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

