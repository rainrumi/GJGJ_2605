class_name EnemyEffectOnAwayAcidLineChangeHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_STOMACH

# HP差分
@export var hp_delta := 0
# HP倍率
@export var hp_multiplier := 1.0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() == 0: multiply_hp(source, hp_multiplier); add_max_hp_delta(source, hp_delta, false)
