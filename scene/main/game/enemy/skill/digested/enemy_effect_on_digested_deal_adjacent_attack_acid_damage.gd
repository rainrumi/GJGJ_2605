class_name EnemyEffectOnDigestedDealAdjacentAttackAcidDamage
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

