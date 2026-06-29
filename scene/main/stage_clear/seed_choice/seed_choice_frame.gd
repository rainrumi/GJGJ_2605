class_name StageClearSeedChoiceFrame
extends NinePatchRect

const HOVER_SCALE := 1.05
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1

var _base_scale := Vector2.ONE
var _base_texture: Texture2D
var _scale_tween: Tween


# 初期化
func _ready() -> void:
	_base_texture = texture
	pivot_offset = size * 0.5
	_base_scale = scale


# 種表示
func setup_choice(_seed: SeedInfo) -> void:
	texture = _base_texture


# 入力反映
func set_interaction_state(is_hovered: bool, is_pressed: bool) -> void:
	_update_scale(is_hovered, is_pressed)


# 表示初期化
func reset_visual_state() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	scale = _base_scale


# scale更新
func _update_scale(is_hovered: bool, is_pressed: bool) -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var target_scale := _base_scale
	if is_hovered:
		target_scale *= HOVER_SCALE
	if is_pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", target_scale, TWEEN_DURATION)
