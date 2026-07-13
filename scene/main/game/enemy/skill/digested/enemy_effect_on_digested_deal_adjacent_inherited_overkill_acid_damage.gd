class_name EnemyEffectOnDigestedDealAdjacentInheritedOverkillAcidDamage
extends EnemyEffect

# 超過倍率
@export var overkill_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

