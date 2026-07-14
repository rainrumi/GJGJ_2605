class_name EnemyEffectOnAwayAcidLineChangeHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0
# HP倍率
@export var hp_multiplier := 1.0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_acid_line_contact_count() == 0: runtime.multiply_hp(runtime.source, hp_multiplier); runtime.add_max_hp_delta(runtime.source, hp_delta, false)
