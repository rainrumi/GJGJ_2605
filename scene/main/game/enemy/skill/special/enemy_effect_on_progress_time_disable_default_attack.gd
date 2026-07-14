class_name EnemyEffectOnProgressTimeDisableDefaultAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# 通常攻撃停止
@export var disabled := true

# 効果適用
func apply() -> void:
	if is_refresh_activation(): set_default_attack_disabled(source, disabled)
