extends ScrollContainer

const SCROLL_BAR_SCRIPT := preload("res://scene/main/stage_select/choice/stage_choices_scroll_bar.gd")
const DRAG_DEADZONE := 8.0

@onready var _mouse_drag_state: MouseDragTracker = get_node("/root/MouseDragState")

var _press_position := Vector2.ZERO
var _scroll_at_press := 0
var _pressing := false
var _dragging := false


# 初期化
func _ready() -> void:
	# scrollbar
	var scroll_bar := get_v_scroll_bar()
	scroll_bar.set_script(SCROLL_BAR_SCRIPT)
	scroll_bar.call("match_main_background_color")
	reset_to_top()


func reset_to_top() -> void:
	scroll_vertical = 0
	call_deferred("_apply_top_scroll")


func _apply_top_scroll() -> void:
	scroll_vertical = 0


# 入力処理
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_begin_press(mouse_button.position)
		else:
			_end_press()
		return
	if event is InputEventMouseMotion and _pressing:
		_update_drag((event as InputEventMouseMotion).position)


# tree終了処理
func _exit_tree() -> void:
	_pressing = false
	_finish_drag()


# 押下開始
func _begin_press(mouse_position: Vector2) -> void:
	if not get_global_rect().has_point(mouse_position):
		return
	_press_position = mouse_position
	_scroll_at_press = scroll_vertical
	_pressing = true


# ドラッグ更新
func _update_drag(mouse_position: Vector2) -> void:
	var drag_offset := mouse_position - _press_position
	if not _dragging:
		if absf(drag_offset.y) < DRAG_DEADZONE:
			return
		_dragging = true
		_mouse_drag_state.begin_drag(self)
	scroll_vertical = _scroll_at_press - roundi(drag_offset.y)
	get_viewport().set_input_as_handled()


# 押下終了
func _end_press() -> void:
	_pressing = false
	if not _dragging:
		return
	call_deferred("_finish_drag")


# ドラッグ終了
func _finish_drag() -> void:
	if not _dragging:
		return
	_dragging = false
	_mouse_drag_state.end_drag(self)
