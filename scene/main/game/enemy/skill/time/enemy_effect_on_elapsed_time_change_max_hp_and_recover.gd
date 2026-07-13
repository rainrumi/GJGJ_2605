class_name EnemyEffectOnElapsedTimeChangeMaxHpAndRecover
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

# 効果適用
func apply(context: EnemyEffectContext) -> void:
	if not context.is_event(Event.PROGRESS_TIME): return
	var count := context.consume_interval(interval_seconds) # 発火数
	context.source.add_max_hp(roundi(context.scale_value(float(max_hp_delta * count))), false)
	context.recover(context.source, recovery * count)
