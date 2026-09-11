class_name SeedEffectOnFinishAcidSeedBlockDamageAdjacent
extends SeedEffect

@export var self_damage_multiplier := 1.0
@export var stomach_edge_only := false
@export var elapsed_minute_damage := 0
@export var player_max_hp_rate := 0.0
@export var damage := 0 # 固定ダメ
@export var received_damage_rate := 0.0 # 受傷率
@export var split := true # 分割有無
@export var player_hp_rate := 0.0
@export var enemies_only := false


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	var acided_enemies: Array = context.get("acided_enemies", []) # 酸化敵
	var received_acid_damage: Dictionary = context.get("received_acid_damage", {}) # 受酸量
	var total_damage := damage + floori(float(maxi(seed_block.received_acid_damage_total if seed_block != null else 0, int(received_acid_damage.get(seed_block, 0)))) * received_damage_rate) # 総ダメ
	total_damage += floori(float(int(context.get("player_hp", 0))) * player_hp_rate)
	total_damage += floori(float(int(context.get("player_max_hp", 0))) * player_max_hp_rate)
	total_damage += int(context.get("day_elapsed_minutes", 0)) * elapsed_minute_damage
	if seed_block == null or total_damage <= 0:
		return
	var targets := EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies, true) # 対象敵
	if stomach_edge_only:
		var stomach := context.get("stomach") as StomachBoard
		assert(stomach != null, "胃袋端ダメージにはStomachBoardが必要です")
		targets.clear()
		for target: Enemy in enemies:
			if target != seed_block and target.is_active_in_stomach() and not target.is_Acided():
				for cell in target.get_occupied_cells(target.stomach_cell):
					if cell.x == 0 or cell.y == 0 or cell.x == stomach.columns - 1 or cell.y == stomach.rows - 1:
						targets.append(target)
						break
	if enemies_only:
		targets = targets.filter(func(target: Enemy) -> bool: return target.is_enemy())
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(total_damage) / float(targets.size()))) if split else total_damage # 対象ダメ
	for target in targets:
		if target == seed_block or target.is_Acided():
			continue
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)
