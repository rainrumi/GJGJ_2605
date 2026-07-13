class_name EnemyEffectOnBattleChangeDigestIntervalByObjectCount
extends EnemyEffect

# モノ毎秒差
@export var seconds_per_object := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.REFRESH): context.add_interval_seconds(seconds_per_object * context.get_active_objects().size())
