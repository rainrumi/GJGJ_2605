class_name StageClearReward
extends RefCounted


# plant種判定
func can_plant_seed(
	seed: SeedInfo,
	planted_flowers: Array[SeedInfo],
	max_flowers: int
) -> bool:
	return StageClearCalculatorRecovery.can_plant_seed(seed, planted_flowers, max_flowers)


# replacefirst花処理
func replace_first_flower(planted_flowers: Array[SeedInfo], flower: SeedInfo) -> void:
	if flower == null:
		return
	for i in range(planted_flowers.size()):
		if planted_flowers[i] == null:
			continue
		planted_flowers[i] = flower
		return


# preview花for種取得
func get_preview_flowers_for_seed(
	seed: SeedInfo,
	planted_seed: Array[SeedInfo],
	max_flowers: int
) -> Array[SeedInfo]:
	# preview花
	var preview_flowers: Array[SeedInfo] = []
	for seed_info in planted_seed:
		preview_flowers.append(seed_info)
	if seed == null:
		return preview_flowers
	if can_plant_seed(seed, preview_flowers, max_flowers):
		preview_flowers.append(seed)
		return preview_flowers
	replace_first_flower(preview_flowers, seed)
	return preview_flowers


# ステージ種options取得
func get_stage_seed_options(
	base_seed_options: Array[SeedInfo],
	stage: StageInfo
) -> Array[SeedInfo]:
	if stage == null or stage.drop_seed_pool == null:
		return _duplicate_seed_array(base_seed_options)
	# ステージ種options
	var stage_seed_options: Array[SeedInfo] = []
	for seed in stage.drop_seed_pool.get_all_skills():
		if seed != null:
			stage_seed_options.append(seed)
	if stage_seed_options.is_empty():
		return _duplicate_seed_array(base_seed_options)
	stage_seed_options.shuffle()
	return _limit_seed_options(stage_seed_options, base_seed_options.size())


# duplicate種スキルarray処理
func _duplicate_seed_array(seeds: Array[SeedInfo]) -> Array[SeedInfo]:
	# duplicated
	var duplicated: Array[SeedInfo] = []
	for seed in seeds:
		if seed != null:
			duplicated.append(seed)
	return duplicated


# limit種スキルoptions処理
func _limit_seed_options(
	seeds: Array[SeedInfo],
	max_count: int
) -> Array[SeedInfo]:
	if max_count <= 0:
		return seeds
	# limited
	var limited: Array[SeedInfo] = []
	for i in range(mini(seeds.size(), max_count)):
		limited.append(seeds[i])
	return limited
