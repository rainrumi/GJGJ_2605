class_name EnemyEffectTargets
extends RefCounted

var source: Enemy # 効果所有者
var enemies: Array[Enemy] = [] # 敵一覧
var stomach: StomachBoard # 胃袋


# 対象初期化
func setup(owner: Enemy, enemy_list: Array[Enemy], stomach_board: StomachBoard) -> void:
	source = owner
	enemies = enemy_list
	stomach = stomach_board


# 隣接モノ取得
func get_adjacent_objects() -> Array[Enemy]:
	return EnemyPlacementQuery.get_adjacent_enemies(source, enemies)


# 有効モノ取得
func get_active_objects() -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効モノ
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach() and not enemy.is_Acided():
			values.append(enemy)
	return values


# 有効悪夢取得
func get_active_enemies() -> Array[Enemy]:
	var values: Array[Enemy] = [] # 有効悪夢
	for enemy in get_active_objects():
		if enemy.is_nightmare():
			values.append(enemy)
	return values
