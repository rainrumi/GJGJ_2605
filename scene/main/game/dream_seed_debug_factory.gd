class_name DreamSeedDebugFactory
extends RefCounted

const seed_catalog: SeedCatalogInfo = preload("res://data/resources/seeds/seed_catalog.tres")


# randomデバッグ種花作成
func create_random_debug_seed_flower() -> SeedInfo:
	# 候補
	var candidates := _get_debug_seed_flower_candidates()
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]


# デバッグ種花候補取得
func _get_debug_seed_flower_candidates() -> Array[SeedInfo]:
	# 候補
	var candidates: Array[SeedInfo] = []
	_append_debug_seed_flower_candidates(candidates, seed_catalog.normal_skills)
	_append_debug_seed_flower_candidates(candidates, seed_catalog.rare_skills)
	return candidates


# デバッグ種花候補追加
func _append_debug_seed_flower_candidates(
	candidates: Array[SeedInfo],
	skills: Array
) -> void:
	for skill_resource in skills:
		if not skill_resource is SeedInfo:
			continue
		# スキル
		var skill := skill_resource as SeedInfo
		# 種データ
		candidates.append(skill)
