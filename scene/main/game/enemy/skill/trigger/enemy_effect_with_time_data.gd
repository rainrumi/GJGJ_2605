class_name EnemyEffectWithTimeData
extends EnemyNodeEffect


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
