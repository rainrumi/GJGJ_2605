class_name EnemyEffectOnDigestionCountChangeAttack
extends EnemyEffect

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃差分
@export var attack_delta := 0

