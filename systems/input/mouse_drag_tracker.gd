class_name MouseDragTracker
extends Node

signal dragging_started
signal dragging_ended
signal state_changed(state: State)

enum State {
	IDLE,
	DRAGGING,
}

var _drag_owner_ids: Dictionary[int, bool] = {}


# ドラッグ開始
func begin_drag(owner: Object) -> void:
	assert(owner != null, "MouseDragTracker.begin_drag requires an owner.")
	var was_dragging := is_dragging()
	_drag_owner_ids[owner.get_instance_id()] = true
	if was_dragging:
		return
	dragging_started.emit()
	state_changed.emit(State.DRAGGING)


# ドラッグ終了
func end_drag(owner: Object) -> void:
	if owner == null:
		return
	var owner_id := owner.get_instance_id()
	if not _drag_owner_ids.erase(owner_id) or is_dragging():
		return
	dragging_ended.emit()
	state_changed.emit(State.IDLE)


# ドラッグ状態取得
func get_state() -> State:
	return State.DRAGGING if is_dragging() else State.IDLE


# ドラッグ中判定
func is_dragging() -> bool:
	return not _drag_owner_ids.is_empty()
