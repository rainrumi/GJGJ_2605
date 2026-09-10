class_name SeedEffectOnFinishAcidSeedBlockFixedDamageLine
extends SeedEffect

@export var damage := 0 # 固定ダメ
@export var split := false # 分割有無


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	apply_line_damage(context, damage, split)


static func apply_line_damage(
	context: Dictionary, amount: int, split_damage := false, edge_only := false,
	enemies_only := true
) -> void:
	var enemies: Array = context.get("enemies", []) # 敵一覧
	var stomach := context.get("stomach") as StomachBoard # 胃ボード
	var acided_enemies: Array = context.get("acided_enemies", []) # 酸化敵
	if stomach == null or amount <= 0:
		return
	var targets: Array[Enemy] = [] # 対象敵
	for enemy in enemies:
		if enemy == null or enemy.is_Acided() or not enemy.is_active_in_stomach():
			continue
		if enemies_only and enemy.has_seed():
			continue
		if edge_only and not _touches_line_edge(enemy, stomach):
			continue
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			targets.append(enemy)
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(amount) / float(targets.size()))) if split_damage else amount
	for target in targets:
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)


static func _touches_line_edge(enemy: Enemy, stomach: StomachBoard) -> bool:
	var line_top := stomach.rows - stomach.get_acid_line_rows()
	for cell in enemy.get_occupied_cells(enemy.stomach_cell):
		if cell.y >= line_top and (
			cell.x == 0 or cell.x == stomach.columns - 1 or cell.y == stomach.rows - 1
		):
			return true
	return false
