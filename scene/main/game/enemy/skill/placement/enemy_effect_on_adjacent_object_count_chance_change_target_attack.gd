class_name EnemyEffectOnAdjacentObjectCountChanceChangeTargetAttack
extends EnemyEffect

# 攻撃差分
@export var attack_delta := 0
# 必要隣接数
@export_range(1, 64, 1) var minimum_count := 1
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# 当選時倍率
@export var chance_multiplier := 1.0

