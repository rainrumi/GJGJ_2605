class_name BeatConductor
extends Node

signal beat(beat_index: int, song_time: float)
signal subdivision(subdivision_index: int, song_time: float)
signal scheduled_event_executed(event_id: int, song_time: float)
signal playback_started()
signal playback_stopped()

@export var bpm: float = 108.0
@export var beat_offset: float = 0.0
@export var subdivisions: int = 4
@export var auto_play: bool = true
@export var use_output_latency_compensation: bool = true
@export var bgm_stream: AudioStream
@export var debug_print_beats: bool = false

@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

var _beat_interval := 0.0
var _subdivision_interval := 0.0
var _last_beat_index := -1
var _last_subdivision_index := -1
var _event_id_counter := 0
var _scheduled_events: Array[Dictionary] = []
var _cached_output_latency := 0.0


# 初期化
func _ready() -> void:
	_recalculate_intervals()
	if audio_player == null:
		push_error("BeatConductor requires an AudioStreamPlayer child.")
		return
	if bgm_stream != null:
		audio_player.stream = bgm_stream
	_cached_output_latency = AudioServer.get_output_latency()
	if auto_play and audio_player.stream != null:
		play()


# 毎フレーム処理
func _process(_delta: float) -> void:
	if audio_player == null or not audio_player.playing:
		return
	# 曲時間
	var song_time := get_song_time()
	if song_time < 0.0:
		return
	_emit_rhythm_signals(song_time)
	_process_scheduled_events(song_time)


# 対象再生
func play(from_position: float = 0.0) -> void:
	if audio_player == null:
		return
	_last_beat_index = -1
	_last_subdivision_index = -1
	audio_player.play(from_position)
	playback_started.emit()


# 対象停止
func stop() -> void:
	if audio_player == null:
		return
	audio_player.stop()
	clear_scheduled_events()
	_last_beat_index = -1
	_last_subdivision_index = -1
	playback_stopped.emit()


# 対象一時停止
func pause() -> void:
	if audio_player != null:
		audio_player.stream_paused = true


# 対象再開
func resume() -> void:
	if audio_player != null:
		audio_player.stream_paused = false


# 曲時間取得
func get_song_time() -> float:
	if audio_player == null:
		return 0.0
	# 時間
	var time := audio_player.get_playback_position()
	time += AudioServer.get_time_since_last_mix()
	if use_output_latency_compensation:
		time -= _cached_output_latency
	time -= beat_offset
	return time


# 拍間隔取得
func get_beat_interval() -> float:
	return _beat_interval


# subdivision間隔取得
func get_subdivision_interval() -> float:
	return _subdivision_interval


# 拍番号取得
func get_current_beat_index() -> int:
	# 曲時間
	var song_time := get_song_time()
	if song_time < 0.0:
		return -1
	return int(floor(song_time / _beat_interval))


# subdivision番号取得
func get_current_subdivision_index() -> int:
	# 曲時間
	var song_time := get_song_time()
	if song_time < 0.0:
		return -1
	return int(floor(song_time / _subdivision_interval))


# 拍時間取得
func get_next_beat_time() -> float:
	# 曲時間
	var song_time := maxf(get_song_time(), 0.0)
	return _get_next_interval_time(song_time, _beat_interval)


# subdivision時間取得
func get_next_subdivision_time() -> float:
	# 曲時間
	var song_time := maxf(get_song_time(), 0.0)
	return _get_next_interval_time(song_time, _subdivision_interval)


# グリッド時間取得
func get_next_grid_time(subdivision_count: int) -> float:
	# 安全subdivision数
	var safe_subdivision_count := maxi(subdivision_count, 1)
	# 間隔
	var interval := _beat_interval / float(safe_subdivision_count)
	# 曲時間
	var song_time := maxf(get_song_time(), 0.0)
	return _get_next_interval_time(song_time, interval)


# at曲時間予約
func schedule_at_song_time(song_time: float, callback: Callable) -> int:
	_event_id_counter += 1
	_scheduled_events.append({
		"id": _event_id_counter,
		"time": song_time,
		"callback": callback,
		"cancelled": false,
	})
	_scheduled_events.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["time"]) < float(b["time"])
	)
	return _event_id_counter


# on拍予約
func schedule_on_next_beat(callback: Callable) -> int:
	return schedule_at_song_time(get_next_beat_time(), callback)


# until拍待機
func wait_until_next_beat() -> void:
	# イベントID
	var event_id := schedule_on_next_beat(Callable())
	while true:
		# signalargs
		var signal_args = await scheduled_event_executed
		# executedイベントID
		var executed_event_id := _get_signal_event_id(signal_args)
		if executed_event_id == event_id:
			return


# onsubdivision予約
func schedule_on_next_subdivision(callback: Callable) -> int:
	return schedule_at_song_time(get_next_subdivision_time(), callback)


# onグリッド予約
func schedule_on_next_grid(subdivision_count: int, callback: Callable) -> int:
	return schedule_at_song_time(get_next_grid_time(subdivision_count), callback)


# イベント取消
func cancel_event(event_id: int) -> void:
	for event in _scheduled_events:
		if int(event["id"]) == event_id:
			event["cancelled"] = true
			return


# scheduledevents消去
func clear_scheduled_events() -> void:
	_scheduled_events.clear()


# intervals再計算
func _recalculate_intervals() -> void:
	# 安全bpm
	var safe_bpm := maxf(bpm, 1.0)
	# 安全subdivisions
	var safe_subdivisions := maxi(subdivisions, 1)
	_beat_interval = 60.0 / safe_bpm
	_subdivision_interval = _beat_interval / float(safe_subdivisions)


# rhythmsignals発火
func _emit_rhythm_signals(song_time: float) -> void:
	# 拍番号
	var beat_index := int(floor(song_time / _beat_interval))
	if beat_index != _last_beat_index:
		_last_beat_index = beat_index
		beat.emit(beat_index, song_time)
		if debug_print_beats:
			print("beat:", beat_index, " song_time:", song_time)
	# subdivision番号
	var subdivision_index := int(floor(song_time / _subdivision_interval))
	if subdivision_index != _last_subdivision_index:
		_last_subdivision_index = subdivision_index
		subdivision.emit(subdivision_index, song_time)


# scheduledevents処理
func _process_scheduled_events(song_time: float) -> void:
	# executedids
	var executed_ids: Array[int] = []
	for event in _scheduled_events:
		# イベント時間
		var event_time := float(event["time"])
		if event_time > song_time:
			break
		executed_ids.append(int(event["id"]))
		if not bool(event["cancelled"]):
			# コール
			var callback: Callable = event["callback"]
			if callback.is_valid():
				callback.call()
			scheduled_event_executed.emit(int(event["id"]), song_time)
	if executed_ids.is_empty():
		return
	_scheduled_events = _scheduled_events.filter(func(event: Dictionary) -> bool:
		return not executed_ids.has(int(event["id"]))
	)


# signalイベントID取得
func _get_signal_event_id(signal_args: Variant) -> int:
	if signal_args is Array and not signal_args.is_empty():
		return int(signal_args[0])
	return int(signal_args)


# 間隔時間取得
func _get_next_interval_time(song_time: float, interval: float) -> float:
	if interval <= 0.0:
		return song_time
	# 間隔番号
	var interval_index := floori(song_time / interval) + 1
	return float(interval_index) * interval
