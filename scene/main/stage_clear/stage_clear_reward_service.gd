class_name StageClearRewardService
extends RefCounted


func create_seed_flower(seed_skill: DreamSeedSkillDefinition) -> FlowerDefinition:
	if seed_skill == null:
		return null
	var flower := FlowerDefinition.new()
	flower.display_name = seed_skill.display_name
	flower.texture = seed_skill.texture
	flower.dream_seed_skill = seed_skill
	return flower


func can_plant_seed(
	seed_skill: DreamSeedSkillDefinition,
	planted_flowers: Array[FlowerDefinition],
	max_flowers: int
) -> bool:
	return StageClearRecoveryCalculator.can_plant_seed(seed_skill, planted_flowers, max_flowers)


func replace_first_flower(planted_flowers: Array[FlowerDefinition], flower: FlowerDefinition) -> void:
	if flower == null:
		return
	for i in range(planted_flowers.size()):
		if planted_flowers[i] == null:
			continue
		planted_flowers[i] = flower
		return


func get_preview_flowers_for_seed(
	seed_skill: DreamSeedSkillDefinition,
	planted_flowers: Array[FlowerDefinition],
	max_flowers: int
) -> Array[FlowerDefinition]:
	var preview_flowers: Array[FlowerDefinition] = []
	for flower in planted_flowers:
		preview_flowers.append(flower)
	var flower := create_seed_flower(seed_skill)
	if flower == null:
		return preview_flowers
	if can_plant_seed(seed_skill, preview_flowers, max_flowers):
		preview_flowers.append(flower)
		return preview_flowers
	replace_first_flower(preview_flowers, flower)
	return preview_flowers


func get_stage_seed_options(
	base_seed_options: Array[DreamSeedSkillDefinition],
	stage: StageDefinition
) -> Array[DreamSeedSkillDefinition]:
	if stage == null or stage.drop_seed_skill_pool == null or stage.drop_seed_skill_pool.skills.is_empty():
		return _duplicate_seed_skill_array(base_seed_options)
	var stage_seed_options: Array[DreamSeedSkillDefinition] = []
	for seed_skill in stage.drop_seed_skill_pool.skills:
		if seed_skill != null:
			stage_seed_options.append(seed_skill)
	if stage_seed_options.is_empty():
		return _duplicate_seed_skill_array(base_seed_options)
	stage_seed_options.shuffle()
	return _limit_seed_skill_options(stage_seed_options, base_seed_options.size())


func _duplicate_seed_skill_array(seed_skills: Array[DreamSeedSkillDefinition]) -> Array[DreamSeedSkillDefinition]:
	var duplicated: Array[DreamSeedSkillDefinition] = []
	for seed_skill in seed_skills:
		if seed_skill != null:
			duplicated.append(seed_skill)
	return duplicated


func _limit_seed_skill_options(
	seed_skills: Array[DreamSeedSkillDefinition],
	max_count: int
) -> Array[DreamSeedSkillDefinition]:
	if max_count <= 0:
		return seed_skills
	var limited: Array[DreamSeedSkillDefinition] = []
	for i in range(mini(seed_skills.size(), max_count)):
		limited.append(seed_skills[i])
	return limited
