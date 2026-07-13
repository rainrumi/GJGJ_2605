class_name EnemyEffectOnAcidDamageCountTakeAcidDamage
extends EnemyEffect

# 必要被弾数
@export_range(1, 10000, 1) var required_count := 1
# 追加ダメージ
@export var damage := 0

