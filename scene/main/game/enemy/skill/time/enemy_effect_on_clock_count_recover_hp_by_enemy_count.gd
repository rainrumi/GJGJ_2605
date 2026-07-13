class_name EnemyEffectOnClockCountRecoverHpByEnemyCount
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 敵毎回復量
@export var recovery_per_enemy := 0
# 自身を含む
@export var include_self := true

