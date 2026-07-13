class_name EnemyEffectOnAdjacentObjectScaleTargetHp
extends EnemyEffect

# HP倍率
@export var hp_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

