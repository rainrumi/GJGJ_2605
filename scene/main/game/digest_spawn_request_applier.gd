class_name AcidSpawnRequestApplier
extends RefCounted


# 要求適用
func apply_requests(
	spawn_requests: Array[AcidSpawnRequest],
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
			request.acid_damage_rate,
			request.global_acid_damage_rate
		):
			break
