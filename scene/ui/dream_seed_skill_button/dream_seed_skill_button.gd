class_name DreamSeedSkillButton
extends Button

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)
const TOOLTIP_SCENE := preload("res://scene/ui/dream_seed_skill_button/dream_seed_skill_tooltip.tscn")

@onready var frame: TextureRect = $Frame
@onready var icon_rect: TextureRect = $Icon

var source_data: Resource
var icon_source_data: Resource
var seed_skill: DreamSeedSkillDefinition
var tooltip_panel: DreamSeedSkillTooltipView
var debug_numbers_visible := false


func _ready() -> void:
	custom_minimum_size = Vector2(16.0, 16.0)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_NONE
	flat = true
	icon_rect.visible = icon_rect.texture != null
	_create_tooltip_panel()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func set_seed_source(source: Resource) -> void:
	source_data = source
	seed_skill = null
	if source is FlowerDefinition:
		var flower := source as FlowerDefinition
		seed_skill = flower.dream_seed_skill
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


func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	_refresh_tooltip()


func _refresh_tooltip() -> void:
	if seed_skill == null:
		tooltip_text = ""
		if tooltip_panel != null:
			tooltip_panel.set_text("")
		return
	var text := _get_tooltip_text()
	tooltip_text = ""
	if tooltip_panel != null:
		tooltip_panel.set_text(text)


func _get_tooltip_text() -> String:
	var lines: Array[String] = [
		_get_title_text(),
		"メインスキル: %s" % _get_or_empty(seed_skill.main_description),
	]
	if _is_rare_seed():
		lines.append("サブスキル: %s" % _get_or_empty(seed_skill.sub_description))
	lines.append("使用可能数: %d" % seed_skill.stock_count)
	if debug_numbers_visible:
		lines.append("ID: %d" % seed_skill.skill_id)
	return "\n".join(lines)


func _create_tooltip_panel() -> void:
	tooltip_panel = TOOLTIP_SCENE.instantiate() as DreamSeedSkillTooltipView
	add_child(tooltip_panel)
	_refresh_tooltip()


func _on_mouse_entered() -> void:
	if seed_skill == null or tooltip_panel == null:
		return
	tooltip_panel.global_position = global_position + TOOLTIP_OFFSET
	tooltip_panel.visible = true


func _on_mouse_exited() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false


func _get_title_text() -> String:
	if _is_rare_seed():
		return "%s(レア)" % seed_skill.display_name
	return seed_skill.display_name


func _is_rare_seed() -> bool:
	return seed_skill != null and seed_skill.rarity == DreamSeedSkillDefinition.Rarity.RARE


func _get_or_empty(text: String) -> String:
	if text.is_empty():
		return "-"
	return text
