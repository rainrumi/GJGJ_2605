class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalRate
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_REFRESH

# 接触毎割合
@export var interval_delta_rate := 0.0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_interval_rate(interval_delta_rate * get_stomach_edge_contact_count())
