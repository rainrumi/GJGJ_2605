class_name HoverScaleTextureButton
extends TextureButton

const HOVER_SCALE := 1.1
const TWEEN_DURATION := 0.1

var _base_scale := Vector2.ONE
var _scale_tween: Tween


# 初期化
func _ready() -> void:
	_base_scale = scale
	pivot_offset = size * 0.5
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)


# ホバー開始
func _on_mouse_entered() -> void:
	_set_hovered(true)


# ホバー終了
func _on_mouse_exited() -> void:
	_set_hovered(false)


# 表示状態変更
func _on_visibility_changed() -> void:
	if not is_visible_in_tree():
		reset_visual_state()


# 表示初期化
func reset_visual_state() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	_scale_tween = null
	scale = _base_scale


# ホバー反映
func _set_hovered(is_hovered: bool) -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var target_scale := _base_scale * HOVER_SCALE if is_hovered else _base_scale
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(self, "scale", target_scale, TWEEN_DURATION)
