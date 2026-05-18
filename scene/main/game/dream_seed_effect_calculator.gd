class_name DreamSeedEffectCalculator
extends RefCounted

const CATEGORY_DREAM_FLOWER := "夢の花系統"
const SKILL_1_DIGEST_DAMAGE_RATE := 0.1
const SKILL_3_TIME_REDUCTION_RATE := 0.05
const SKILL_3_MAX_TIME_REDUCTION_RATE := 0.2
const SKILL_4_REST_RECOVERY_BONUS_RATE := 0.5
const DREAM_SEED_DIGEST_DAMAGE_UP := 1
const DREAM_SEED_CLEAR_RECOVERY_UP := 2
const DREAM_SEED_TIME_REDUCTION := 3
const DREAM_SEED_REST_RECOVERY := 4

var next_digest_damage_bonus_rate := 0.0
var _planted_flowers: Array[FlowerDefinition] = []
var _skill_4_stock_by_flower: Dictionary = {}


func setup(flowers: Array) -> void:
	_planted_flowers.clear()
	for flower in flowers:
		if flower is FlowerDefinition:
			_planted_flowers.append(flower as FlowerDefinition)
	next_digest_damage_bonus_rate = 0.0
	_setup_skill_4_stocks()


func get_digest_damage_breakdown(
	base_damage: int,
	nightmare_rate: float,
	_minutes: int,
	consume_pending_bonus: bool = false
) -> Dictionary:
	var seed_rate := _get_digest_damage_rate()
	if next_digest_damage_bonus_rate > 0.0:
		seed_rate += next_digest_damage_bonus_rate
	if consume_pending_bonus:
		next_digest_damage_bonus_rate = 0.0
	var seed_buff := roundi(float(base_damage) * seed_rate)
	var damage_after_seed := base_damage + seed_buff
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
	return final_damage


func get_time_reduction_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_TIME_REDUCTION):
			rate += SKILL_3_TIME_REDUCTION_RATE
	return minf(SKILL_3_MAX_TIME_REDUCTION_RATE, rate)


func get_rest_hp(max_hp: int, base_recovery_rate: float) -> int:
	var recovery_rate := base_recovery_rate + _consume_rest_recovery_bonus_rate()
	return ceili(float(max_hp) * recovery_rate)


func get_rest_recovery_bonus_rate() -> float:
	var bonus_rate := 0.0
	for flower in _skill_4_stock_by_flower.keys():
		if int(_skill_4_stock_by_flower[flower]) > 0:
			bonus_rate += SKILL_4_REST_RECOVERY_BONUS_RATE
	return bonus_rate


func get_seed_skill_id_text() -> String:
	var seed_ids: Array[String] = []
	for flower in _planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		seed_ids.append(str(flower.dream_seed_skill.skill_id))
	if seed_ids.is_empty():
		return "-"
	return ",".join(seed_ids)


func _get_digest_damage_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if _is_dream_flower_skill(skill, DREAM_SEED_DIGEST_DAMAGE_UP):
			rate += SKILL_1_DIGEST_DAMAGE_RATE
	return rate


func _get_player_damage_multiplier() -> float:
	return 1.0


func _get_reflect_digest_rate(_taken_damage: int) -> float:
	return 0.0


func _setup_skill_4_stocks() -> void:
	_skill_4_stock_by_flower.clear()
	for flower in _planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		if _is_dream_flower_skill(flower.dream_seed_skill, DREAM_SEED_REST_RECOVERY):
			_skill_4_stock_by_flower[flower] = maxi(0, flower.dream_seed_skill.stock_count)


func _consume_rest_recovery_bonus_rate() -> float:
	var bonus_rate := 0.0
	for flower in _skill_4_stock_by_flower.keys():
		var stock := int(_skill_4_stock_by_flower[flower])
		if stock <= 0:
			continue
		bonus_rate += SKILL_4_REST_RECOVERY_BONUS_RATE
		_skill_4_stock_by_flower[flower] = stock - 1
	return bonus_rate


func _get_planted_seed_skills() -> Array[DreamSeedSkillDefinition]:
	var skills: Array[DreamSeedSkillDefinition] = []
	for flower in _planted_flowers:
		if flower != null and flower.dream_seed_skill != null:
			skills.append(flower.dream_seed_skill)
	return skills


func _is_dream_flower_skill(skill: DreamSeedSkillDefinition, skill_id: int) -> bool:
	return skill != null and skill.skill_id == skill_id and skill.category == CATEGORY_DREAM_FLOWER
