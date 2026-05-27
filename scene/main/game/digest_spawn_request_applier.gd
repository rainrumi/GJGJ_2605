class_name DigestSpawnRequestApplier
extends RefCounted


func apply_requests(
	spawn_requests: Array[DigestSpawnRequest],
	enemies: Array[Enemy],
	enemy_setup: GameEnemySetupController
) -> void:
	for request in spawn_requests:
		if request == null:
			continue
		if not enemy_setup.spawn_nuisance_nightmare(
			enemies,
			request.source_enemy,
			request.cell,
			request.hp_rate,
			request.damage,
			request.digest_damage_rate
		):
			break
