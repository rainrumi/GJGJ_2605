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
