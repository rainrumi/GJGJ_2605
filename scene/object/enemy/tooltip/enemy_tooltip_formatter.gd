class_name EnemyTooltipFormatter
extends RefCounted

const REVIVE_CHANCE_TOOLTIP_SKILL_IDS := [17020002001, 17020002002]


# categoryname取得
static func get_category_name(has_main_effect: bool, skill_definition: EnemyInfo) -> String:
	if not has_main_effect:
		return "-"
	# category文言
	var category_text := _get_category_text(skill_definition)
	# separator番号
	var separator_index := category_text.find("（")
	if separator_index == -1:
		return category_text
	return category_text.substr(0, separator_index)


# categorydetail取得
static func get_category_detail(has_main_effect: bool, skill_definition: EnemyInfo) -> String:
	if not has_main_effect:
		return ""
	# category文言
	var category_text := _get_category_text(skill_definition)
	# start番号
	var start_index := category_text.find("（")
	# end番号
	var end_index := category_text.rfind("）")
	if start_index == -1 or end_index == -1 or end_index <= start_index:
		return ""
	return category_text.substr(start_index + 1, end_index - start_index - 1)


# maineffect文言取得
static func get_main_effect_text(
	has_main_effect: bool,
	skill_definition: EnemyInfo,
	enemy_data: EnemyData = null,
	active_effects: Array[EnemyEffect] = []
) -> String:
	if not has_main_effect or skill_definition == null:
		return ""
	var description := skill_definition.description
	description = _append_dynamic_effect_descriptions(description, active_effects)
	if skill_definition.skill_id in REVIVE_CHANCE_TOOLTIP_SKILL_IDS:
		description = _append_chance_description(description, skill_definition, enemy_data)
	return description


# 効果の動的説明追記
static func _append_dynamic_effect_descriptions(
	description: String,
	active_effects: Array[EnemyEffect]
) -> String:
	for effect in active_effects:
		if effect is EnemyEffectOnOtherObjectScaleEffectByObjectCount:
			var count := (effect as EnemyEffectOnOtherObjectScaleEffectByObjectCount).get_object_count()
			return "%s(倍率:%d倍)" % [description, count]
	return description


static func _append_chance_description(
	description: String,
	skill_definition: EnemyInfo,
	enemy_data: EnemyData,
) -> String:
	if description.is_empty():
		return description
	var skill := skill_definition.main_skill
	if enemy_data != null and enemy_data.get_active_skill() != null:
		skill = enemy_data.get_active_skill()
	if skill == null:
		return description
	for effect in skill.effects:
		if effect is EnemyEffectOnDigestedChanceRevive:
			var chance_effect := effect as EnemyEffectOnDigestedChanceRevive
			var adjusted_chance := chance_effect.chance
			if enemy_data != null:
				adjusted_chance = clampf(
					(adjusted_chance + enemy_data.defense_status.chance_delta)
					* enemy_data.defense_status.chance_multiplier,
					0.0,
					1.0
				)
			return "%s(確率:%.1f%%)" % [description, adjusted_chance * 100.0]
	return description


# category文言取得
static func _get_category_text(skill_definition: EnemyInfo) -> String:
	if skill_definition == null or skill_definition.category.is_empty():
		return "通常"
	return skill_definition.category
