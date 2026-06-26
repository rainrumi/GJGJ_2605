class_name SeedDescription
extends RefCounted

const EMPTY_TEXT := "-"
const BLOCK_HP_PLACEHOLDER := "%d"


# main説明取得
static func get_main_description(skill: SeedInfo) -> String:
	if skill == null:
		return EMPTY_TEXT
	return _get_or_empty(skill.main_description)


# sub説明取得
static func get_sub_description(skill: SeedInfo) -> String:
	if skill == null:
		return EMPTY_TEXT
	# 説明
	var description := _format_block_status_placeholders(skill.sub_description, skill)
	if _should_append_block_status(skill, description):
		description = "%s（%s）" % [description, get_block_status_text(skill)]
	return _get_or_empty(description)


# sub説明判定
static func has_sub_description(skill: SeedInfo) -> bool:
	return skill != null and not skill.sub_description.strip_edges().is_empty()


# subスキル判定
static func has_sub_skill(skill: SeedInfo) -> bool:
	return has_sub_description(skill) or is_block_generation_skill(skill)


# ブロック状態文言取得
static func get_block_status_text(skill: SeedInfo) -> String:
	# ブロック定義
	var block_definition := _get_block_definition(skill)
	# 最大HP
	var max_hp := block_definition.get_max_hp() if block_definition != null else 1
	# ダメージ
	var damage := block_definition.get_damage() if block_definition != null else 0
	return "HP%d, 消化ダメージ%d" % [max_hp, damage]


# ブロックgenerationスキル判定
static func is_block_generation_skill(skill: SeedInfo) -> bool:
	return (
		skill != null
		and skill.sub_skill_mode == SeedInfo.SubSkillMode.Drag
		and skill.acid_block != null
	)


# ブロック状態placeholders整形
static func _format_block_status_placeholders(
	description: String,
	skill: SeedInfo
) -> String:
	if description.is_empty() or not is_block_generation_skill(skill):
		return description
	# ブロック定義
	var block_definition := _get_block_definition(skill)
	# 最大HP
	var max_hp := block_definition.get_max_hp() if block_definition != null else 1
	return description.replace(BLOCK_HP_PLACEHOLDER, str(max_hp))


# shouldappendブロック状態処理
static func _should_append_block_status(skill: SeedInfo, description: String) -> bool:
	return (
		is_block_generation_skill(skill)
		and not description.is_empty()
		and (not description.contains("HP") or not description.contains("消化ダメージ"))
	)


# ブロック定義取得
static func _get_block_definition(skill: SeedInfo) -> AcidBlockInfo:
	if skill == null:
		return null
	return skill.acid_block


# orempty取得
static func _get_or_empty(text: String) -> String:
	if text.strip_edges().is_empty():
		return EMPTY_TEXT
	return text
