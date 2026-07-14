class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalSeconds
extends EnemyEffect

# 接触毎秒差
@export var interval_delta_seconds := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH): runtime.add_interval_seconds(interval_delta_seconds * runtime.get_stomach_edge_contact_count())
