class_name DreamSeedDebugFactory
extends RefCounted

const seed_catalog: SeedCatalogInfo = preload("res://data/resources/seeds/seed_catalog.tres")


func create_random_debug_seed_flower() -> SeedInfo:
	var candidates := _get_debug_seed_flower_candidates()
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


func _get_debug_seed_flower_candidates() -> Array[SeedInfo]:
	var candidates: Array[SeedInfo] = []
	_append_debug_seed_flower_candidates(candidates, seed_catalog.normal_skills)
	_append_debug_seed_flower_candidates(candidates, seed_catalog.rare_skills)
	return candidates


func _append_debug_seed_flower_candidates(
	candidates: Array[SeedInfo],
	skills: Array
) -> void:
	for skill_resource in skills:
		if not skill_resource is SeedInfo:
			continue
		var skill := skill_resource as SeedInfo
		var flower := SeedInfo.new()
		flower.display_name = skill.display_name
		flower.texture = skill.texture
		candidates.append(flower)
