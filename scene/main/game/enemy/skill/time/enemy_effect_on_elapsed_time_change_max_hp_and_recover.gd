class_name EnemyEffectOnElapsedTimeChangeMaxHpAndRecover
extends EnemyEffect

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 最大HP差分
@export var max_hp_delta := 0
# 回復量
@export var recovery := 0

# 効果適用
func apply() -> void:
	if not runtime.is_event(Event.PROGRESS_TIME): return
	var count := runtime.consume_interval(interval_seconds) # 発火数
	runtime.source.add_max_hp(roundi(runtime.scale_value(float(max_hp_delta * count))), false)
	runtime.recover(runtime.source, recovery * count)
