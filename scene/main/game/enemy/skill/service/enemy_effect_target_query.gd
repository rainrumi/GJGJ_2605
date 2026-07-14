class_name EnemyEffectTargetQuery
extends RefCounted


# 隣接モノ取得
static func get_adjacent_objects(source: Enemy, enemies: Array[Enemy]) -> Array[Enemy]:
	return EnemyPlacementQuery.get_adjacent_enemies(source, enemies)


# 隣接悪夢取得
static func get_adjacent_enemies(source: Enemy, enemies: Array[Enemy]) -> Array[Enemy]:
	var values: Array[Enemy] = [] # 隣接悪夢
	for enemy in get_adjacent_objects(source, enemies):
		if enemy.is_nightmare():
			values.append(enemy)
	return values


# 効果対象取得
static func get_targets(
	source: Enemy,
	enemies: Array[Enemy],
	stomach: StomachBoard,
	target_type: EnemyEffect.EffectTarget
) -> Array[Enemy]:
	match target_type:
		EnemyEffect.EffectTarget.SELF:
			return [source]
		EnemyEffect.EffectTarget.ADJACENT_OBJECTS:
			return get_adjacent_objects(source, enemies)
		EnemyEffect.EffectTarget.ADJACENT_ENEMIES:
			return get_adjacent_enemies(source, enemies)
		EnemyEffect.EffectTarget.ALL_ENEMIES:
			return get_active_enemies(enemies)
		EnemyEffect.EffectTarget.ACID_LINE_OBJECTS:
			return get_acid_line_objects(enemies, stomach)
	return get_active_objects(enemies)


# 有効モノ取得
static func get_active_objects(enemies: Array[Enemy]) -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効モノ
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach() and not enemy.is_Acided():
			values.append(enemy)
	return values


# 有効悪夢取得
static func get_active_enemies(enemies: Array[Enemy]) -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効悪夢
	for enemy in get_active_objects(enemies):
		if enemy.is_nightmare():
			values.append(enemy)
	return values


# 消化ライン取得
static func get_acid_line_objects(enemies: Array[Enemy], stomach: StomachBoard) -> Array[Enemy]:
	var values: Array[Enemy] = [] # ライン対象
	if stomach == null:
		return values
	for enemy in get_active_objects(enemies):
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			values.append(enemy)
	return values


# ライン接触数
static func get_acid_line_contact_count(enemy: Enemy, stomach: StomachBoard) -> int:
	if stomach == null or enemy == null:
		return 0
	return stomach.get_bottom_row_cell_count(enemy)


# 胃袋端接触数
static func get_stomach_edge_contact_count(enemy: Enemy, stomach: StomachBoard) -> int:
	if stomach == null or enemy == null or not enemy.is_active_in_stomach():
		return 0
	var count := 0 # 接触数
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.x == 0 or cell.x == stomach.columns - 1 or cell.y == 0 or cell.y == stomach.rows - 1:
			count += 1
	return count


# 空隣接数取得
static func get_open_adjacent_count(source: Enemy, enemies: Array[Enemy], stomach: StomachBoard) -> int:
	if stomach == null:
		return 0
	return EnemyPlacementQuery.get_open_adjacent_cell_count(source, enemies, stomach.columns, stomach.rows)


# 空マス数取得
static func get_empty_cell_count(enemies: Array[Enemy], stomach: StomachBoard) -> int:
	if stomach == null:
		return 0
	return maxi(0, stomach.get_capacity() - stomach.get_current_fullness(enemies))
