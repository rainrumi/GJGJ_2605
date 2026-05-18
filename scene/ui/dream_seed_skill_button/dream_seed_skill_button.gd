class_name DreamSeedSkillButton
extends Button

const RARITY_NORMAL: StringName = &"normal"
const SEED_DESCRIPTION := "悪夢を消化したら生まれた種。ドラッグですると食べられるものもあるらしい"
const TOOLTIP_SIZE := Vector2(220.0, 130.0)
const TOOLTIP_OFFSET := Vector2(18.0, -8.0)

@onready var frame: TextureRect = $Frame
@onready var icon_rect: TextureRect = $Icon

var source_data: Resource
var icon_source_data: Resource
var seed_skill: DreamSeedSkillDefinition
var rarity: StringName = RARITY_NORMAL
var tooltip_panel: Panel
var tooltip_label: Label


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
		if tooltip_label != null:
			tooltip_label.text = ""
		return
	var text := _get_tooltip_text()
	tooltip_text = text
	if tooltip_label != null:
		tooltip_label.text = text


func _get_tooltip_text() -> String:
	var lines: Array[String] = [
		_get_title_text(),
		"使用可能数: %d" % seed_skill.stock_count,
		"メインスキル: %s" % _get_or_empty(seed_skill.main_description),
	]
	if _is_rare_seed():
		lines.append("サブスキル: %s" % _get_or_empty(seed_skill.sub_description))
	lines.append("説明: %s" % SEED_DESCRIPTION)
	return "\n".join(lines)


func _create_tooltip_panel() -> void:
	tooltip_panel = Panel.new()
	tooltip_panel.name = "SeedSkillTooltip"
	tooltip_panel.visible = false
	tooltip_panel.top_level = true
	tooltip_panel.z_index = 100
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.size = TOOLTIP_SIZE
	tooltip_panel.add_theme_stylebox_override("panel", _create_tooltip_style())
	add_child(tooltip_panel)

	tooltip_label = Label.new()
	tooltip_label.offset_left = 8.0
	tooltip_label.offset_top = 8.0
	tooltip_label.offset_right = TOOLTIP_SIZE.x - 8.0
	tooltip_label.offset_bottom = TOOLTIP_SIZE.y - 8.0
	tooltip_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_label.add_theme_color_override("font_color", Color.WHITE)
	tooltip_label.add_theme_color_override("font_outline_color", Color.BLACK)
	tooltip_label.add_theme_constant_override("outline_size", 2)
	tooltip_label.add_theme_font_size_override("font_size", 10)
	tooltip_panel.add_child(tooltip_label)
	_refresh_tooltip()


func _create_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.78)
	style.border_color = Color(0.94, 0.88, 1.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 1)
	style.set_corner_radius(CORNER_TOP_LEFT, 2)
	style.set_corner_radius(CORNER_TOP_RIGHT, 2)
	style.set_corner_radius(CORNER_BOTTOM_RIGHT, 2)
	style.set_corner_radius(CORNER_BOTTOM_LEFT, 2)
	return style


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
	return rarity != RARITY_NORMAL


func _get_or_empty(text: String) -> String:
	if text.is_empty():
		return "-"
	return text
