class_name StageClearRewardService
extends RefCounted


func can_plant_seed(
	seed_skill: SeedInfo,
	planted_flowers: Array[SeedInfo],
	max_flowers: int
) -> bool:
	return StageClearRecoveryCalculator.can_plant_seed(seed_skill, planted_flowers, max_flowers)


func replace_first_flower(planted_flowers: Array[SeedInfo], flower: SeedInfo) -> void:
	if flower == null:
		return
	for i in range(planted_flowers.size()):
		if planted_flowers[i] == null:
			continue
		planted_flowers[i] = flower
		return


func get_preview_flowers_for_seed(
	seed_skill: SeedInfo,
	planted_seed: Array[SeedInfo],
	max_flowers: int
) -> Array[SeedInfo]:
	var preview_flowers: Array[SeedInfo] = []
	for seed_info in planted_seed:
		preview_flowers.append(seed_info)
	if seed_skill == null:
		return preview_flowers
	if can_plant_seed(seed_skill, preview_flowers, max_flowers):
		preview_flowers.append(seed_skill)
		return preview_flowers
	replace_first_flower(preview_flowers, seed_skill)
	return preview_flowers


func get_stage_seed_options(
	base_seed_options: Array[SeedInfo],
	stage: StageDefinition
) -> Array[SeedInfo]:
	if stage == null or stage.drop_seed_skill_pool == null:
		return _duplicate_seed_skill_array(base_seed_options)
	var stage_seed_options: Array[SeedInfo] = []
	for seed_skill in stage.drop_seed_skill_pool.get_all_skills():
		if seed_skill != null:
			stage_seed_options.append(seed_skill)
	if stage_seed_options.is_empty():
		return _duplicate_seed_skill_array(base_seed_options)
	stage_seed_options.shuffle()
	return _limit_seed_skill_options(stage_seed_options, base_seed_options.size())


func _duplicate_seed_skill_array(seed_skills: Array[SeedInfo]) -> Array[SeedInfo]:
	var duplicated: Array[SeedInfo] = []
	for seed_skill in seed_skills:
		if seed_skill != null:
			duplicated.append(seed_skill)
	return duplicated


func _limit_seed_skill_options(
	seed_skills: Array[SeedInfo],
	max_count: int
) -> Array[SeedInfo]:
	if max_count <= 0:
		return seed_skills
	var limited: Array[SeedInfo] = []
	for i in range(mini(seed_skills.size(), max_count)):
		limited.append(seed_skills[i])
	return limited
