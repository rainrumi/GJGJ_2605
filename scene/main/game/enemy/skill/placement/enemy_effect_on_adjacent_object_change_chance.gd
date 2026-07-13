class_name EnemyEffectOnAdjacentObjectChangeChance
extends EnemyEffect

# 確率差分
@export_range(-1.0, 1.0, 0.01) var chance_delta := 0.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

