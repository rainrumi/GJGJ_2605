class_name SeedEffectOnFinishAcidSeedBlockDamageAdjacent
extends SeedEffect

@export var damage := 0 # 固定ダメ
@export var received_damage_rate := 0.0 # 受傷率
@export var split := true # 分割有無


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy # 種ブロック
	var enemies: Array = context.get("enemies", []) # 敵一覧
	var acided_enemies: Array = context.get("acided_enemies", []) # 酸化敵
	var received_acid_damage: Dictionary = context.get("received_acid_damage", {}) # 受酸量
	var total_damage := damage + floori(float(int(received_acid_damage.get(seed_block, 0))) * received_damage_rate) # 総ダメ
	if seed_block == null or total_damage <= 0:
		return
	var targets := EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies) # 対象敵
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(total_damage) / float(targets.size()))) if split else total_damage # 対象ダメ
	for target in targets:
		if target == seed_block or target.is_Acided():
			continue
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)
