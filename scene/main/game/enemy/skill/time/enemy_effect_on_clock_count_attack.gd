class_name EnemyEffectOnClockCountAttack
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

