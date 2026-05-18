class_name DreamSeedSkillButton
extends Button

const RARITY_NORMAL: StringName = &"normal"
const SEED_DESCRIPTION := "悪夢を消化したら生まれた種。ドラッグですると食べられるものもあるらしい"

@onready var frame: TextureRect = $Frame
@onready var icon_rect: TextureRect = $Icon

var source_data: Resource
var icon_source_data: Resource
var seed_skill: DreamSeedSkillDefinition
var rarity: StringName = RARITY_NORMAL


func _ready() -> void:
	custom_minimum_size = Vector2(16.0, 16.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	flat = true
	icon_rect.visible = icon_rect.texture != null


func set_seed_source(source: Resource) -> void:
	source_data = source
	seed_skill = null
	rarity = RARITY_NORMAL
	if source is FlowerDefinition:
		var flower := source as FlowerDefinition
		seed_skill = flower.dream_seed_skill
		rarity = flower.rarity
	elif source is DreamSeedSkillDefinition:
		seed_skill = source as DreamSeedSkillDefinition
	set_seed_icon_source(source)
	disabled = seed_skill == null
	_refresh_tooltip()


func set_seed_icon_source(source: Resource) -> void:
	icon_source_data = source


func set_seed_icon_texture(texture: Texture2D) -> void:
	icon_rect.texture = texture
	icon_rect.visible = texture != null


func get_seed_source() -> Resource:
	return source_data


func _refresh_tooltip() -> void:
	if seed_skill == null:
		tooltip_text = ""
		return
	var lines: Array[String] = [
		_get_title_text(),
		"使用可能数: %d" % seed_skill.stock_count,
		"メインスキル: %s" % _get_or_empty(seed_skill.main_description),
	]
	if _is_rare_seed():
		lines.append("サブスキル: %s" % _get_or_empty(seed_skill.sub_description))
	lines.append("説明: %s" % SEED_DESCRIPTION)
	tooltip_text = "\n".join(lines)


func _get_title_text() -> String:
	if _is_rare_seed():
		return "%s(レア)" % seed_skill.display_name
	return seed_skill.display_name


func _is_rare_seed() -> bool:
	return rarity != RARITY_NORMAL


func _get_or_empty(text: String) -> String:
	if text.is_empty():
		return "-"
	return text
