class_name DreamSeedEffectCalculator
extends RefCounted

var next_digest_damage_bonus_rate := 0.0
var rest_recovery_bonus_rate := 0.0
var _planted_flowers: Array[FlowerDefinition] = []


func setup(flowers: Array) -> void:
	_planted_flowers.clear()
	for flower in flowers:
		if flower is FlowerDefinition:
			_planted_flowers.append(flower as FlowerDefinition)
	next_digest_damage_bonus_rate = 0.0
	rest_recovery_bonus_rate = 0.0


func get_digest_damage_breakdown(
	base_damage: int,
	nightmare_rate: float,
	minutes: int,
	consume_pending_bonus: bool = false
) -> Dictionary:
	var seed_rate := _get_digest_damage_rate(minutes)
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


func apply_player_damage(amount: int, base_damage: int) -> int:
	if amount <= 0:
		return 0
	var final_damage := maxi(0, roundi(float(amount) * _get_player_damage_multiplier()))
	next_digest_damage_bonus_rate += _get_reflect_digest_rate(final_damage, base_damage)
	return final_damage


func get_time_reduction_rate() -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 3 and skill.category == "螟｢縺ｮ闃ｱ邉ｻ邨ｱ":
			rate += 0.05
	return minf(0.2, rate)


func get_rest_hp(max_hp: int, base_recovery_rate: float) -> int:
	var recovery_rate := base_recovery_rate + _get_rest_recovery_bonus_rate()
	if rest_recovery_bonus_rate > 0.0:
		rest_recovery_bonus_rate = maxf(0.0, rest_recovery_bonus_rate - 0.1)
	return ceili(float(max_hp) * recovery_rate)


func get_seed_skill_id_text() -> String:
	var seed_ids: Array[String] = []
	for flower in _planted_flowers:
		if flower == null or flower.dream_seed_skill == null:
			continue
		seed_ids.append(str(flower.dream_seed_skill.skill_id))
	if seed_ids.is_empty():
		return "-"
	return ",".join(seed_ids)


func _get_digest_damage_rate(minutes: int) -> float:
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 1 and skill.category == "螟｢縺ｮ闃ｱ邉ｻ邨ｱ":
			rate += 0.1
		if skill.skill_id == 5 and skill.category == "蜿榊ｰ・ｳｻ邨ｱ":
			rate += 0.1
		if skill.skill_id == 4 and skill.category == "譎る俣邉ｻ邨ｱ" and minutes >= 27 * 60:
			rate += 2.0
	return rate


func _get_player_damage_multiplier() -> float:
	var multiplier := 1.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 2 and skill.category == "蜿榊ｰ・ｳｻ邨ｱ":
			multiplier += 0.3
	return multiplier


func _get_reflect_digest_rate(taken_damage: int, base_damage: int) -> float:
	if taken_damage <= 0:
		return 0.0
	var rate := 0.0
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 2 and skill.category == "蜿榊ｰ・ｳｻ邨ｱ":
			rate += float(taken_damage) * 0.3 / float(base_damage)
	return rate


func _get_rest_recovery_bonus_rate() -> float:
	if rest_recovery_bonus_rate > 0.0:
		return rest_recovery_bonus_rate
	for skill in _get_planted_seed_skills():
		if skill.skill_id == 4 and skill.category == "螟｢縺ｮ闃ｱ邉ｻ邨ｱ":
			rest_recovery_bonus_rate = 0.5
			return rest_recovery_bonus_rate
	return 0.0


func _get_planted_seed_skills() -> Array[DreamSeedSkillDefinition]:
	var skills: Array[DreamSeedSkillDefinition] = []
	for flower in _planted_flowers:
		if flower != null and flower.dream_seed_skill != null:
			skills.append(flower.dream_seed_skill)
	return skills
