class_name EnemyEffectOnAwayAcidLineChangeAcidDamage
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH


# 依存種別取得
func get_dependency_mask() -> int:
	return DEPENDENCY_STOMACH

# ダメージ差分
@export var acid_damage_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() == 0: add_acid_damage_delta(source, acid_damage_delta)
