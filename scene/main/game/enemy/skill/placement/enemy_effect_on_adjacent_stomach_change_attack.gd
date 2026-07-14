class_name EnemyEffectOnAdjacentStomachChangeAttack
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# 接触毎差分
@export var attack_delta := 0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_attack_delta(source, attack_delta * get_stomach_edge_contact_count())
