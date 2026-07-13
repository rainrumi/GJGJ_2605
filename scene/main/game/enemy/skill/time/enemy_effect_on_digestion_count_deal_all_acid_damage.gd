class_name EnemyEffectOnDigestionCountDealAllAcidDamage
extends EnemyEffect

# 必要消化数
@export_range(1, 10000, 1) var required_count := 1
# ダメージ
@export var damage := 0
# 攻撃回数
@export_range(1, 64, 1) var hit_count := 1
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ALL_OBJECTS

