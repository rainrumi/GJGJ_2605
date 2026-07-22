class_name GameInputController
extends Node

signal enemy_drag_started(enemy: Enemy, pointer_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i)
signal enemy_drag_moved(enemy: Enemy, pointer_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i)
signal enemy_drag_released(enemy: Enemy, pointer_position: Vector2)
signal enemy_hover_requested(enemy: Enemy)
signal enemy_rotation_requested(enemy: Enemy)

const LONG_PRESS_DURATION_MSEC := 500

var _active := false
var _enemies: Array[Enemy] = []
var _pressed_enemy: Enemy
var _press_started_msec := 0
var _press_position := Vector2.ZERO
var _dragging_enemy: Enemy
var _drag_offset := Vector2.ZERO
var _drag_grab_cell := Vector2i.ZERO
var _hovered_enemy: Enemy


# setup処理
func setup(enemies: Array[Enemy]) -> void:
	_enemies = enemies


# active設定
func set_active(value: bool) -> void:
	_active = value
	if not _active:
		clear_drag()
		_request_hover(null)


# ドラッグ消去
func clear_drag() -> void:
	_pressed_enemy = null
	_press_started_msec = 0
	_press_position = Vector2.ZERO
	_dragging_enemy = null
	_drag_offset = Vector2.ZERO
	_drag_grab_cell = Vector2i.ZERO


# 毎フレーム処理
func _process(_delta: float) -> void:
	if not _active:
		return
	# マウス位置
	var mouse_position := get_viewport().get_mouse_position()
	if _pressed_enemy != null and _has_long_press_elapsed():
		_start_drag(mouse_position)
	if _dragging_enemy != null:
		enemy_drag_moved.emit(_dragging_enemy, mouse_position, _drag_offset, _drag_grab_cell)
		return
	if _pressed_enemy != null:
		return
	_update_hover(mouse_position)


# 入力処理
func _input(event: InputEvent) -> void:
	if not _active:
		return
	if event is InputEventMouseButton:
		# マウスボタン
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse_button.pressed:
			_handle_press(mouse_button.position)
		else:
			_handle_release(mouse_button.position)
	elif event is InputEventMouseMotion and _pressed_enemy != null and _dragging_enemy == null:
		var mouse_motion := event as InputEventMouseMotion
		if not mouse_motion.position.is_equal_approx(_press_position):
			_start_drag(mouse_motion.position)


# handlepress処理
func _handle_press(mouse_position: Vector2) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		# 敵値
		var enemy := _enemies[i]
		if not _can_point_enemy(enemy, mouse_position):
			continue
		_pressed_enemy = enemy
		_press_started_msec = Time.get_ticks_msec()
		_press_position = mouse_position
		_drag_offset = enemy.global_position - mouse_position
		_drag_grab_cell = enemy.get_grab_cell(mouse_position)
		_request_hover(null)
		return


# handlerelease処理
func _handle_release(mouse_position: Vector2) -> void:
	if _pressed_enemy != null and _has_long_press_elapsed():
		_start_drag(mouse_position)
	if _dragging_enemy != null:
		# released敵
		var released_enemy := _dragging_enemy
		clear_drag()
		enemy_drag_released.emit(released_enemy, mouse_position)
		return
	if _pressed_enemy == null:
		return
	var clicked_enemy := _pressed_enemy
	clear_drag()
	enemy_rotation_requested.emit(clicked_enemy)


# ドラッグ開始
func _start_drag(mouse_position: Vector2) -> void:
	if _pressed_enemy == null or not is_instance_valid(_pressed_enemy):
		clear_drag()
		return
	_dragging_enemy = _pressed_enemy
	_pressed_enemy = null
	enemy_drag_started.emit(_dragging_enemy, mouse_position, _drag_offset, _drag_grab_cell)


# 長押し経過判定
func _has_long_press_elapsed() -> bool:
	return Time.get_ticks_msec() - _press_started_msec >= LONG_PRESS_DURATION_MSEC


# hover更新
func _update_hover(mouse_position: Vector2) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		# 敵値
		var enemy := _enemies[i]
		if _can_point_enemy(enemy, mouse_position):
			_request_hover(enemy)
			return
	_request_hover(null)


# hover要求
func _request_hover(enemy: Enemy) -> void:
	if _hovered_enemy == enemy:
		return
	_hovered_enemy = enemy
	enemy_hover_requested.emit(enemy)


# point敵判定
func _can_point_enemy(enemy: Enemy, mouse_position: Vector2) -> bool:
	return enemy != null and enemy.visible and enemy.can_drag() and enemy.get_global_rect().has_point(mouse_position)
