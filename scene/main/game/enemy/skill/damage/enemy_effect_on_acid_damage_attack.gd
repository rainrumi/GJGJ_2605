class_name EnemyEffectOnAcidDamageAttack
extends EnemyEffect

# 攻撃回数
@export_range(1, 64, 1) var attack_count := 1
# 固定ダメージ
@export var fixed_damage := 0

