class_name EnemyTooltipFormatter
extends RefCounted


# categoryname取得
static func get_category_name(has_main_effect: bool, skill_definition: NightmareInfo) -> String:
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
static func get_category_detail(has_main_effect: bool, skill_definition: NightmareInfo) -> String:
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
static func get_main_effect_text(has_main_effect: bool, skill_definition: NightmareInfo) -> String:
	if not has_main_effect or skill_definition == null:
		return ""
	return skill_definition.description


# category文言取得
static func _get_category_text(skill_definition: NightmareInfo) -> String:
	if skill_definition == null or skill_definition.category.is_empty():
		return "通常"
	return skill_definition.category
