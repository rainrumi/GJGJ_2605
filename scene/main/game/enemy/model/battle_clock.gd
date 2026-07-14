class_name BattleClock
extends RefCounted

signal progressed(elapsed_seconds: int, current_seconds: int)
signal change_requested(delta_seconds: int)
signal battle_started(data: BattleStartActivationData)
signal turn_started(data: TurnStartActivationData)
signal progress_resolved(data: ProgressTimeActivationData)

var elapsed_seconds := 0 # 経過秒数
var current_seconds := 0 # 現在秒数
var _pending_delta_seconds := 0 # 待機時刻差分


# 時刻設定
func set_time(elapsed: int, current: int) -> void:
	elapsed_seconds = maxi(0, elapsed)
	current_seconds = maxi(0, current)
	progressed.emit(elapsed_seconds, current_seconds)


# 時刻差分追加
func request_change(delta_seconds: int) -> void:
	_pending_delta_seconds += delta_seconds
	change_requested.emit(delta_seconds)


# 時刻差分消費
func consume_change() -> int:
	var value := _pending_delta_seconds # 時刻差分
	_pending_delta_seconds = 0
	return value


# 時刻状態初期化
func reset() -> void:
	elapsed_seconds = 0
	current_seconds = 0
	_pending_delta_seconds = 0


# 戦闘開始通知
func notify_battle_started(data: BattleStartActivationData) -> void:
	battle_started.emit(data)


# ターン開始通知
func notify_turn_started(data: TurnStartActivationData) -> void:
	set_time(data.elapsed_seconds, data.current_seconds)
	turn_started.emit(data)


# 時間進行通知
func notify_progress_resolved(data: ProgressTimeActivationData) -> void:
	set_time(data.elapsed_seconds, data.current_seconds)
	progress_resolved.emit(data)
