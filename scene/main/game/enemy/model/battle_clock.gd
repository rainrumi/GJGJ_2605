class_name BattleClock
extends RefCounted

signal progressed(elapsed_seconds: int, current_seconds: int)

var elapsed_seconds := 0 # 経過秒数
var current_seconds := 0 # 現在秒数


# 時刻設定
func set_time(elapsed: int, current: int) -> void:
	elapsed_seconds = maxi(0, elapsed)
	current_seconds = maxi(0, current)
	progressed.emit(elapsed_seconds, current_seconds)
