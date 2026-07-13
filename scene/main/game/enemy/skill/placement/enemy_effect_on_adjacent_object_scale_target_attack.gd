class_name EnemyEffectOnAdjacentObjectScaleTargetAttack
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 必要隣接数
@export_range(1, 64, 1) var required_count := 1

