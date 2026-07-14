class_name EnemyEffectOnDigestedDealAdjacentInheritedOverkillAcidDamage
extends EnemyEffect

# 超過倍率
@export var overkill_multiplier := 1.0
# 効果対象
@export var target: EnemyEffect.EffectTarget = EnemyEffect.EffectTarget.ADJACENT_OBJECTS

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.DIGESTED) and runtime.target == runtime.source:
		for enemy in runtime.get_targets(target): runtime.deal_acid_damage(enemy, roundi(float(runtime.overkill_damage) * overkill_multiplier))
