class_name DreamSeedSkillButton
extends Button

signal seed_skill_drag_started(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_moved(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_released(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)
const TOOLTIP_SCENE := preload("res://scene/ui/dream_seed_skill_button/dream_seed_skill_tooltip.tscn")
const LOW_SUB_SKILL_USES_COLOR := Color(1.0, 0.02745098, 0.21176471, 1.0)
const NORMAL_ICON_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const SUB_SKILL_USE_COUNT := 1

@onready var frame: TextureRect = $Frame
@onready var icon_rect: TextureRect = $Icon

var source_data: Resource
var icon_source_data: Resource
var seed_skill: DreamSeedSkillDefinition
var tooltip_panel: DreamSeedSkillTooltipView
var debug_numbers_visible := false
var sub_skill_drag_enabled := false
var _remaining_sub_skill_uses := 0
var _dragging := false


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
	_remaining_sub_skill_uses = SUB_SKILL_USE_COUNT if _has_sub_skill() else 0
	disabled = seed_skill == null
	_update_drag_state()
	_refresh_tooltip()


func set_seed_icon_source(source: Resource) -> void:
	icon_source_data = source
	if source is FlowerDefinition:
		set_seed_icon_texture((source as FlowerDefinition).texture)
	elif source is DreamSeedSkillDefinition:
		set_seed_icon_texture((source as DreamSeedSkillDefinition).texture)
	else:
		set_seed_icon_texture(null)


func set_seed_icon_texture(texture: Texture2D) -> void:
	icon_rect.texture = texture
	icon_rect.visible = texture != null


func get_seed_source() -> Resource:
	return source_data


func get_remaining_sub_skill_uses() -> int:
	return _remaining_sub_skill_uses


func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	_refresh_tooltip()


func set_sub_skill_drag_enabled(is_enabled: bool) -> void:
	sub_skill_drag_enabled = is_enabled
	_update_drag_state()


func consume_sub_skill_use() -> void:
	_remaining_sub_skill_uses = maxi(0, _remaining_sub_skill_uses - 1)
	_update_drag_state()
	_refresh_tooltip()


func _process(_delta: float) -> void:
	if not _dragging or seed_skill == null:
		return
	seed_skill_drag_moved.emit(self, seed_skill, get_viewport().get_mouse_position())


func _input(event: InputEvent) -> void:
	if not _dragging:
		return
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and not mouse_button.pressed:
			_dragging = false
			seed_skill_drag_released.emit(self, seed_skill, mouse_button.position)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			_try_use_sub_skill(mouse_button.position)


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
		"メインスキル: %s" % DreamSeedSkillDescriptionFormatter.get_main_description(seed_skill),
	]
	if _has_sub_skill():
		lines.append("サブスキル: %s" % DreamSeedSkillDescriptionFormatter.get_sub_description(seed_skill))
	if _has_sub_skill():
		lines.append(DreamSeedSkillDescriptionFormatter.get_sub_skill_use_text(_remaining_sub_skill_uses))
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
	tooltip_panel.global_position = TooltipPositioner.get_tooltip_position(
		global_position,
		tooltip_panel.size,
		get_viewport().get_visible_rect(),
		TOOLTIP_OFFSET
	)
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


func _try_use_sub_skill(mouse_position: Vector2) -> void:
	if not _can_use_sub_skill():
		return
	_dragging = true
	seed_skill_drag_started.emit(self, seed_skill, mouse_position)


func _can_use_sub_skill() -> bool:
	return sub_skill_drag_enabled and seed_skill != null and seed_skill.sub_skill_mode != DreamSeedSkillDefinition.SubSkillMode.None and _has_sub_skill() and _remaining_sub_skill_uses > 0


func _has_sub_skill() -> bool:
	return DreamSeedSkillDescriptionFormatter.has_sub_skill(seed_skill)


func _update_drag_state() -> void:
	if icon_rect != null:
		icon_rect.self_modulate = LOW_SUB_SKILL_USES_COLOR if _can_use_sub_skill() and _remaining_sub_skill_uses <= 1 else NORMAL_ICON_COLOR
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if _can_use_sub_skill() else Control.CURSOR_ARROW
