class_name EnemyEffectOnSelfOrAdjacentDigestedRevive
extends EnemyEffect

# 回復割合
@export_range(0.0, 1.0, 0.01) var recovery_rate := 1.0
# 生存者必須
@export var require_survivor := true
# 自身を含む
@export var include_self := true

