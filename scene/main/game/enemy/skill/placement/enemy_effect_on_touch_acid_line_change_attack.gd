class_name EnemyEffectOnTouchAcidLineChangeAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# 攻撃差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation() and get_acid_line_contact_count() > 0: add_attack_delta(source, attack_delta)
