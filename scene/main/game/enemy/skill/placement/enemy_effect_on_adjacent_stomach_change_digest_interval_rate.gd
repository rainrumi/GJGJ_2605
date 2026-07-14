class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalRate
extends EnemyEffect

# 接触毎割合
@export var interval_delta_rate := 0.0

# 効果適用
func apply() -> void:
	if is_refresh_activation(): add_interval_rate(interval_delta_rate * get_stomach_edge_contact_count())
