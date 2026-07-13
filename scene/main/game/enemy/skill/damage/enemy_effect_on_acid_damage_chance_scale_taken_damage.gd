class_name EnemyEffectOnAcidDamageChanceScaleTakenDamage
extends EnemyEffect

# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ダメージ倍率
@export var damage_multiplier := 1.0

