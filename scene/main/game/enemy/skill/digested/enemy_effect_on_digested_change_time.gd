class_name EnemyEffectOnDigestedChangeTime
extends EnemyEffect


# 発動種別取得
func get_activation_mask() -> int:
	return ACTIVATION_DIGESTED

# 時刻秒差分
@export var seconds_delta := 0

# 効果適用
func apply() -> void:
	if is_digested_activation() and get_activation_target() == source: add_time_delta(seconds_delta)
