class_name EnemyEffectOnDigestedDealAdjacentFixedAcidDamage
extends EnemyEffect

# 固定ダメージ
@export var damage := 0
# ダメージ倍率
@export var damage_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

