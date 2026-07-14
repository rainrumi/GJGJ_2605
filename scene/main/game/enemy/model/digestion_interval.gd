class_name DigestionInterval
extends RefCounted

signal changed

var seconds_delta := 0 # 秒差分
var rate := 0.0 # 割合差分


# 間隔初期化
func reset() -> void:
	seconds_delta = 0
	rate = 0.0
	changed.emit()


# 秒差分追加
func add_seconds(value: int) -> void:
	seconds_delta += value
	changed.emit()


# 割合追加
func add_rate(value: float) -> void:
	rate += value
	changed.emit()


# 補正間隔取得
func resolve(base_seconds: int) -> int:
	return maxi(1, roundi(float(base_seconds + seconds_delta) * (1.0 + rate)))
