class_name EnemyEffectOnAdjacentObjectShareAcidDamage
extends EnemyEffect

# 自身を含む
@export var include_self := true
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

