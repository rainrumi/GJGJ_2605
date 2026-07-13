class_name EnemyEffectOnDigestedDealAdjacentAttackAcidDamage
extends EnemyEffect

# 攻撃倍率
@export var attack_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.DIGESTED) and context.target == context.source:
		for enemy in context.get_targets(target): context.deal_acid_damage(enemy, roundi(float(context.source.get_damage()) * attack_multiplier))
