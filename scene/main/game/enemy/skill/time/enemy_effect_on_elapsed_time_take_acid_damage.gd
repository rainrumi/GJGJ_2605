class_name EnemyEffectOnElapsedTimeTakeAcidDamage
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# ダメージ
@export var damage := 0

