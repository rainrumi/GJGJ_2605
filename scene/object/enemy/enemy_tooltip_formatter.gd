class_name EnemyTooltipFormatter
extends RefCounted


static func get_category_name(has_main_effect: bool, skill_definition: NightmareSkillDefinition) -> String:
	if not has_main_effect:
		return "-"
	var category_text := _get_category_text(skill_definition)
	var separator_index := category_text.find("（")
	if separator_index == -1:
		return category_text
	return category_text.substr(0, separator_index)


static func get_category_detail(has_main_effect: bool, skill_definition: NightmareSkillDefinition) -> String:
	if not has_main_effect:
		return ""
	var category_text := _get_category_text(skill_definition)
	var start_index := category_text.find("（")
	var end_index := category_text.rfind("）")
	if start_index == -1 or end_index == -1 or end_index <= start_index:
		return ""
	return category_text.substr(start_index + 1, end_index - start_index - 1)


static func get_main_effect_text(has_main_effect: bool, skill_definition: NightmareSkillDefinition) -> String:
	if not has_main_effect or skill_definition == null:
		return ""
	return skill_definition.description


static func _get_category_text(skill_definition: NightmareSkillDefinition) -> String:
	if skill_definition == null or skill_definition.category.is_empty():
		return "通常"
	return skill_definition.category

