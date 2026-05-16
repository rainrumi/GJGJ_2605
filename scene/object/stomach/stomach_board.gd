class_name StomachBoard
extends Node2D

@export var columns := 4
@export var rows := 5
@export var edge_overlap := 1.0

@onready var grid_frame: NinePatchRect = $grid_frame
@onready var frame: NinePatchRect = $frame

var _grid_origin := Vector2.ZERO
var _cell_size := 0.0
var _grid_step := 0.0
var _grid_frame_area_position := Vector2.ZERO
var _grid_frame_area_size := Vector2.ZERO
var _frame_base_position := Vector2.ZERO
var _frame_base_size := Vector2.ZERO
var _preview_sprite: Sprite2D


func _ready() -> void:
	_capture_grid_frame_area()
	_configure_grid()
	_create_preview()


func get_capacity() -> int:
	return columns * rows


func set_grid_size(new_columns: int, new_rows: int) -> void:
	columns = maxi(1, new_columns)
	rows = maxi(1, new_rows)
	hide_preview()
	_configure_grid()


func get_span_size(cell_count: int) -> float:
	return float(cell_count) * _cell_size - float(cell_count - 1) * edge_overlap


func contains_global_position(global_position: Vector2) -> bool:
	return frame.get_global_rect().has_point(global_position)


func get_drop_cell(enemy: Enemy, mouse_position: Vector2, grab_cell: Vector2i, active_enemies: Array[Enemy]) -> Vector2i:
	var target_cell: Vector2i = _get_nearest_cell(mouse_position) - grab_cell
	target_cell.y = 0
	if not can_place(enemy, target_cell, active_enemies):
		return target_cell
	var drop_cell: Vector2i = target_cell
	while can_place(enemy, drop_cell + Vector2i(0, 1), active_enemies):
		drop_cell += Vector2i(0, 1)
	return drop_cell


func can_place(enemy: Enemy, top_left: Vector2i, active_enemies: Array[Enemy]) -> bool:
	if not _is_within_bounds(enemy, top_left):
		return false
	var occupied_cells: Array[Vector2i] = enemy.get_occupied_cells(top_left)
	for other: Enemy in active_enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		for cell: Vector2i in occupied_cells:
			if other.get_occupied_cells(other.stomach_cell).has(cell):
				return false
	return true


func place_enemy(enemy: Enemy, top_left: Vector2i) -> void:
	enemy.set_stomach_cell(top_left)
	enemy.global_position = get_global_position_for_cell(top_left, enemy.get_stomach_size())


func apply_gravity(active_enemies: Array[Enemy]) -> void:
	var moved := true
	while moved:
		moved = false
		var sorted_enemies: Array[Enemy] = active_enemies.duplicate()
		sorted_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
			return a.get_bottom_row(a.stomach_cell) > b.get_bottom_row(b.stomach_cell)
		)
		for enemy: Enemy in sorted_enemies:
			if not enemy.is_active_in_stomach() or not enemy.can_apply_gravity():
				continue
			var next_cell: Vector2i = enemy.stomach_cell + Vector2i(0, 1)
			if not can_place(enemy, next_cell, active_enemies):
				continue
			place_enemy(enemy, next_cell)
			moved = true
	for enemy: Enemy in active_enemies:
		enemy.clear_gravity_lock()


func get_current_fullness(active_enemies: Array[Enemy]) -> int:
	var fullness := 0
	for enemy: Enemy in active_enemies:
		if enemy.is_active_in_stomach():
			fullness += enemy.get_size()
	return fullness


func has_bottom_touching_enemy(active_enemies: Array[Enemy]) -> bool:
	for enemy: Enemy in active_enemies:
		if get_bottom_row_cell_count(enemy) > 0:
			return true
	return false


func get_bottom_row_cell_count(enemy: Enemy) -> int:
	if not enemy.can_take_stomach_turn():
		return 0
	var count := 0
	for cell: Vector2i in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.y == rows - 1:
			count += 1
	return count


func show_preview(enemy: Enemy, mouse_position: Vector2, grab_cell: Vector2i, active_enemies: Array[Enemy]) -> void:
	if _preview_sprite == null:
		return
	if not contains_global_position(mouse_position):
		hide_preview()
		return
	var top_left: Vector2i = get_drop_cell(enemy, mouse_position, grab_cell, active_enemies)
	if not _is_within_bounds(enemy, top_left):
		hide_preview()
		return
	_preview_sprite.texture = enemy.sprite.texture
	_preview_sprite.scale = enemy.sprite.scale
	_preview_sprite.global_position = get_global_position_for_cell(top_left, enemy.get_stomach_size())
	_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	_preview_sprite.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	if not can_place(enemy, top_left, active_enemies):
		_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.32)
	_preview_sprite.visible = true


func hide_preview() -> void:
	if _preview_sprite != null:
		_preview_sprite.visible = false


func get_global_position_for_cell(top_left: Vector2i, size: Vector2i) -> Vector2:
	var local_position: Vector2 = _grid_origin + Vector2(
		float(top_left.x) * _grid_step + get_span_size(size.x) * 0.5,
		float(top_left.y) * _grid_step + get_span_size(size.y) * 0.5
	)
	return to_global(local_position)


func _configure_grid() -> void:
	var cell_size_columns := maxi(columns, 4)
	var cell_size_rows := maxi(rows, 4)
	var horizontal_cell_size := (_grid_frame_area_size.x + float(cell_size_columns - 1) * edge_overlap) / float(cell_size_columns)
	var vertical_cell_size := (_grid_frame_area_size.y + float(cell_size_rows - 1) * edge_overlap) / float(cell_size_rows)
	var is_horizontal_limited := horizontal_cell_size <= vertical_cell_size
	_cell_size = floorf(minf(horizontal_cell_size, vertical_cell_size))
	_cell_size = maxf(1.0, _cell_size)
	_grid_step = _cell_size - edge_overlap
	var grid_size: Vector2 = Vector2(
		float(columns) * _cell_size - float(columns - 1) * edge_overlap,
		float(rows) * _cell_size - float(rows - 1) * edge_overlap
	)
	var active_grid_area_position := _get_active_grid_area_position(grid_size, is_horizontal_limited)
	var active_grid_area_size := _get_active_grid_area_size(grid_size, is_horizontal_limited)
	_grid_origin = (active_grid_area_position + (active_grid_area_size - grid_size) * 0.5).round()
	_update_frame_size(active_grid_area_size)
	for child: Node in get_children():
		if child is NinePatchRect and String(child.name).begins_with("grid_frame_"):
			remove_child(child)
			child.queue_free()
	for row in range(rows):
		for column in range(columns):
			var cell: NinePatchRect = grid_frame
			if row != 0 or column != 0:
				cell = grid_frame.duplicate() as NinePatchRect
				cell.name = "grid_frame_%d_%d" % [column, row]
				add_child(cell)
			cell.position = (_grid_origin + Vector2(column, row) * _grid_step).round()
			cell.size = Vector2(_cell_size, _cell_size)
	frame.z_index = 10


func _capture_grid_frame_area() -> void:
	_grid_frame_area_position = grid_frame.position
	_grid_frame_area_size = grid_frame.size
	_frame_base_position = frame.position
	_frame_base_size = frame.size


func _get_active_grid_area_size(grid_size: Vector2, is_horizontal_limited: bool) -> Vector2:
	var active_size := _grid_frame_area_size
	if columns < 4 or (rows > 5 and not is_horizontal_limited):
		active_size.x = grid_size.x
	if rows < 4 or (columns > 4 and is_horizontal_limited):
		active_size.y = grid_size.y
	return active_size.round()


func _get_active_grid_area_position(grid_size: Vector2, is_horizontal_limited: bool) -> Vector2:
	var active_position := _grid_frame_area_position
	if columns < 4 or (rows > 5 and not is_horizontal_limited):
		active_position.x = _grid_frame_area_position.x + (_grid_frame_area_size.x - grid_size.x) * 0.5
	if rows < 4 or (columns > 4 and is_horizontal_limited):
		active_position.y = _grid_frame_area_position.y + (_grid_frame_area_size.y - grid_size.y) * 0.5
	return active_position.round()


func _update_frame_size(active_grid_area_size: Vector2) -> void:
	var left_margin := _grid_frame_area_position.x - _frame_base_position.x
	var top_margin := _grid_frame_area_position.y - _frame_base_position.y
	var right_margin := _frame_base_size.x - left_margin - _grid_frame_area_size.x
	var bottom_margin := _frame_base_size.y - top_margin - _grid_frame_area_size.y
	var target_size := _frame_base_size
	if not is_equal_approx(active_grid_area_size.x, _grid_frame_area_size.x):
		target_size.x = active_grid_area_size.x + left_margin + right_margin
	if not is_equal_approx(active_grid_area_size.y, _grid_frame_area_size.y):
		target_size.y = active_grid_area_size.y + top_margin + bottom_margin
	frame.position = (_frame_base_position + (_frame_base_size - target_size) * 0.5).round()
	frame.size = target_size.round()


func _create_preview() -> void:
	_preview_sprite = Sprite2D.new()
	_preview_sprite.name = "EnemyPlacementPreview"
	_preview_sprite.visible = false
	_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	_preview_sprite.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	_preview_sprite.z_index = 5
	add_child(_preview_sprite)


func _get_nearest_cell(global_position: Vector2) -> Vector2i:
	var local_position: Vector2 = to_local(global_position)
	var centered_position: Vector2 = local_position - _grid_origin - Vector2.ONE * _cell_size * 0.5
	return Vector2i(
		clampi(roundi(centered_position.x / _grid_step), 0, columns - 1),
		clampi(roundi(centered_position.y / _grid_step), 0, rows - 1)
	)


func _is_within_bounds(enemy: Enemy, top_left: Vector2i) -> bool:
	for cell: Vector2i in enemy.get_occupied_cells(top_left):
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
			return false
	return true
