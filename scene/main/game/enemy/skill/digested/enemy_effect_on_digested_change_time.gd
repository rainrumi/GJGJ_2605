class_name EnemyEffectOnDigestedChangeTime
extends EnemyEffect

# 時刻秒差分
@export var seconds_delta := 0

# 効果適用
func apply() -> void:
	if runtime.is_event(Event.DIGESTED) and runtime.target == runtime.source: runtime.resolver.add_time_delta(seconds_delta)
