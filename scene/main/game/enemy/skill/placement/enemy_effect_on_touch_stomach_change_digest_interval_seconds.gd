class_name EnemyEffectOnTouchStomachChangeDigestIntervalSeconds
extends EnemyEffect

# 秒差分
@export var interval_delta_seconds := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.REFRESH) and runtime.get_stomach_edge_contact_count() > 0: runtime.add_interval_seconds(interval_delta_seconds)
