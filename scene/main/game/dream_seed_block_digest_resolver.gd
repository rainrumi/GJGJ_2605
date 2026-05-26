class_name DreamSeedBlockDigestResolver
extends RefCounted

const DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE := 2002
const DREAM_SEED_RARE_LATE_DIGEST_DAMAGE := 2004
const DREAM_SEED_RARE_ADJACENT_DAMAGE_UP := 2005
const LATE_DIGEST_DAMAGE_RATE := 1.0
const LATE_DIGEST_DAMAGE_START_HOUR := 28


func get_digest_damage_rate(enemies: Array[Enemy], minutes: int) -> float:
	if minutes < LATE_DIGEST_DAMAGE_START_HOUR * 60:
		return 0.0
	var rate := 0.0
	for enemy in enemies:
		if enemy == null or not enemy.is_active_in_stomach() or not enemy.has_seed_skill():
			continue
		if enemy.get_seed_skill().skill_id == DREAM_SEED_RARE_LATE_DIGEST_DAMAGE:
			rate += LATE_DIGEST_DAMAGE_RATE
	return rate


func append_digested_by_seed_block_effects(
	seed_block: Enemy,
	enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	if seed_block == null or not seed_block.has_seed_skill():
		return
	match seed_block.get_seed_skill().skill_id:
		DREAM_SEED_RARE_REFLECT_DIGEST_DAMAGE, DREAM_SEED_RARE_ADJACENT_DAMAGE_UP:
			_apply_adjacent_damage(
				seed_block,
				enemies,
				int(received_digest_damage.get(seed_block, 0)),
				digested_enemies
			)


func apply_digested_effect_and_append_new_digested(
	seed_block: Enemy,
	enemies: Array[Enemy],
	received_digest_damage: Dictionary,
	digested_enemies: Array[Enemy]
) -> void:
	append_digested_by_seed_block_effects(seed_block, enemies, received_digest_damage, digested_enemies)


func _apply_adjacent_damage(
	seed_block: Enemy,
	enemies: Array[Enemy],
	damage: int,
	digested_enemies: Array[Enemy]
) -> void:
	if damage <= 0:
		return
	var adjacent_enemies := NightmarePlacementQuery.get_adjacent_enemies(seed_block, enemies)
	if adjacent_enemies.is_empty():
		return
	var split_damage := maxi(1, roundi(float(damage) / float(adjacent_enemies.size())))
	for adjacent_enemy in adjacent_enemies:
		if adjacent_enemy == seed_block or adjacent_enemy.is_digested():
			continue
		adjacent_enemy.show_digest_damage_values([split_damage])
		if adjacent_enemy.take_digest_damage(split_damage, false) and not digested_enemies.has(adjacent_enemy):
			digested_enemies.append(adjacent_enemy)
