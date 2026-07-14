class_name EnemyEffectOnElapsedTimeRecoverHp
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_PROGRESS_TIME

# 発動秒数
@export_range(1, 86400, 1) var interval_seconds := 60
# 固定回復量
@export var recovery := 0
# 割合回復量
@export var recovery_rate := 0.0

# 効果適用
func apply() -> void:
	if not is_progress_time_activation(): return
	var count := consume_interval(interval_seconds) # 発火数
	recover(source, recovery * count, recovery_rate * count)
