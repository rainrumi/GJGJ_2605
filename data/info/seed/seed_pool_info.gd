class_name SeedPoolInfo
extends Resource

@export var common_skills: Array[SeedInfo] = []
@export var rare_skills: Array[SeedInfo] = []
@export var epic_skills: Array[SeedInfo] = []
# ステージクリア報酬で通常・レアの抽選確率を使うか
@export var use_stage_clear_rarity_probabilities := false
@export_range(0.0, 1.0, 0.01) var normal_probability := 0.25
@export_range(0.0, 1.0, 0.01) var rare_probability := 0.75


# allskills取得
func get_all_skills() -> Array[SeedInfo]:
	# allskills
	var all_skills: Array[SeedInfo] = []
	_append_skills(all_skills, common_skills)
	_append_skills(all_skills, rare_skills)
	_append_skills(all_skills, epic_skills)
	return all_skills


# ステージクリア報酬の候補をレア度抽選で取得
func get_stage_clear_seed_options(option_count: int) -> Array[SeedInfo]:
	var selected_seeds: Array[SeedInfo] = []
	if option_count <= 0:
		return selected_seeds

	var normal_pool := _copy_seed_array(common_skills)
	var rare_pool := _copy_seed_array(rare_skills)
	for _index in range(option_count):
		var selected_pool := rare_pool if _should_pick_rare(normal_pool, rare_pool) else normal_pool
		if selected_pool.is_empty():
			selected_pool = normal_pool if not normal_pool.is_empty() else rare_pool
		if selected_pool.is_empty():
			break

		var seed_index := randi_range(0, selected_pool.size() - 1)
		var selected_seed: SeedInfo = selected_pool[seed_index]
		selected_seeds.append(selected_seed)
		_remove_seed_from_pool(normal_pool, selected_seed)
		_remove_seed_from_pool(rare_pool, selected_seed)

	return selected_seeds


func _should_pick_rare(normal_pool: Array[SeedInfo], rare_pool: Array[SeedInfo]) -> bool:
	if normal_pool.is_empty():
		return true
	if rare_pool.is_empty():
		return false

	var total_probability := normal_probability + rare_probability
	if total_probability <= 0.0:
		return false
	return randf() * total_probability >= normal_probability


func _copy_seed_array(source: Array[SeedInfo]) -> Array[SeedInfo]:
	var copied: Array[SeedInfo] = []
	for seed in source:
		if seed != null:
			copied.append(seed)
	return copied


func _remove_seed_from_pool(pool: Array[SeedInfo], selected_seed: SeedInfo) -> void:
	for index in range(pool.size() - 1, -1, -1):
		var candidate: SeedInfo = pool[index]
		if candidate == selected_seed or (
			selected_seed.skill_id > 0 and candidate.skill_id == selected_seed.skill_id
		):
			pool.remove_at(index)


# skills追加
func _append_skills(
	target: Array[SeedInfo],
	source: Array[SeedInfo]
) -> void:
	for skill in source:
		if skill != null:
			target.append(skill)
