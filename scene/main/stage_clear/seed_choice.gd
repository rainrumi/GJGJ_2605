class_name StageClearSeedChoice
extends Button

const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1
const RARITY_NORMAL: StringName = &"normal"

@onready var frame: NinePatchRect = $Frame
@onready var valuable_icon: NinePatchRect = $ValuableIcon
@onready var seed_texture_rect: TextureRect = $Texture
@onready var name_label: Label = $NameLabel
@onready var effect_label: Label = $EffectLabel

var _base_scale := Vector2.ONE
var _hovered := false
var _pressed := false
var _scale_tween: Tween


func _ready() -> void:
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup_choice(seed: SeedOptionDefinition) -> void:
	name_label.text = _get_seed_display_name(seed)
	effect_label.text = _get_seed_effect_text(seed)
	effect_label.add_theme_font_size_override("font_size", seed.effect_font_size)
	seed_texture_rect.texture = _get_flower_texture(seed)
	frame.texture = seed.frame_texture
	valuable_icon.visible = seed.rarity != RARITY_NORMAL


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


func _get_seed_effect_text(seed: SeedOptionDefinition) -> String:
	if seed.dream_seed_skill == null:
		return seed.effect_text
	var skill := seed.dream_seed_skill
	var lines: Array[String] = [
		"メインスキル: %s" % _get_or_empty(skill.main_description),
	]
	if not skill.sub_description.is_empty():
		lines.append("サブスキル: %s" % skill.sub_description)
	lines.append("残基: %d" % skill.stock_count)
	return "\n".join(lines)


func _get_flower_texture(seed: SeedOptionDefinition) -> Texture2D:
	if seed.flower_definition != null:
		return seed.flower_definition.texture
	return seed.seed_texture


func _get_or_empty(text: String) -> String:
	if text.is_empty():
		return "-"
	return text
