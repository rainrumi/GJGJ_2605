class_name EnemyEffectOnTouchAcidLineChangeMaxHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_acid_line_contact_count() > 0: context.add_max_hp_delta(context.source, max_hp_delta, false)
