class_name StageSelectMapView
extends Sprite2D

const BEACON_FRAME_DURATION := 0.1
const LOCATION_MARKER_FRAME_DURATION := 0.1
const FALLBACK_BACKGROUND_COLOR := Color(0.1254902, 0.1254902, 0.1254902, 1.0)
const MARKER_FILL_COLOR := Color(0.9411765, 0.8784314, 1.0, 1.0)

@export var beacon_outline_frames: Array[Texture2D] = []
@export var beacon_fill_frames: Array[Texture2D] = []
@export var location_outline_frames: Array[Texture2D] = []
@export var location_fill_frames: Array[Texture2D] = []
@export var location_outline_texture: Texture2D
@export var location_fill_texture: Texture2D

@onready var beacon: Node2D = $Beacon
@onready var beacon_outline: Sprite2D = $Beacon/Outline
@onready var beacon_fill: Sprite2D = $Beacon/Fill
@onready var location_marker: Node2D = $LocationMarker
@onready var location_marker_outline: Sprite2D = $LocationMarker/Outline
@onready var location_marker_fill: Sprite2D = $LocationMarker/Fill

var _beacon_tween: Tween
var _beacon_frame_index := 0
var _beacon_frame_elapsed := 0.0
var _location_marker_frame_index := 0
var _location_marker_frame_elapsed := 0.0
var _location_marker_playing := false


# 初期化
func _ready() -> void:
	setup_view()


# 毎フレーム処理
func _process(delta: float) -> void:
	_process_beacon_frame(delta)
	_process_location_marker_frame(delta)


# 表示初期化
func setup_view() -> void:
	_setup_beacon()
	_setup_location_marker()


# 現在地設定
func set_current_stage(stage_definition: StageInfo) -> void:
	if stage_definition == null:
		location_marker.visible = false
		_location_marker_playing = false
		return
	location_marker.position = stage_definition.map_position
	location_marker.visible = true
	_reset_location_marker_frame()
	_play_location_marker()


# ホバー表示
func show_stage_hover(stage_definition: StageInfo, is_current_location: bool) -> void:
	if stage_definition == null:
		hide_hover()
		return
	if is_current_location:
		hide_hover()
		return
	_show_beacon(stage_definition.map_position)


# ホバー解除
func hide_hover() -> void:
	beacon.visible = false
	beacon.scale = Vector2.ONE
	if _beacon_tween != null and _beacon_tween.is_valid():
		_beacon_tween.kill()
	_play_location_marker()


# beacon初期化
func _setup_beacon() -> void:
	beacon.visible = false
	beacon.scale = Vector2.ONE
	beacon_outline.self_modulate = _get_background_color()
	beacon_fill.self_modulate = MARKER_FILL_COLOR
	_reset_beacon_frame()


# beacon表示
func _show_beacon(map_position: Vector2) -> void:
	var was_visible := beacon.visible
	beacon.position = map_position
	beacon.visible = true
	_pause_location_marker()
	if not was_visible:
		_start_beacon_animation()


# beacon開始
func _start_beacon_animation() -> void:
	if _beacon_tween != null and _beacon_tween.is_valid():
		return
	beacon.scale = Vector2.ONE
	_beacon_tween = create_tween()
	_beacon_tween.set_loops()
	_beacon_tween.set_trans(Tween.TRANS_SINE)
	_beacon_tween.set_ease(Tween.EASE_IN_OUT)
	_beacon_tween.tween_property(beacon, "scale", Vector2(1.12, 1.12), 0.45)
	_beacon_tween.tween_property(beacon, "scale", Vector2.ONE, 0.45)


# beaconフレーム処理
func _process_beacon_frame(delta: float) -> void:
	if not beacon.visible:
		return
	if beacon_outline_frames.is_empty() or beacon_fill_frames.is_empty():
		return
	_beacon_frame_elapsed += delta
	if _beacon_frame_elapsed < BEACON_FRAME_DURATION:
		return
	_beacon_frame_elapsed -= BEACON_FRAME_DURATION
	_beacon_frame_index = (_beacon_frame_index + 1) % mini(beacon_outline_frames.size(), beacon_fill_frames.size())
	_apply_beacon_frame()


# beaconフレーム初期化
func _reset_beacon_frame() -> void:
	_beacon_frame_index = 0
	_beacon_frame_elapsed = 0.0
	_apply_beacon_frame()


# beaconフレーム適用
func _apply_beacon_frame() -> void:
	if not beacon_outline_frames.is_empty():
		beacon_outline.texture = beacon_outline_frames[_beacon_frame_index % beacon_outline_frames.size()]
	if not beacon_fill_frames.is_empty():
		beacon_fill.texture = beacon_fill_frames[_beacon_frame_index % beacon_fill_frames.size()]


# 現在地初期化
func _setup_location_marker() -> void:
	location_marker.visible = false
	location_marker.scale = Vector2.ONE
	location_marker_outline.self_modulate = _get_background_color()
	location_marker_fill.self_modulate = MARKER_FILL_COLOR
	if not location_outline_frames.is_empty():
		location_marker_outline.texture = location_outline_frames[0]
	elif location_outline_texture != null:
		location_marker_outline.texture = location_outline_texture
	if not location_fill_frames.is_empty():
		location_marker_fill.texture = location_fill_frames[0]
	elif location_fill_texture != null:
		location_marker_fill.texture = location_fill_texture


# 現在地停止
func _pause_location_marker() -> void:
	_location_marker_playing = false
	_reset_location_marker_frame()


# 現在地再生
func _play_location_marker() -> void:
	if not location_marker.visible:
		return
	_location_marker_playing = true


# 現在地フレーム処理
func _process_location_marker_frame(delta: float) -> void:
	if not location_marker.visible or not _location_marker_playing:
		return
	if location_outline_frames.is_empty() or location_fill_frames.is_empty():
		return
	_location_marker_frame_elapsed += delta
	if _location_marker_frame_elapsed < LOCATION_MARKER_FRAME_DURATION:
		return
	_location_marker_frame_elapsed -= LOCATION_MARKER_FRAME_DURATION
	_location_marker_frame_index = (_location_marker_frame_index + 1) % mini(location_outline_frames.size(), location_fill_frames.size())
	_apply_location_marker_frame()


# 現在地フレーム初期化
func _reset_location_marker_frame() -> void:
	_location_marker_frame_index = 0
	_location_marker_frame_elapsed = 0.0
	_apply_location_marker_frame()


# 現在地フレーム適用
func _apply_location_marker_frame() -> void:
	if not location_outline_frames.is_empty():
		location_marker_outline.texture = location_outline_frames[_location_marker_frame_index % location_outline_frames.size()]
	if not location_fill_frames.is_empty():
		location_marker_fill.texture = location_fill_frames[_location_marker_frame_index % location_fill_frames.size()]


# 背景色取得
func _get_background_color() -> Color:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return FALLBACK_BACKGROUND_COLOR
	var background_color := current_scene.get_node_or_null("BackgroundColor") as ColorRect
	if background_color == null:
		return FALLBACK_BACKGROUND_COLOR
	return background_color.color
