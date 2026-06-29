class_name StageSelectBeacon
extends Node2D

const FRAME_DURATION := 0.1
const FILL_COLOR := Color(0.9411765, 0.8784314, 1.0, 1.0)

@export var outline_frames: Array[Texture2D] = []
@export var fill_frames: Array[Texture2D] = []

@onready var outline: Sprite2D = $Outline
@onready var fill: Sprite2D = $Fill

var _scale_tween: Tween
var _frame_index := 0
var _frame_elapsed := 0.0


# 初期化
func _ready() -> void:
	visible = false
	scale = Vector2.ONE


# 毎フレーム処理
func _process(delta: float) -> void:
	_process_frame(delta)


# marker初期化
func setup_marker(background_color: Color) -> void:
	visible = false
	scale = Vector2.ONE
	outline.self_modulate = background_color
	fill.self_modulate = FILL_COLOR
	_reset_frame()


# 位置表示
func show_at(map_position: Vector2) -> void:
	var was_visible := visible
	position = map_position
	visible = true
	if not was_visible:
		_start_animation()


# 非表示
func hide_marker() -> void:
	visible = false
	scale = Vector2.ONE
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()


# アニメ開始
func _start_animation() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		return
	scale = Vector2.ONE
	_scale_tween = create_tween()
	_scale_tween.set_loops()
	_scale_tween.set_trans(Tween.TRANS_SINE)
	_scale_tween.set_ease(Tween.EASE_IN_OUT)
	_scale_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.45)
	_scale_tween.tween_property(self, "scale", Vector2.ONE, 0.45)


# フレーム処理
func _process_frame(delta: float) -> void:
	if not visible:
		return
	if outline_frames.is_empty() or fill_frames.is_empty():
		return
	_frame_elapsed += delta
	if _frame_elapsed < FRAME_DURATION:
		return
	_frame_elapsed -= FRAME_DURATION
	_frame_index = (_frame_index + 1) % mini(outline_frames.size(), fill_frames.size())
	_apply_frame()


# フレーム初期化
func _reset_frame() -> void:
	_frame_index = 0
	_frame_elapsed = 0.0
	_apply_frame()


# フレーム適用
func _apply_frame() -> void:
	if not outline_frames.is_empty():
		outline.texture = outline_frames[_frame_index % outline_frames.size()]
	if not fill_frames.is_empty():
		fill.texture = fill_frames[_frame_index % fill_frames.size()]
