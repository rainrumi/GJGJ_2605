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
	if not is_progress_time_activation(): return
	var count := consume_interval(interval_seconds) # 発火数
	source.add_max_hp(roundi(scale_value(float(max_hp_delta * count))), false)
	recover(source, recovery * count)
