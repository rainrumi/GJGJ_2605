class_name LaraReward
extends RefCounted


static func get_seed_candidates(
	stages: Array[StageInfo], owned_seeds: Array[SeedInfo], rarity: int = -1
) -> Array[SeedInfo]:
	var candidates: Array[SeedInfo] = []
	var seen_ids: Dictionary[int, bool] = {}
	for stage in stages:
		if stage == null or stage.drop_seed_pool == null:
			continue
		for seed in stage.drop_seed_pool.get_all_skills():
			if seen_ids.has(seed.skill_id) or (rarity >= 0 and seed.rarity != rarity):
				continue
			if not StageClearCalculatorRecovery.can_receive_seed(seed, owned_seeds):
				continue
			seen_ids[seed.skill_id] = true
			candidates.append(seed)
	return candidates


static func grant_seed(state: RunState, seed: SeedInfo) -> String:
	# 交流報酬も既存の所持枠へ入れ、装備の判断はプレイヤーに委ねる。
	state.stored_seeds.append(seed)
	return "%sを1つ手に入れた。" % seed.display_name


static func recover_hp(state: RunState, percent: int) -> void:
	state.current_hp = mini(
		state.max_hp, state.current_hp + ceili(float(state.max_hp) * percent / 100.0)
	)
