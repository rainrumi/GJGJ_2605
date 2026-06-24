class_name StageClearRecoveryCalculator
extends RefCounted

const SKILL_2_CLEAR_RECOVERY_BONUS_RATE := 0.1
const DREAM_SEED_CLEAR_RECOVERY_UP := 1002
const DREAM_SEED_RARE_CLEAR_RECOVERY_DISABLE := 2004
const DREAM_SEED_SPECIAL_EXTRA_CHOICE_START_HOUR := 28


static func can_plant_seed(seed_skill: SeedInfo, planted_flowers: Array[SeedInfo], max_flowers: int) -> bool:
	if seed_skill == null:
		return false
	return count_planted_flowers(planted_flowers) < max_flowers


static func count_planted_flowers(planted_flowers: Array[SeedInfo]) -> int:
	var count := 0
	for flower in planted_flowers:
		if flower != null:
			count += 1
	return count


static func get_planned_recovery_rate(
	planted_flowers: Array[SeedInfo],
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
	planted_flowers: Array[SeedInfo],
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


static func get_seed_bonus_rate(planted_flowers: Array[SeedInfo]) -> float:
	var bonus_rate := 0.0
	for flower in planted_flowers:
		if flower == null:
			continue
		if flower.skill_id == DREAM_SEED_CLEAR_RECOVERY_UP:
			bonus_rate += SKILL_2_CLEAR_RECOVERY_BONUS_RATE
	return bonus_rate


static func is_clear_time_recovery_disabled(planted_flowers: Array[SeedInfo]) -> bool:
	for flower in planted_flowers:
		if flower == null:
			continue
		if flower.skill_id == DREAM_SEED_RARE_CLEAR_RECOVERY_DISABLE:
			return true
	return false


static func grants_extra_seed_choice(planted_flowers: Array[SeedInfo], clear_minutes: int) -> bool:
	if clear_minutes < DREAM_SEED_SPECIAL_EXTRA_CHOICE_START_HOUR * 60:
		return false
	return is_clear_time_recovery_disabled(planted_flowers)
