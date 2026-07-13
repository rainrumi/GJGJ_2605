class_name EnemyEffectOnClockCountChangeAcidDamage
extends EnemyEffect

# 必要回数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ差分
@export var damage_delta := 0
# ダメージ倍率
@export var damage_multiplier := 1.0

