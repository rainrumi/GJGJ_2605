class_name StageSelectLocationMarker
extends Node2D

const FRAME_DURATION := 0.1
const FILL_COLOR := Color(0.9411765, 0.8784314, 1.0, 1.0)

@export var fill_frames: Array[Texture2D] = []
@export var fill_texture: Texture2D

@onready var fill: Sprite2D = $Fill

var _frame_index := 0
var _frame_elapsed := 0.0
var _playing := false


# 初期化
func _ready() -> void:
	visible = false
	scale = Vector2.ONE


# 毎フレーム処理
func _process(delta: float) -> void:
	_process_frame(delta)


# marker初期化
func setup_marker() -> void:
	visible = false
	scale = Vector2.ONE
	fill.self_modulate = FILL_COLOR
	_apply_initial_texture()


# 現在地設定
func set_stage_position(map_position: Vector2) -> void:
	position = map_position
	visible = true
	_reset_frame()
	play_marker()


# 現在地消去
func clear_stage() -> void:
	visible = false
	_playing = false


# 一時停止
func pause_marker() -> void:
	_playing = false
	_reset_frame()


# 再生
func play_marker() -> void:
	if not visible:
		return
	_playing = true


# 初期画像適用
func _apply_initial_texture() -> void:
	if not fill_frames.is_empty():
		fill.texture = fill_frames[0]
	elif fill_texture != null:
		fill.texture = fill_texture


# フレーム処理
func _process_frame(delta: float) -> void:
	if not visible or not _playing:
		return
	if fill_frames.is_empty():
		return
	_frame_elapsed += delta
	if _frame_elapsed < FRAME_DURATION:
		return
	_frame_elapsed -= FRAME_DURATION
	_frame_index = (_frame_index + 1) % fill_frames.size()
	_apply_frame()


# フレーム初期化
func _reset_frame() -> void:
	_frame_index = 0
	_frame_elapsed = 0.0
	_apply_frame()


# フレーム適用
func _apply_frame() -> void:
	if not fill_frames.is_empty():
		fill.texture = fill_frames[_frame_index % fill_frames.size()]
