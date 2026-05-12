class_name StageClearRecoveryCalculator
extends RefCounted


static func can_plant_seed(seed: SeedOptionDefinition, planted_flowers: Array[FlowerDefinition], max_normal: int, max_high: int) -> bool:
	if seed.flower_definition == null:
		return false
	return count_planted_by_rarity(planted_flowers, seed.rarity) < get_max_flowers_by_rarity(seed.rarity, max_normal, max_high)


static func count_planted_by_rarity(planted_flowers: Array[FlowerDefinition], rarity: StringName) -> int:
	var count := 0
	for flower in planted_flowers:
		if flower != null and flower.rarity == rarity:
			count += 1
	return count


static func get_max_flowers_by_rarity(rarity: StringName, max_normal: int, max_high: int) -> int:
	match rarity:
		&"normal":
			return max_normal
		&"high":
			return max_high
	return 0


static func get_planned_recovery_rate(
	planted_flowers: Array[FlowerDefinition],
	clear_minutes: int,
	recovery_applied: bool,
	start_hour: int,
	end_hour: int,
	base_rate: float,
	hourly_loss_rate: float
) -> float:
	if recovery_applied:
		return 0.0
	return get_clear_time_recovery_rate(planted_flowers, clear_minutes, start_hour, end_hour, base_rate, hourly_loss_rate) + get_seed_bonus_rate(planted_flowers)


static func get_clear_time_recovery_rate(
	planted_flowers: Array[FlowerDefinition],
	clear_minutes: int,
	start_hour: int,
	end_hour: int,
	base_rate: float,
	hourly_loss_rate: float
) -> float:
	if is_clear_time_recovery_disabled(planted_flowers):
		return 0.0
	var clear_hour := int(clear_minutes / 60)
	if clear_hour < start_hour:
		return base_rate
	if clear_hour >= end_hour:
		return 0.0
	return maxf(0.0, base_rate - float(clear_hour - start_hour) * hourly_loss_rate)


static func get_seed_bonus_rate(planted_flowers: Array[FlowerDefinition]) -> float:
	var bonus_rate := 0.0
	for flower in planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		var skill := flower.dream_seed_skill
		if skill.skill_id == 2 and skill.category == "夢の花系統":
			bonus_rate += 0.1
	return bonus_rate


static func is_clear_time_recovery_disabled(planted_flowers: Array[FlowerDefinition]) -> bool:
	for flower in planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		var skill := flower.dream_seed_skill
		if skill.skill_id == 4 and skill.category == "時間系統":
			return true
	return false
