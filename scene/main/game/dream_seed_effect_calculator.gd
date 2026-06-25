class_name DreamSeedEffectCalculator
extends RefCounted

const SKILL_1_DIGEST_DAMAGE_RATE := 0.1
const SKILL_1_BLOCK_DIGEST_DAMAGE_RATE := 0.2
const SKILL_3_TIME_REDUCTION_RATE := 0.05
const SKILL_3_BLOCK_TIME_REDUCTION_RATE := 0.15
const SKILL_3_MAX_TIME_REDUCTION_RATE := 0.2
const SKILL_4_REST_RECOVERY_BONUS_RATE := 0.5
const RARE_SKILL_3_BLOCK_TIME_REDUCTION_RATE := 0.5
const SPECIAL_SKILL_4_LATE_DIGEST_DAMAGE_RATE := 2.0
const SPECIAL_SKILL_4_LATE_DIGEST_DAMAGE_START_HOUR := 28
const DREAM_SEED_DIGEST_DAMAGE_UP := 1001
const DREAM_SEED_CLEAR_RECOVERY_UP := 1002
const DREAM_SEED_TIME_REDUCTION := 1003
const DREAM_SEED_REST_RECOVERY := 1004
const DREAM_SEED_RARE_TIME_REDUCTION := 2003
const DREAM_SEED_RARE_CLEAR_RECOVERY_DISABLE := 2004
const PROPOSAL_RARE_ID_MIN := 2101
const PROPOSAL_RARE_ID_MAX := 2138
const PROPOSAL_RARE_DIGEST_DAMAGE_TIME := 2101
const PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE := 2102
const PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE_BIG := 2103
const PROPOSAL_RARE_REVIVE_TIME_DAMAGE := 2104
const PROPOSAL_RARE_ATTACK_DAMAGE_TO_DIGEST := 2105
const PROPOSAL_RARE_DAMAGE_AND_INTERVAL_UP := 2106
const PROPOSAL_RARE_EXTRA_DIGEST_HIT := 2107
const PROPOSAL_RARE_RANDOM_EXTRA_DIGEST := 2108
const PROPOSAL_RARE_RANDOM_DOUBLE_DIGEST := 2109
const PROPOSAL_RARE_INTERVAL_DAMAGE := 2110
const PROPOSAL_RARE_INTERVAL_SCALING_DAMAGE := 2111
const PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE := 2112
const PROPOSAL_RARE_LINE_PLUS := 2113
const PROPOSAL_RARE_LINE_CELL_DAMAGE := 2114
const PROPOSAL_RARE_EDGE_LINE_DAMAGE := 2115
const PROPOSAL_RARE_LINE_COUNT_DAMAGE := 2116
const PROPOSAL_RARE_SELF_DAMAGE_FROM_DIGEST := 2117
const PROPOSAL_RARE_STOMACH_COLUMN := 2118
const PROPOSAL_RARE_STOMACH_ROW := 2119
const PROPOSAL_RARE_TIME_HP := 2120
const PROPOSAL_RARE_TIME_HP_BY_COUNT := 2121
const PROPOSAL_RARE_EXTRA_HEAL := 2122
const PROPOSAL_RARE_DIGEST_DAMAGE_HEAL := 2123
const PROPOSAL_RARE_DIGESTED_NIGHTMARE_HEAL := 2124
const PROPOSAL_RARE_HOUR_HP := 2125
const PROPOSAL_RARE_DIGESTED_NIGHTMARE_MAX_HP := 2126
const PROPOSAL_RARE_HP_INTERVAL_UP := 2127
const PROPOSAL_RARE_REVIVE_MAX_HP := 2128
const PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE := 2129
const PROPOSAL_RARE_ATTACK_UP := 2130
const PROPOSAL_RARE_INTERVAL_PARITY := 2131
const PROPOSAL_RARE_HP_LOSS_INTERVAL_UP := 2132
const PROPOSAL_RARE_RANDOM_INTERVAL_DAILY := 2133
const PROPOSAL_RARE_TWO_OCLOCK_INTERVAL := 2134
const PROPOSAL_RARE_DAILY_INTERVAL_UP := 2135
const PROPOSAL_RARE_GROWING_INTERVAL_DOWN := 2136
const PROPOSAL_RARE_SAFE_RETURN := 2137
const PROPOSAL_RARE_RETURN_DAMAGE_AND_DISABLE := 2138

var next_digest_damage_bonus_rate := 0.0
var next_time_reduction_bonus_rate := 0.0
var next_digest_damage_flat_bonus := 0
var next_player_damage_multiplier_bonus := 0.0
var next_heal_bonus_rate := 0.0
var max_hp_bonus_rate := 0.0
var recovery_accumulated_for_max_hp := 0
var last_digest_damage_total := 0
var last_hp_loss := 0
var revive_count := 0
var day := 1
var remove_from_stomach_disabled := false
var _planted_flowers: Array[SeedInfo] = []


func setup(flowers: Array) -> void:
	_planted_flowers.clear()
	for flower in flowers:
		if flower is SeedInfo:
			_planted_flowers.append(flower as SeedInfo)
	next_digest_damage_bonus_rate = 0.0
	next_time_reduction_bonus_rate = 0.0
	next_digest_damage_flat_bonus = 0
	next_player_damage_multiplier_bonus = 0.0
	next_heal_bonus_rate = 0.0
	max_hp_bonus_rate = 0.0
	recovery_accumulated_for_max_hp = 0
	last_digest_damage_total = 0
	last_hp_loss = 0
	revive_count = 0
	remove_from_stomach_disabled = false


func get_digest_damage_breakdown(
	base_damage: int,
	nightmare_rate: float,
	minutes: int,
	consume_pending_bonus: bool = false
) -> Dictionary:
	var seed_rate := _get_digest_damage_rate(minutes)
	if next_digest_damage_bonus_rate != 0.0:
		seed_rate += next_digest_damage_bonus_rate
	if consume_pending_bonus:
		next_digest_damage_bonus_rate = 0.0
	var seed_buff := roundi(float(base_damage) * seed_rate)
	var damage_after_seed := base_damage + seed_buff + next_digest_damage_flat_bonus
	if consume_pending_bonus:
		next_digest_damage_flat_bonus = 0
	var total_damage := maxi(1, roundi(float(damage_after_seed) * (1.0 + nightmare_rate)))
	return {
		"total": total_damage,
		"base": base_damage,
		"seed_buff": seed_buff,
		"seed_rate": seed_rate,
		"nightmare_buff": total_damage - damage_after_seed,
		"nightmare_rate": nightmare_rate,
	}


func apply_player_damage(amount: int, _base_damage: int) -> int:
	if amount <= 0:
		return 0
	var final_damage := maxi(0, roundi(float(amount) * _get_player_damage_multiplier()))
	next_digest_damage_bonus_rate += _get_reflect_digest_rate(final_damage)
	next_digest_damage_flat_bonus += _get_taken_attack_flat_digest_bonus(final_damage)
	next_player_damage_multiplier_bonus = 0.0
	last_hp_loss = final_damage
	return final_damage


func get_time_reduction_rate(consume_pending_bonus := false, minutes := 0) -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_TIME_REDUCTION):
			rate += SKILL_3_TIME_REDUCTION_RATE
		match skill.skill_id:
			PROPOSAL_RARE_DAMAGE_AND_INTERVAL_UP:
				rate -= 0.10
			PROPOSAL_RARE_STOMACH_COLUMN:
				rate += 0.10
			PROPOSAL_RARE_HP_INTERVAL_UP:
				rate -= 0.30
			PROPOSAL_RARE_HP_LOSS_INTERVAL_UP:
				rate -= minf(2.0, float(last_hp_loss) * 0.01)
			PROPOSAL_RARE_RANDOM_INTERVAL_DAILY:
				rate += _get_daily_random_interval_rate(day, 0.8)
			PROPOSAL_RARE_TWO_OCLOCK_INTERVAL:
				rate += -0.50 if minutes >= 26 * 60 else 0.50
			PROPOSAL_RARE_DAILY_INTERVAL_UP:
				rate -= 0.50 + _get_daily_growth_rate(day)
			PROPOSAL_RARE_GROWING_INTERVAL_DOWN:
				rate += -minf(0.40, 0.02 * _get_elapsed_step_count(minutes))
	rate += next_time_reduction_bonus_rate
	if consume_pending_bonus:
		next_time_reduction_bonus_rate = 0.0
	return clampf(rate, -2.0, 0.9)


func add_digested_seed_effect(seed_skill: SeedInfo) -> bool:
	if seed_skill == null:
		return false
	match seed_skill.skill_id:
		DREAM_SEED_DIGEST_DAMAGE_UP:
			next_digest_damage_bonus_rate += SKILL_1_BLOCK_DIGEST_DAMAGE_RATE
			return true
		DREAM_SEED_TIME_REDUCTION:
			next_time_reduction_bonus_rate += SKILL_3_BLOCK_TIME_REDUCTION_RATE
			return true
		DREAM_SEED_RARE_TIME_REDUCTION:
			next_time_reduction_bonus_rate += RARE_SKILL_3_BLOCK_TIME_REDUCTION_RATE
			return true
		PROPOSAL_RARE_DAMAGE_AND_INTERVAL_UP:
			next_digest_damage_bonus_rate -= 0.05
			next_time_reduction_bonus_rate += 0.10
			return true
		PROPOSAL_RARE_DIGEST_DAMAGE_TIME:
			next_digest_damage_bonus_rate -= 0.50
			next_time_reduction_bonus_rate += 0.50
			return true
		PROPOSAL_RARE_STOMACH_COLUMN:
			next_time_reduction_bonus_rate += 0.10
			return true
		PROPOSAL_RARE_STOMACH_ROW:
			next_digest_damage_bonus_rate += 0.10
			return true
		PROPOSAL_RARE_TIME_HP:
			next_time_reduction_bonus_rate += 0.99
			return true
		PROPOSAL_RARE_TIME_HP_BY_COUNT:
			next_heal_bonus_rate += 0.05
			return true
		PROPOSAL_RARE_EXTRA_HEAL:
			max_hp_bonus_rate += float(recovery_accumulated_for_max_hp) / 100.0
			return true
		PROPOSAL_RARE_DIGESTED_NIGHTMARE_MAX_HP:
			max_hp_bonus_rate += 0.10
			return true
		PROPOSAL_RARE_HP_INTERVAL_UP:
			next_heal_bonus_rate += 0.50
			return true
		PROPOSAL_RARE_REVIVE_MAX_HP:
			next_heal_bonus_rate += 1.00
			return true
		PROPOSAL_RARE_LINE_PLUS:
			next_digest_damage_bonus_rate -= 0.20
			return true
		PROPOSAL_RARE_LINE_COUNT_DAMAGE:
			next_digest_damage_bonus_rate += 0.50
			return true
		PROPOSAL_RARE_INTERVAL_PARITY:
			next_digest_damage_bonus_rate += 0.20
			next_heal_bonus_rate += 0.20
			return true
		PROPOSAL_RARE_RANDOM_INTERVAL_DAILY:
			next_time_reduction_bonus_rate += _get_daily_random_interval_rate(day, 1.6)
			return true
		PROPOSAL_RARE_TWO_OCLOCK_INTERVAL:
			next_time_reduction_bonus_rate += 0.80
			return true
		PROPOSAL_RARE_DAILY_INTERVAL_UP:
			next_time_reduction_bonus_rate += 0.50 + _get_daily_growth_rate(day)
			return true
		PROPOSAL_RARE_GROWING_INTERVAL_DOWN:
			next_time_reduction_bonus_rate += -minf(0.80, 0.04 * _get_elapsed_step_count(0))
			return true
		PROPOSAL_RARE_RETURN_DAMAGE_AND_DISABLE:
			remove_from_stomach_disabled = true
			next_digest_damage_bonus_rate += 1.0
			return true
	return false


func get_rest_hp(max_hp: int, base_recovery_rate: float) -> int:
	var recovery_rate := base_recovery_rate + _consume_rest_recovery_bonus_rate()
	return ceili(float(max_hp) * recovery_rate)


func get_rest_recovery_bonus_rate() -> float:
	var bonus_rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_REST_RECOVERY):
			bonus_rate += SKILL_4_REST_RECOVERY_BONUS_RATE
	return bonus_rate


func get_seed_skill_id_text() -> String:
	var seed_ids: Array[String] = []
	for flower in _planted_flowers:
		if flower == null:
			continue
		seed_ids.append(str(flower.skill_id))
	if seed_ids.is_empty():
		return "-"
	return ",".join(seed_ids)


func _get_digest_damage_rate(minutes: int) -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_DIGEST_DAMAGE_UP):
			rate += SKILL_1_DIGEST_DAMAGE_RATE
		if _is_special_time_skill(skill, DREAM_SEED_RARE_CLEAR_RECOVERY_DISABLE) and minutes >= SPECIAL_SKILL_4_LATE_DIGEST_DAMAGE_START_HOUR * 60:
			rate += SPECIAL_SKILL_4_LATE_DIGEST_DAMAGE_RATE
		match skill.skill_id:
			PROPOSAL_RARE_DIGEST_DAMAGE_TIME:
				rate += 0.001 * _get_elapsed_step_count(minutes)
			PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE:
				rate += 0.002 * float(revive_count)
			PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE_BIG:
				rate += 0.05 * float(revive_count)
			PROPOSAL_RARE_ATTACK_DAMAGE_TO_DIGEST:
				rate += 0.0
			PROPOSAL_RARE_DAMAGE_AND_INTERVAL_UP:
				rate += 0.05
			PROPOSAL_RARE_INTERVAL_DAMAGE:
				rate += 0.02 * floorf(30.0 / 10.0)
			PROPOSAL_RARE_INTERVAL_SCALING_DAMAGE:
				rate += _get_interval_scaling_damage_rate(30)
			PROPOSAL_RARE_FIXED_INTERVAL_DAMAGE:
				rate += 0.0
			PROPOSAL_RARE_LINE_PLUS:
				rate -= 0.20
			PROPOSAL_RARE_LINE_CELL_DAMAGE:
				rate += 10.0 / 300.0
			PROPOSAL_RARE_DIGEST_DAMAGE_HEAL:
				pass
	return rate


func _get_player_damage_multiplier() -> float:
	var multiplier := 1.0 + next_player_damage_multiplier_bonus
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE:
			multiplier += 0.30
	return maxf(0.0, multiplier)


func _get_reflect_digest_rate(_taken_damage: int) -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_REVIVE_DIGEST_DAMAGE:
			rate += 0.30
		if skill.skill_id == PROPOSAL_RARE_ATTACK_DAMAGE_TO_DIGEST:
			rate += 0.02
	return rate


func add_heal_event(amount: int) -> int:
	if amount <= 0:
		return 0
	var bonus := ceili(float(amount) * _get_heal_bonus_rate())
	recovery_accumulated_for_max_hp += amount
	next_digest_damage_flat_bonus += _get_heal_to_line_damage(amount)
	return bonus


func add_revive_event() -> void:
	revive_count += 1
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_REVIVE_MAX_HP:
			var rate := maxf(0.0, 2.0 - 0.40 * float(revive_count - 1))
			max_hp_bonus_rate += rate


func add_digest_damage_total(amount: int) -> void:
	last_digest_damage_total += maxi(0, amount)


func consume_digest_damage_heal_amount() -> int:
	var heal_amount := 0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_DIGEST_DAMAGE_HEAL:
			heal_amount += floori(float(last_digest_damage_total) * 0.02)
	last_digest_damage_total = 0
	return heal_amount


func get_digested_nightmare_heal_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_DIGESTED_NIGHTMARE_HEAL:
			rate += 0.20
	return rate


func get_digested_nightmare_max_hp_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_DIGESTED_NIGHTMARE_MAX_HP:
			rate += 0.05
	return rate


func get_max_hp_bonus_rate() -> float:
	var rate := max_hp_bonus_rate
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_HP_INTERVAL_UP:
			rate += 1.0
		if skill.skill_id == PROPOSAL_RARE_EXTRA_HEAL:
			rate += float(recovery_accumulated_for_max_hp) / 100.0
	return maxf(0.0, rate)


func get_time_hp_recovery_rate(active_count: int) -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_TIME_HP:
			rate += 0.01
		if skill.skill_id == PROPOSAL_RARE_TIME_HP_BY_COUNT:
			rate += 0.01 * float(active_count)
	return rate


func get_hour_hp_recovery_rate(minutes: int) -> float:
	var minute := minutes % 60
	if minute != 0:
		return 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_HOUR_HP:
			return 0.20
	return 0.0


func get_enemy_attack_multiplier() -> float:
	var multiplier := 1.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_ATTACK_UP:
			multiplier += 0.10
	return maxf(0.0, multiplier)


func get_enemy_attack_delta(minutes: int) -> int:
	var delta := 0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_INTERVAL_PARITY and int(minutes / 30) % 2 == 0:
			delta -= 15
	return delta


func get_digest_target_multiplier() -> float:
	var multiplier := 1.0
	for skill in _get_planted_seed_skills():
		match skill.skill_id:
			PROPOSAL_RARE_EXTRA_DIGEST_HIT:
				multiplier *= 1.20
			PROPOSAL_RARE_RANDOM_EXTRA_DIGEST:
				if randi() % 20 == 0:
					multiplier *= 3.0
			PROPOSAL_RARE_RANDOM_DOUBLE_DIGEST:
				if randi() % 5 == 0:
					multiplier *= 2.0
	return multiplier


func get_remove_from_stomach_damage_rate(default_rate: float) -> float:
	var rate := default_rate
	var safe_return_enabled := false
	for skill in _get_planted_seed_skills():
		match skill.skill_id:
			PROPOSAL_RARE_SAFE_RETURN:
				safe_return_enabled = true
			PROPOSAL_RARE_RETURN_DAMAGE_AND_DISABLE:
				rate = maxf(rate, 0.50)
	if safe_return_enabled:
		return 0.0
	return rate


func get_remove_from_stomach_digest_damage_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_RETURN_DAMAGE_AND_DISABLE:
			rate += 0.33
	return rate


func is_remove_from_stomach_disabled() -> bool:
	return remove_from_stomach_disabled


func add_max_hp_bonus_rate(rate: float) -> void:
	max_hp_bonus_rate += rate


func set_day(value: int) -> void:
	day = maxi(1, value)


func _consume_rest_recovery_bonus_rate() -> float:
	var bonus_rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_REST_RECOVERY):
			bonus_rate += SKILL_4_REST_RECOVERY_BONUS_RATE
	return bonus_rate


func _get_heal_bonus_rate() -> float:
	var rate := next_heal_bonus_rate
	next_heal_bonus_rate = 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_EXTRA_HEAL:
			rate += 0.05
	return rate


func _get_heal_to_line_damage(amount: int) -> int:
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_HEAL_TO_LINE_DAMAGE:
			return floori(float(amount) * 0.33)
	return 0


func _get_taken_attack_flat_digest_bonus(taken_damage: int) -> int:
	var bonus := 0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == PROPOSAL_RARE_ATTACK_DAMAGE_TO_DIGEST:
			bonus += floori(float(taken_damage) * 0.10)
	return bonus


func _get_elapsed_step_count(minutes: int) -> float:
	return maxf(0.0, float(minutes - 22 * 60) / 30.0)


func _get_interval_scaling_damage_rate(interval_minutes: int) -> float:
	if interval_minutes < 60:
		return float(interval_minutes / 5) * 0.10
	return -float(interval_minutes / 10) * 0.10


func _get_daily_random_interval_rate(source_day: int, max_positive_rate: float) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = source_day * 97531
	return rng.randf_range(-0.80, max_positive_rate)


func _get_daily_growth_rate(source_day: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = source_day * 86491
	var rate := 0.0
	for _i in range(maxi(0, source_day - 1)):
		rate += rng.randf_range(0.0, 0.10)
	return rate


func _get_planted_seed_skills() -> Array[SeedInfo]:
	var skills: Array[SeedInfo] = []
	for flower in _planted_flowers:
		if flower != null:
			skills.append(flower)
	return skills


func _is_dream_flower_skill(skill: SeedInfo, skill_id: int) -> bool:
	return skill != null and skill.skill_id == skill_id


func _is_special_time_skill(skill: SeedInfo, skill_id: int) -> bool:
	return skill != null and skill.skill_id == skill_id
