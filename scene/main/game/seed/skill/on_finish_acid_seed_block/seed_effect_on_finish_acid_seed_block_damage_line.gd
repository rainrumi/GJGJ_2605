class_name SeedEffectOnFinishAcidSeedBlockDamageLine
extends SeedEffect

@export var split := false # 分割有無


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var enemies: Array = context.get("enemies", []) # 敵一覧
	var stomach := context.get("stomach") as StomachBoard # 胃ボード
	var acided_enemies: Array = context.get("acided_enemies", []) # 酸化敵
	var total_damage := _get_total_damage(context) # 総ダメ
	if stomach == null or total_damage <= 0:
		return
	var targets: Array[Enemy] = [] # 対象敵
	for enemy in enemies:
		if enemy == null or enemy.is_Acided() or not enemy.is_active_in_stomach():
			continue
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			targets.append(enemy)
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(total_damage) / float(targets.size()))) if split else total_damage # 対象ダメ
	for target in targets:
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)


# 総ダメ取得
func _get_total_damage(context: Dictionary) -> int:
	var acid_damage := int(context.get("acid_damage", 0)) # 消化ダメ
	var interval := int(context.get("acid_interval_minutes", 0)) # 消化間隔
	return maxi(0, acid_damage * interval)
