class_name StageClearSeedChoice
extends Button

const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1

@onready var frame: NinePatchRect = $Frame
@onready var valuable_icon: NinePatchRect = $ValuableIcon
@onready var seed_texture_rect: TextureRect = $Texture
@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel

var current_seed: SeedOptionDefinition
var debug_numbers_visible := false
var _base_scale := Vector2.ONE
var _base_frame_texture: Texture2D
var _hovered := false
var _pressed := false
var _scale_tween: Tween


func _ready() -> void:
	_base_frame_texture = frame.texture
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup_choice(seed: SeedOptionDefinition) -> void:
	current_seed = seed
	name_label.text = _get_seed_name_text(seed)
	effect_label.text = _get_seed_effect_text(seed)
	seed_texture_rect.texture = _get_flower_texture(seed)
	frame.texture = _get_frame_texture(seed)
	valuable_icon.visible = _is_rare_dream_seed(seed)


func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	if current_seed != null:
		name_label.text = _get_seed_name_text(current_seed)
		effect_label.text = _get_seed_effect_text(current_seed)


func set_choice_disabled(value: bool) -> void:
	disabled = value
	if disabled:
		_reset_scale_state()


func _on_button_down() -> void:
	_pressed = true
	_update_scale()


func _on_button_up() -> void:
	_pressed = false
	_hovered = false
	_update_scale()


func _on_mouse_entered() -> void:
	_hovered = true
	_update_scale()


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_update_scale()


func _update_scale() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(frame, "scale", target_scale, TWEEN_DURATION)


func _reset_scale_state() -> void:
	_hovered = false
	_pressed = false
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	frame.scale = _base_scale


func _get_seed_display_name(seed: SeedOptionDefinition) -> String:
	if seed.dream_seed_skill != null:
		return seed.dream_seed_skill.display_name
	return seed.display_name


func _get_seed_name_text(seed: SeedOptionDefinition) -> String:
	var display_name := _get_seed_display_name(seed)
	if not debug_numbers_visible or seed.dream_seed_skill == null:
		return display_name
	return "%s ID:%d" % [display_name, seed.dream_seed_skill.skill_id]


func _get_seed_effect_text(seed: SeedOptionDefinition) -> String:
	if seed.dream_seed_skill == null:
		return seed.effect_text
	var skill := seed.dream_seed_skill
	var lines: Array[String] = [
		"メインスキル: %s" % DreamSeedSkillDescriptionFormatter.get_main_description(skill),
	]
	if DreamSeedSkillDescriptionFormatter.has_sub_description(skill):
		lines.append("サブスキル: %s" % DreamSeedSkillDescriptionFormatter.get_sub_description(skill))
		lines.append(DreamSeedSkillDescriptionFormatter.get_reward_sub_skill_use_text(skill))
	return "\n".join(lines)


func _get_flower_texture(seed: SeedOptionDefinition) -> Texture2D:
	if seed.flower_definition != null:
		return seed.flower_definition.texture
	return seed.seed_texture


func _get_frame_texture(seed: SeedOptionDefinition) -> Texture2D:
	if _is_rare_dream_seed(seed):
		return _base_frame_texture
	return seed.frame_texture


func _is_rare_dream_seed(seed: SeedOptionDefinition) -> bool:
	if seed.dream_seed_skill == null:
		return false
	return seed.dream_seed_skill.rarity == DreamSeedSkillDefinition.Rarity.RARE
