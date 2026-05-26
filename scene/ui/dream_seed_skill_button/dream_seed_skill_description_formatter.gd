class_name DreamSeedSkillDescriptionFormatter
extends RefCounted

const EMPTY_TEXT := "-"
const BLOCK_HP_PLACEHOLDER := "%d"


static func get_main_description(skill: DreamSeedSkillDefinition) -> String:
	if skill == null:
		return EMPTY_TEXT
	return _get_or_empty(skill.main_description)


static func get_sub_description(skill: DreamSeedSkillDefinition) -> String:
	if skill == null:
		return EMPTY_TEXT
	var description := _format_block_status_placeholders(skill.sub_description, skill)
	if _should_append_block_status(skill, description):
		description = "%s（%s）" % [description, get_block_status_text(skill)]
	return _get_or_empty(description)


static func has_sub_description(skill: DreamSeedSkillDefinition) -> bool:
	return skill != null and not skill.sub_description.strip_edges().is_empty()


static func get_sub_skill_use_text(remaining_uses: int) -> String:
	return "使用可能数: %d" % remaining_uses


static func get_reward_sub_skill_use_text(skill: DreamSeedSkillDefinition) -> String:
	if not has_sub_description(skill):
		return "使用可能数: 0"
	return "使用可能数: 1"


static func get_block_status_text(skill: DreamSeedSkillDefinition) -> String:
	var block_definition := _get_block_definition(skill)
	var max_hp := block_definition.get_max_hp() if block_definition != null else 1
	var damage := block_definition.get_damage() if block_definition != null else 0
	return "HP%d, 消化ダメージ%d" % [max_hp, damage]


static func is_block_generation_skill(skill: DreamSeedSkillDefinition) -> bool:
	return (
		skill != null
		and skill.sub_skill_mode == DreamSeedSkillDefinition.SubSkillMode.Drag
		and (skill.drag_block_definition != null or skill.drag_texture != null)
	)


static func _format_block_status_placeholders(
	description: String,
	skill: DreamSeedSkillDefinition
) -> String:
	if description.is_empty() or not is_block_generation_skill(skill):
		return description
	var block_definition := _get_block_definition(skill)
	var max_hp := block_definition.get_max_hp() if block_definition != null else 1
	return description.replace(BLOCK_HP_PLACEHOLDER, str(max_hp))


static func _should_append_block_status(skill: DreamSeedSkillDefinition, description: String) -> bool:
	return (
		is_block_generation_skill(skill)
		and not description.is_empty()
		and (not description.contains("HP") or not description.contains("消化ダメージ"))
	)


static func _get_block_definition(skill: DreamSeedSkillDefinition) -> DreamSeedDragBlockDefinition:
	if skill == null:
		return null
	return skill.drag_block_definition


static func _get_or_empty(text: String) -> String:
	if text.strip_edges().is_empty():
		return EMPTY_TEXT
	return text
