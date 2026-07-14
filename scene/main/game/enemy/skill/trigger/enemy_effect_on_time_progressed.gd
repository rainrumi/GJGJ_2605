class_name EnemyEffectOnTimeProgressed
extends EnemyEffect


# 時間発動値取得
func get_time_activation() -> TimeActivationData:
	return get_activation_data() as TimeActivationData


# 経過秒数取得
func get_activation_elapsed_seconds() -> int:
	var data := get_time_activation() # 時間発動値
	return data.elapsed_seconds if data != null else 0


# 現在秒数取得
func get_activation_current_seconds() -> int:
	var data := get_time_activation() # 時間発動値
	return data.current_seconds if data != null else 0


# 間隔発火数取得
func consume_interval(interval_seconds: int) -> int:
	if interval_seconds <= 0:
		return 0
	var accumulated := get_state_int("elapsed_seconds") + get_activation_elapsed_seconds() # 累積秒
	var count := int(accumulated / interval_seconds) # 発火数
	set_state("elapsed_seconds", accumulated % interval_seconds)
	return count
