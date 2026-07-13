class_name EnemyEffectOnTouchStomachChangeDigestIntervalRate
extends EnemyEffect

# 割合差分
@export var interval_delta_rate := 0.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH) and context.get_stomach_edge_contact_count() > 0: context.add_interval_rate(interval_delta_rate)
