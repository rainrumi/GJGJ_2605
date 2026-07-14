class_name EnemyEffectOnAwayAcidLineChangeHp
extends EnemyEffect

# HP差分
@export var hp_delta := 0
# HP倍率
@export var hp_multiplier := 1.0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() == 0: multiply_hp(source, hp_multiplier); add_max_hp_delta(source, hp_delta, false)
