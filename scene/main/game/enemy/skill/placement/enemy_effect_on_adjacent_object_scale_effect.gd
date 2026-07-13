class_name EnemyEffectOnAdjacentObjectScaleEffect
extends EnemyEffect

# 効果倍率
@export var effect_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

