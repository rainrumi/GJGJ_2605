class_name DreamSeedSkillButtonList
extends HFlowContainer

const BUTTON_SCENE := preload("res://scene/ui/dream_seed_skill_button/dream_seed_skill_button.tscn")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("h_separation", 2)
	add_theme_constant_override("v_separation", 2)


func set_seed_sources(sources: Array) -> void:
	_clear_buttons()
	for source in sources:
		if source is Resource and _has_seed_skill(source as Resource):
			_add_seed_button(source as Resource)


func _add_seed_button(source: Resource) -> void:
	var button := BUTTON_SCENE.instantiate() as DreamSeedSkillButton
	add_child(button)
	button.set_seed_source(source)


func _clear_buttons() -> void:
	for child in get_children():
		child.free()


func _has_seed_skill(source: Resource) -> bool:
	if source is FlowerDefinition:
		return (source as FlowerDefinition).dream_seed_skill != null
	return source is DreamSeedSkillDefinition
