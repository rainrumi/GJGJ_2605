class_name EnemyEffectOnDigestedDealAdjacentInheritedOverkillAcidDamage
extends EnemyEffect

# 超過倍率
@export var overkill_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.DIGESTED) and context.target == context.source:
		for enemy in context.get_targets(target): context.deal_acid_damage(enemy, roundi(float(context.overkill_damage) * overkill_multiplier))
