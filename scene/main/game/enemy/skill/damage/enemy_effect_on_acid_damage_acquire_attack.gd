class_name EnemyEffectOnAcidDamageAcquireAttack
extends EnemyEffect

# 取得割合
@export var attack_rate := 1.0
# 発動率
@export_range(0.0, 1.0, 0.01) var chance := 1.0
# ライン接触必須
@export var require_acid_line_touch := false

