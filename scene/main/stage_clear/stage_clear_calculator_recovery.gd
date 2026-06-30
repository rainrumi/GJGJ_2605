class_name StageClearCalculatorRecovery
extends RefCounted

const SKILL_2_CLEAR_RECOVERY_BONUS_RATE := 0.1
const seed_CLEAR_RECOVERY_UP := 1002
const seed_RARE_CLEAR_RECOVERY_DISABLE := 2004
const seed_SPECIAL_EXTRA_CHOICE_START_HOUR := 28


# plant種判定
static func can_plant_seed(seed: SeedInfo, planted_flowers: Array[SeedInfo], max_flowers: int) -> bool:
	if seed == null:
		return false
	return count_planted_flowers(planted_flowers) < max_flowers


# 数planted花処理
static func count_planted_flowers(planted_flowers: Array[SeedInfo]) -> int:
	# 数値
	var count := 0
	for flower in planted_flowers:
		if flower != null:
			count += 1
	return count


# planned回復率取得
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


# clear時間回復率取得
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
	# clear時
	var clear_hour := int(clear_minutes / 60)
	if clear_hour < start_hour:
		return base_rate
	if clear_hour >= end_hour:
		return 0.0
	return maxf(0.0, base_rate - float(clear_hour - start_hour) * hourly_loss_rate)


# 種補正率取得
static func get_seed_bonus_rate(planted_flowers: Array[SeedInfo]) -> float:
	# 補正率
	var bonus_rate := 0.0
	for flower in planted_flowers:
		if flower == null:
			continue
		if flower.skill_id == seed_CLEAR_RECOVERY_UP:
			bonus_rate += SKILL_2_CLEAR_RECOVERY_BONUS_RATE
	return bonus_rate


# clear時間回復disabled判定
static func is_clear_time_recovery_disabled(planted_flowers: Array[SeedInfo]) -> bool:
	for flower in planted_flowers:
		if flower == null:
			continue
		if flower.skill_id == seed_RARE_CLEAR_RECOVERY_DISABLE:
			return true
	return false


# grantsextra種選択肢処理
static func grants_extra_seed_choice(planted_flowers: Array[SeedInfo], clear_minutes: int) -> bool:
	if clear_minutes < seed_SPECIAL_EXTRA_CHOICE_START_HOUR * 60:
		return false
	return is_clear_time_recovery_disabled(planted_flowers)
