class_name EnemyEffectOnTouchAcidLineChangeMaxHp
extends EnemyEffect

# 最大HP差分
@export var max_hp_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() > 0: runtime.add_max_hp_delta(runtime.source, max_hp_delta, false)
