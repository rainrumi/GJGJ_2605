class_name EnemyEffectOnNotAdjacentAcidLineChangeHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0
# HP倍率
@export var hp_multiplier := 1.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_acid_line_contact_count() == 0: context.multiply_hp(context.source, hp_multiplier); context.add_max_hp_delta(context.source, hp_delta, false)
