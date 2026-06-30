class_name SeedEffectOnFinishAcidSeedBlockDamageAdjacent
extends SeedEffect

@export var damage := 0
@export var received_damage_rate := 0.0
@export var split := true


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var seed_block := context.get("seed_block") as Enemy
	var enemies: Array = context.get("enemies", [])
	var acided_enemies: Array = context.get("acided_enemies", [])
	var received_acid_damage: Dictionary = context.get("received_acid_damage", {})
	var total_damage := damage + floori(float(int(received_acid_damage.get(seed_block, 0))) * received_damage_rate)
	if seed_block == null or total_damage <= 0:
		return
	var targets := EnemyPlacementQuery.get_adjacent_enemies(seed_block, enemies)
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(total_damage) / float(targets.size()))) if split else total_damage
	for target in targets:
		if target == seed_block or target.is_Acided():
			continue
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)
