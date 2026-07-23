extends SceneTree

var _failures := 0
var _started_count := 0
var _ended_count := 0
var _states: Array[MouseDragTracker.State] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tracker := MouseDragTracker.new()
	var first_owner := Node.new()
	var second_owner := Node.new()
	tracker.dragging_started.connect(_on_dragging_started)
	tracker.dragging_ended.connect(_on_dragging_ended)
	tracker.state_changed.connect(_on_state_changed)

	_expect(tracker.get_state() == MouseDragTracker.State.IDLE, "初期状態は待機中")
	_expect(not tracker.is_dragging(), "初期状態ではドラッグ中ではない")

	tracker.begin_drag(first_owner)
	_expect(tracker.is_dragging(), "所有者が開始するとドラッグ中になる")
	_expect(tracker.get_state() == MouseDragTracker.State.DRAGGING, "ドラッグ状態を取得できる")
	_expect(_started_count == 1, "最初の開始時だけ開始signalを送る")

	tracker.begin_drag(first_owner)
	tracker.begin_drag(second_owner)
	_expect(_started_count == 1, "重複または追加所有者では開始signalを重複しない")

	tracker.end_drag(first_owner)
	_expect(tracker.is_dragging(), "別の所有者が残る間はドラッグ中を維持する")
	_expect(_ended_count == 0, "別の所有者が残る間は終了signalを送らない")

	tracker.end_drag(second_owner)
	_expect(not tracker.is_dragging(), "最後の所有者が終了すると待機中へ戻る")
	_expect(tracker.get_state() == MouseDragTracker.State.IDLE, "待機状態を取得できる")
	_expect(_ended_count == 1, "最後の終了時だけ終了signalを送る")
	_expect(
		_states == [MouseDragTracker.State.DRAGGING, MouseDragTracker.State.IDLE],
		"状態変化を開始・終了の順で通知する"
	)

	tracker.end_drag(second_owner)
	_expect(_ended_count == 1, "重複終了では終了signalを重複しない")

	tracker.free()
	first_owner.free()
	second_owner.free()
	quit(_failures)


func _on_dragging_started() -> void:
	_started_count += 1


func _on_dragging_ended() -> void:
	_ended_count += 1


func _on_state_changed(state: MouseDragTracker.State) -> void:
	_states.append(state)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MouseDragTrackerTest: %s" % message)
