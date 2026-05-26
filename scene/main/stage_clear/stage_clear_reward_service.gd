class_name StageClearRewardService
extends RefCounted


func create_seed_flower(seed: SeedOptionDefinition) -> FlowerDefinition:
	if seed == null or seed.flower_definition == null:
		return null
	var flower := seed.flower_definition.duplicate() as FlowerDefinition
	flower.dream_seed_skill = seed.dream_seed_skill
	return flower


func can_plant_seed(
	seed: SeedOptionDefinition,
	planted_flowers: Array[FlowerDefinition],
	max_flowers: int
) -> bool:
	return StageClearRecoveryCalculator.can_plant_seed(seed, planted_flowers, max_flowers)


func replace_first_flower(planted_flowers: Array[FlowerDefinition], flower: FlowerDefinition) -> void:
	if flower == null:
		return
	for i in range(planted_flowers.size()):
		if planted_flowers[i] == null:
			continue
		planted_flowers[i] = flower
		return


func get_preview_flowers_for_seed(
	seed: SeedOptionDefinition,
	planted_flowers: Array[FlowerDefinition],
	max_flowers: int
) -> Array[FlowerDefinition]:
	var preview_flowers: Array[FlowerDefinition] = []
	for flower in planted_flowers:
		preview_flowers.append(flower)
	var flower := create_seed_flower(seed)
	if flower == null:
		return preview_flowers
	if can_plant_seed(seed, preview_flowers, max_flowers):
		preview_flowers.append(flower)
		return preview_flowers
	replace_first_flower(preview_flowers, flower)
	return preview_flowers


func get_stage_seed_options(
	base_seed_options: Array[Resource],
	stage: StageDefinition
) -> Array[Resource]:
	if stage == null or stage.drop_item_pool.is_empty():
		return _duplicate_resource_array(base_seed_options)
	var stage_seed_options: Array[Resource] = []
	for drop_item in stage.drop_item_pool:
		if drop_item != null:
			stage_seed_options.append(drop_item)
	if stage_seed_options.is_empty():
		return _duplicate_resource_array(base_seed_options)
	return stage_seed_options


func _duplicate_resource_array(resources: Array[Resource]) -> Array[Resource]:
	var duplicated: Array[Resource] = []
	for resource in resources:
		if resource != null:
			duplicated.append(resource)
	return duplicated
