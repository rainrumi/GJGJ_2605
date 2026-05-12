class_name NightmarePlacementQuery
extends RefCounted


static func get_adjacent_enemies(enemy: Enemy, enemies: Array[Enemy]) -> Array[Enemy]:
	var adjacent_enemies: Array[Enemy] = []
	if not enemy.is_active_in_stomach():
		return adjacent_enemies
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		if are_enemies_adjacent(enemy, other):
			adjacent_enemies.append(other)
	return adjacent_enemies


static func are_enemies_adjacent(enemy: Enemy, other: Enemy) -> bool:
	var other_cells := other.get_occupied_cells(other.stomach_cell)
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if other_cells.has(cell + Vector2i(-1, 0)) or other_cells.has(cell + Vector2i(1, 0)):
			return true
		if other_cells.has(cell + Vector2i(0, -1)) or other_cells.has(cell + Vector2i(0, 1)):
			return true
	return false


static func get_open_side_count(enemy: Enemy, enemies: Array[Enemy]) -> int:
	var open_side_count := 0
	for direction in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
		if not has_adjacent_enemy_in_direction(enemy, direction, enemies):
			open_side_count += 1
	return open_side_count


static func get_open_face_count(enemy: Enemy, enemies: Array[Enemy]) -> int:
	if not enemy.is_active_in_stomach():
		return 0
	var occupied_cells: Array[Vector2i] = enemy.get_occupied_cells(enemy.stomach_cell)
	var occupied_cell_set := {}
	var directions: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for cell: Vector2i in occupied_cells:
		occupied_cell_set[cell] = true
	var open_face_count := 0
	for cell: Vector2i in occupied_cells:
		for direction: Vector2i in directions:
			var adjacent_cell := cell + direction
			if occupied_cell_set.has(adjacent_cell):
				continue
			if not has_enemy_at_cell(enemy, adjacent_cell, enemies):
				open_face_count += 1
	return open_face_count


static func get_open_adjacent_cell_count(
	enemy: Enemy,
	enemies: Array[Enemy],
	columns: int,
	rows: int
) -> int:
	if not enemy.is_active_in_stomach():
		return 0
	var occupied_cells: Array[Vector2i] = enemy.get_occupied_cells(enemy.stomach_cell)
	var occupied_cell_set := {}
	var open_adjacent_cells := {}
	var directions: Array[Vector2i] = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	for cell: Vector2i in occupied_cells:
		occupied_cell_set[cell] = true
	for cell: Vector2i in occupied_cells:
		for direction: Vector2i in directions:
			var adjacent_cell := cell + direction
			if occupied_cell_set.has(adjacent_cell):
				continue
			if adjacent_cell.x < 0 or adjacent_cell.x >= columns or adjacent_cell.y < 0 or adjacent_cell.y >= rows:
				continue
			if not has_enemy_at_cell(enemy, adjacent_cell, enemies):
				open_adjacent_cells[adjacent_cell] = true
	return open_adjacent_cells.size()


static func has_adjacent_enemy_in_direction(
	enemy: Enemy,
	direction: Vector2i,
	enemies: Array[Enemy]
) -> bool:
	var occupied_cells := enemy.get_occupied_cells(enemy.stomach_cell)
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		var other_cells := other.get_occupied_cells(other.stomach_cell)
		for cell in occupied_cells:
			if other_cells.has(cell + direction):
				return true
	return false


static func has_enemy_at_cell(enemy: Enemy, target_cell: Vector2i, enemies: Array[Enemy]) -> bool:
	for other in enemies:
		if other == enemy or not other.is_active_in_stomach():
			continue
		if other.get_occupied_cells(other.stomach_cell).has(target_cell):
			return true
	return false
