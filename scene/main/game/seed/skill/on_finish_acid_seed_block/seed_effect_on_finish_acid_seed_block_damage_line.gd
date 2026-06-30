class_name SeedEffectOnFinishAcidSeedBlockDamageLine
extends SeedEffect

@export var damage := 0
@export var split := false


# 種ブロック完了
func on_finish_acid_seed_block(context: Dictionary) -> void:
	var enemies: Array = context.get("enemies", [])
	var stomach := context.get("stomach") as StomachBoard
	var acided_enemies: Array = context.get("acided_enemies", [])
	if stomach == null or damage <= 0:
		return
	var targets: Array[Enemy] = []
	for enemy in enemies:
		if enemy == null or enemy.is_Acided() or not enemy.is_active_in_stomach() or enemy.has_seed():
			continue
		if stomach.get_bottom_row_cell_count(enemy) > 0:
			targets.append(enemy)
	if targets.is_empty():
		return
	var target_damage := maxi(1, roundi(float(damage) / float(targets.size()))) if split else damage
	for target in targets:
		target.show_acid_damage_values([target_damage])
		if target.take_acid_damage(target_damage, false) and not acided_enemies.has(target):
			acided_enemies.append(target)
