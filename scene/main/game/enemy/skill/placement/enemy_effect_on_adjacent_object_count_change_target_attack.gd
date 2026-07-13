class_name EnemyEffectOnAdjacentObjectCountChangeTargetAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1

