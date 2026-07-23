class_name StomachBoard
extends Node2D


@export var columns := 4
@export var rows := 5
@export var edge_overlap := 1.0

@onready var grid_frame: NinePatchRect = $grid_frame
@onready var frame: NinePatchRect = $frame
@onready var line_mesh: StomachLineMesh = $line

var _grid_origin := Vector2.ZERO
var _cell_size := 0.0
var _grid_step := 0.0
var _grid_frame_area_position := Vector2.ZERO
var _grid_frame_area_size := Vector2.ZERO
var _frame_base_position := Vector2.ZERO
var _frame_base_size := Vector2.ZERO
var _line_base_position := Vector2.ZERO
var _line_base_size := Vector2.ZERO
var _preview_sprite: Sprite2D
var _acid_line_rows := 1 # 消化行数


# 初期化
func _ready() -> void:
	_capture_grid_frame_area()
	_configure_grid()
	_create_preview()


# capacity取得
func get_capacity() -> int:
	return columns * rows


# グリッドサイズ設定
func set_grid_size(new_columns: int, new_rows: int) -> void:
	columns = maxi(1, new_columns)
	rows = maxi(1, new_rows)
	_acid_line_rows = clampi(_acid_line_rows, 1, rows)
	hide_preview()
	_configure_grid()


# 消化行数設定
func set_acid_line_rows(value: int) -> void:
	_acid_line_rows = clampi(value, 1, rows)
	_update_line_mesh()


# 消化行数加算
func add_acid_line_rows(delta: int) -> void:
	set_acid_line_rows(_acid_line_rows + delta)


# 消化行数取得
func get_acid_line_rows() -> int:
	return _acid_line_rows


# spanサイズ取得
func get_span_size(cell_count: int) -> float:
	return float(cell_count) * _cell_size - float(cell_count - 1) * edge_overlap


# containsglobal位置処理
func contains_global_position(global_position: Vector2) -> bool:
	return frame.get_global_rect().has_point(global_position)


# dropセル取得
func get_drop_cell(enemy: Enemy, mouse_position: Vector2, grab_cell: Vector2i, active_enemies: Array[Enemy]) -> Vector2i:
	# 対象セル
	var target_cell: Vector2i = _get_nearest_cell(mouse_position) - grab_cell
	target_cell.y = 0
	if not can_place(enemy, target_cell, active_enemies):
		return target_cell
	# dropセル
	var drop_cell: Vector2i = target_cell
	while can_place(enemy, drop_cell + Vector2i(0, 1), active_enemies):
		drop_cell += Vector2i(0, 1)
	return drop_cell


# place判定
func can_place(enemy: Enemy, top_left: Vector2i, active_enemies: Array[Enemy]) -> bool:
	return _can_place_shape(enemy, top_left, enemy.get_stomach_shape(), active_enemies)


# 90度右回転試行
func try_rotate_enemy_clockwise(enemy: Enemy, active_enemies: Array[Enemy]) -> bool:
	if enemy == null:
		return false
	if enemy.is_enemy() and enemy.is_active_in_stomach():
		return false
	var rotated_size := enemy.get_clockwise_rotated_stomach_size()
	var rotated_shape := enemy.get_clockwise_rotated_stomach_shape()
	if enemy.is_active_in_stomach() and not _can_place_shape(
		enemy,
		enemy.stomach_cell,
		rotated_shape,
		active_enemies
	):
		return false
	enemy.rotate_stomach_footprint_clockwise(Vector2(
		get_span_size(rotated_size.x),
		get_span_size(rotated_size.y)
	))
	if enemy.is_active_in_stomach():
		place_enemy(enemy, enemy.stomach_cell)
	return true


# 指定形状の配置判定
func _can_place_shape(
	enemy: Enemy,
	top_left: Vector2i,
	shape: Array[Vector2i],
	active_enemies: Array[Enemy]
) -> bool:
	var occupied_cells: Array[Vector2i] = []
	for offset: Vector2i in shape:
		var cell := top_left + offset
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
			return false
		occupied_cells.append(cell)
	for other: Enemy in active_enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		for cell: Vector2i in occupied_cells:
			if other.get_occupied_cells(other.stomach_cell).has(cell):
				return false
	return true


# place敵処理
func place_enemy(enemy: Enemy, top_left: Vector2i) -> void:
	enemy.set_stomach_cell(top_left)
	enemy.global_position = get_global_position_for_cell(top_left, enemy.get_stomach_size())


# gravity適用
func apply_gravity(active_enemies: Array[Enemy]) -> void:
	# moved
	var moved := true
	while moved:
		moved = false
		# sorted敵
		var sorted_enemies: Array[Enemy] = active_enemies.duplicate()
		sorted_enemies.sort_custom(func(a: Enemy, b: Enemy) -> bool:
			return a.get_bottom_row(a.stomach_cell) > b.get_bottom_row(b.stomach_cell)
		)
		for enemy: Enemy in sorted_enemies:
			if not enemy.is_active_in_stomach() or not enemy.can_apply_gravity():
				continue
			# セル
			var next_cell: Vector2i = enemy.stomach_cell + Vector2i(0, 1)
			if not can_place(enemy, next_cell, active_enemies):
				continue
			place_enemy(enemy, next_cell)
			moved = true
	for enemy: Enemy in active_enemies:
		enemy.clear_gravity_lock()


# fullness取得
func get_current_fullness(active_enemies: Array[Enemy]) -> int:
	# fullness
	var fullness := 0
	for enemy: Enemy in active_enemies:
		if enemy.is_active_in_stomach():
			fullness += enemy.get_size()
	return fullness


# bottomtouching敵判定
func has_bottom_touching_enemy(active_enemies: Array[Enemy]) -> bool:
	for enemy: Enemy in active_enemies:
		if get_bottom_row_cell_count(enemy) > 0:
			return true
	return false


# bottom行セル数取得
func get_bottom_row_cell_count(enemy: Enemy) -> int:
	if not enemy.can_take_stomach_turn():
		return 0
	# 数値
	var count := 0
	var line_top_row := maxi(0, rows - _acid_line_rows) # ライン上端
	for cell: Vector2i in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.y >= line_top_row:
			count += 1
	return count


# preview表示
func show_preview(enemy: Enemy, mouse_position: Vector2, grab_cell: Vector2i, active_enemies: Array[Enemy]) -> void:
	if _preview_sprite == null:
		return
	if not contains_global_position(mouse_position):
		hide_preview()
		return
	# topleft
	var top_left: Vector2i = get_drop_cell(enemy, mouse_position, grab_cell, active_enemies)
	if not _is_within_bounds(enemy, top_left):
		hide_preview()
		return
	_preview_sprite.texture = enemy.get_preview_texture()
	_preview_sprite.scale = enemy.get_preview_scale()
	_preview_sprite.global_position = get_global_position_for_cell(top_left, enemy.get_stomach_size())
	_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	_preview_sprite.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	if not can_place(enemy, top_left, active_enemies):
		_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.32)
	_preview_sprite.visible = true


# preview非表示
func hide_preview() -> void:
	if _preview_sprite != null:
		_preview_sprite.visible = false


# global位置forセル取得
func get_global_position_for_cell(top_left: Vector2i, size: Vector2i) -> Vector2:
	# local位置
	var local_position: Vector2 = _grid_origin + Vector2(
		float(top_left.x) * _grid_step + get_span_size(size.x) * 0.5,
		float(top_left.y) * _grid_step + get_span_size(size.y) * 0.5
	)
	return to_global(local_position)


# configureグリッド処理
func _configure_grid() -> void:
	# セルサイズ列
	var cell_size_columns := maxi(columns, 4)
	# セルサイズ行
	var cell_size_rows := maxi(rows, 4)
	# horizontalセルサイズ
	var horizontal_cell_size := (_grid_frame_area_size.x + float(cell_size_columns - 1) * edge_overlap) / float(cell_size_columns)
	# verticalセルサイズ
	var vertical_cell_size := (_grid_frame_area_size.y + float(cell_size_rows - 1) * edge_overlap) / float(cell_size_rows)
	# ishorizontallimited
	var is_horizontal_limited := horizontal_cell_size <= vertical_cell_size
	_cell_size = floorf(minf(horizontal_cell_size, vertical_cell_size))
	_cell_size = maxf(1.0, _cell_size)
	_grid_step = _cell_size - edge_overlap
	# グリッドサイズ
	var grid_size: Vector2 = Vector2(
		float(columns) * _cell_size - float(columns - 1) * edge_overlap,
		float(rows) * _cell_size - float(rows - 1) * edge_overlap
	)
	# activeグリッドarea位置
	var active_grid_area_position := _get_active_grid_area_position(grid_size, is_horizontal_limited)
	# activeグリッドareaサイズ
	var active_grid_area_size := _get_active_grid_area_size(grid_size, is_horizontal_limited)
	_update_frame_size(active_grid_area_size)
	_grid_origin = _get_grid_origin(active_grid_area_position, active_grid_area_size, grid_size)
	_update_line_mesh()
	for child: Node in get_children():
		if child is NinePatchRect and String(child.name).begins_with("grid_frame_"):
			remove_child(child)
			child.queue_free()
	for row in range(rows):
		for column in range(columns):
			# セル
			var cell: NinePatchRect = grid_frame
			if row != 0 or column != 0:
				cell = grid_frame.duplicate() as NinePatchRect
				cell.name = "grid_frame_%d_%d" % [column, row]
				add_child(cell)
			cell.position = (_grid_origin + Vector2(column, row) * _grid_step).round()
			cell.size = Vector2(_cell_size, _cell_size)
	frame.z_index = 10


# グリッドframearea記録
func _capture_grid_frame_area() -> void:
	_grid_frame_area_position = grid_frame.position
	_grid_frame_area_size = grid_frame.size
	_frame_base_position = frame.position
	_frame_base_size = frame.size
	_line_base_position = line_mesh.position
	_line_base_size = line_mesh.size


# activeグリッドareaサイズ取得
func _get_active_grid_area_size(grid_size: Vector2, is_horizontal_limited: bool) -> Vector2:
	# activeサイズ
	var active_size := _grid_frame_area_size
	if columns < 4 or (rows > 5 and not is_horizontal_limited):
		active_size.x = grid_size.x
	if rows < 4 or (columns > 4 and is_horizontal_limited):
		active_size.y = grid_size.y
	return active_size.round()


# activeグリッドarea位置取得
func _get_active_grid_area_position(grid_size: Vector2, is_horizontal_limited: bool) -> Vector2:
	# active位置
	var active_position := _grid_frame_area_position
	if columns < 4 or (rows > 5 and not is_horizontal_limited):
		active_position.x = _grid_frame_area_position.x + (_grid_frame_area_size.x - grid_size.x) * 0.5
	if rows < 4 or (columns > 4 and is_horizontal_limited):
		active_position.y = _grid_frame_area_position.y + (_grid_frame_area_size.y - grid_size.y) * 0.5
	return active_position.round()


# frameサイズ更新
func _update_frame_size(active_grid_area_size: Vector2) -> void:
	# leftmargin
	var left_margin := _grid_frame_area_position.x - _frame_base_position.x
	# topmargin
	var top_margin := _grid_frame_area_position.y - _frame_base_position.y
	# rightmargin
	var right_margin := _frame_base_size.x - left_margin - _grid_frame_area_size.x
	# bottommargin
	var bottom_margin := _frame_base_size.y - top_margin - _grid_frame_area_size.y
	# 対象サイズ
	var target_size := _frame_base_size
	if not is_equal_approx(active_grid_area_size.x, _grid_frame_area_size.x):
		target_size.x = active_grid_area_size.x + left_margin + right_margin
	if not is_equal_approx(active_grid_area_size.y, _grid_frame_area_size.y):
		target_size.y = active_grid_area_size.y + top_margin + bottom_margin
	frame.position = (_frame_base_position + (_frame_base_size - target_size) * 0.5).round()
	frame.size = target_size.round()


# グリッドorigin取得
func _get_grid_origin(active_grid_area_position: Vector2, active_grid_area_size: Vector2, grid_size: Vector2) -> Vector2:
	# グリッドoriginx
	var grid_origin_x := active_grid_area_position.x + (active_grid_area_size.x - grid_size.x) * 0.5
	# グリッドoriginy
	var grid_origin_y := frame.position.y + frame.size.y - grid_size.y
	return Vector2(grid_origin_x, grid_origin_y).round()


# 列mesh更新
func _update_line_mesh() -> void:
	# ライン行
	var top_row := maxi(0, rows - _acid_line_rows)
	var bottom_row := rows - 1
	# 消化列topy
	var acid_line_top_y := _get_row_top_y(top_row)
	# 消化列bottomy
	var acid_line_bottom_y := _get_row_bottom_y(bottom_row)
	# 列位置
	var line_position := Vector2(frame.position.x, acid_line_top_y)
	# 列サイズ
	var line_size := Vector2(frame.size.x, acid_line_bottom_y - acid_line_top_y)
	line_mesh.set_line_rect(line_position, line_size)


# 行topy取得
func _get_row_top_y(row: int) -> float:
	return _grid_origin.y + float(row) * _grid_step


# 行bottomy取得
func _get_row_bottom_y(row: int) -> float:
	return _get_row_top_y(row) + _cell_size


# preview作成
func _create_preview() -> void:
	_preview_sprite = Sprite2D.new()
	_preview_sprite.name = "EnemyPlacementPreview"
	_preview_sprite.visible = false
	_preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	_preview_sprite.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	_preview_sprite.z_index = 5
	add_child(_preview_sprite)


# nearestセル取得
func _get_nearest_cell(global_position: Vector2) -> Vector2i:
	# local位置
	var local_position: Vector2 = to_local(global_position)
	# centered位置
	var centered_position: Vector2 = local_position - _grid_origin - Vector2.ONE * _cell_size * 0.5
	return Vector2i(
		clampi(roundi(centered_position.x / _grid_step), 0, columns - 1),
		clampi(roundi(centered_position.y / _grid_step), 0, rows - 1)
	)


# withinbounds判定
func _is_within_bounds(enemy: Enemy, top_left: Vector2i) -> bool:
	for cell: Vector2i in enemy.get_occupied_cells(top_left):
		if cell.x < 0 or cell.x >= columns or cell.y < 0 or cell.y >= rows:
			return false
	return true
