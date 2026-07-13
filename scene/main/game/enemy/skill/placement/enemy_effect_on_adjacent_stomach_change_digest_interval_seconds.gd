class_name EnemyEffectOnAdjacentStomachChangeDigestIntervalSeconds
extends EnemyEffect

# 接触毎秒差
@export var interval_delta_seconds := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.add_interval_seconds(interval_delta_seconds * context.get_stomach_edge_contact_count())
