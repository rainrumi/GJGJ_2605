class_name DreamSeedSkillButtonList
extends HFlowContainer

signal seed_skill_drag_started(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_moved(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)
signal seed_skill_drag_released(button: DreamSeedSkillButton, seed_skill: DreamSeedSkillDefinition, mouse_position: Vector2)

const BUTTON_SCENE := preload("res://scene/ui/dream_seed_skill_button/dream_seed_skill_button.tscn")

var debug_numbers_visible := false
var sub_skill_drag_enabled := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)


func set_seed_sources(sources: Array) -> void:
	_clear_buttons()
	for source in sources:
		if source is Resource and _has_seed_skill(source as Resource):
			_add_seed_button(source as Resource)


func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	for child in get_children():
		if child is DreamSeedSkillButton:
			(child as DreamSeedSkillButton).set_debug_numbers_visible(debug_numbers_visible)


func set_sub_skill_drag_enabled(is_enabled: bool) -> void:
	sub_skill_drag_enabled = is_enabled
	for child in get_children():
		if child is DreamSeedSkillButton:
			(child as DreamSeedSkillButton).set_sub_skill_drag_enabled(sub_skill_drag_enabled)


func _add_seed_button(source: Resource) -> void:
	var button := BUTTON_SCENE.instantiate() as DreamSeedSkillButton
	add_child(button)
	button.set_seed_source(source)
	button.set_debug_numbers_visible(debug_numbers_visible)
	button.set_sub_skill_drag_enabled(sub_skill_drag_enabled)
	button.seed_skill_drag_started.connect(_on_seed_skill_drag_started)
	button.seed_skill_drag_moved.connect(_on_seed_skill_drag_moved)
	button.seed_skill_drag_released.connect(_on_seed_skill_drag_released)


func _clear_buttons() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


func _has_seed_skill(source: Resource) -> bool:
	if source is SeedInfo:
		return (source as SeedInfo).dream_seed_skill != null
	return source is DreamSeedSkillDefinition


func _on_seed_skill_drag_started(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_started.emit(button, seed_skill, mouse_position)


func _on_seed_skill_drag_moved(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_moved.emit(button, seed_skill, mouse_position)


func _on_seed_skill_drag_released(
	button: DreamSeedSkillButton,
	seed_skill: DreamSeedSkillDefinition,
	mouse_position: Vector2
) -> void:
	seed_skill_drag_released.emit(button, seed_skill, mouse_position)
