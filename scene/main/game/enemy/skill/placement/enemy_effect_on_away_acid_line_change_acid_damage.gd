class_name EnemyEffectOnAwayAcidLineChangeAcidDamage
extends EnemyEffect

# ダメージ差分
@export var acid_damage_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() == 0: add_acid_damage_delta(source, acid_damage_delta)
