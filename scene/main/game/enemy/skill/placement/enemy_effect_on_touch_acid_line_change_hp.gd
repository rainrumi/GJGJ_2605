class_name EnemyEffectOnTouchAcidLineChangeHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# HP差分
@export var hp_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation():
		var active := 1 if get_acid_line_contact_count() > 0 else 0 # 接触状態
		var previous := get_state_int("active") # 直前状態
		set_state("active", active); change_hp(source, hp_delta * (active - previous))
