class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalRate
extends EnemyEffect

# 接触毎割合
@export var interval_delta_rate := 0.0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.add_interval_rate(interval_delta_rate * context.get_stomach_edge_contact_count())
