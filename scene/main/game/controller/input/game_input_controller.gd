class_name GameInputController
extends Node

signal enemy_drag_started(enemy: Enemy, pointer_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i)
signal enemy_drag_moved(enemy: Enemy, pointer_position: Vector2, pointer_offset: Vector2, grab_cell: Vector2i)
signal enemy_drag_released(enemy: Enemy, pointer_position: Vector2)
signal enemy_hover_requested(enemy: Enemy)
signal enemy_rotation_requested(enemy: Enemy)

var _active := false
var _enemies: Array[Enemy] = []
var _dragging_enemy: Enemy
var _drag_offset := Vector2.ZERO
var _drag_grab_cell := Vector2i.ZERO
var _hovered_enemy: Enemy
var _rotation_mode_enabled := false


# setup処理
func setup(enemies: Array[Enemy]) -> void:
	_enemies = enemies


# active設定
func set_active(value: bool) -> void:
	_active = value
	if not _active:
		clear_drag()
		_request_hover(null)


# 回転モード設定
func set_rotation_mode_enabled(value: bool) -> void:
	_rotation_mode_enabled = value
	if _rotation_mode_enabled:
		clear_drag()


# 回転モード判定
func is_rotation_mode_enabled() -> bool:
	return _rotation_mode_enabled


# ドラッグ消去
func clear_drag() -> void:
	_dragging_enemy = null
	_drag_offset = Vector2.ZERO
	_drag_grab_cell = Vector2i.ZERO


# 毎フレーム処理
func _process(_delta: float) -> void:
	if not _active:
		return
	# マウス位置
	var mouse_position := get_viewport().get_mouse_position()
	if _dragging_enemy != null:
		enemy_drag_moved.emit(_dragging_enemy, mouse_position, _drag_offset, _drag_grab_cell)
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


# handlepress処理
func _handle_press(mouse_position: Vector2) -> void:
	for i in range(_enemies.size() - 1, -1, -1):
		# 敵値
		var enemy := _enemies[i]
		if not _can_point_enemy(enemy, mouse_position):
			continue
		if _rotation_mode_enabled:
			_request_hover(null)
			enemy_rotation_requested.emit(enemy)
			return
		_dragging_enemy = enemy
		_drag_offset = enemy.global_position - mouse_position
		_drag_grab_cell = enemy.get_grab_cell(mouse_position)
		_request_hover(null)
		enemy_drag_started.emit(enemy, mouse_position, _drag_offset, _drag_grab_cell)
		return


# handlerelease処理
func _handle_release(mouse_position: Vector2) -> void:
	if _dragging_enemy == null:
		return
	# released敵
	var released_enemy := _dragging_enemy
	clear_drag()
	enemy_drag_released.emit(released_enemy, mouse_position)


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
