class_name EnemyEffectOnDigestedChangeTime
extends EnemyEffect

# 時刻秒差分
@export var seconds_delta := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if context.is_event(Event.DIGESTED) and context.target == context.source: context.resolver.add_time_delta(seconds_delta)
