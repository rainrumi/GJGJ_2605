class_name StageSelectMapView
extends Sprite2D

const FALLBACK_BACKGROUND_COLOR := Color(0.1254902, 0.1254902, 0.1254902, 1.0)

@onready var beacon: StageSelectBeacon = $Beacon
@onready var location_marker: StageSelectLocationMarker = $LocationMarker


# 初期化
func _ready() -> void:
	setup_view()


# 表示初期化
func setup_view() -> void:
	var background_color := _get_background_color()
	beacon.setup_marker(background_color)
	location_marker.setup_marker(background_color)


# ラーラ現在地設定
func set_lara_location(stage_definition: StageInfo) -> void:
	if stage_definition == null:
		location_marker.clear_stage()
		return
	location_marker.set_stage_position(stage_definition.map_position)


# ホバー表示
func show_stage_hover(stage_definition: StageInfo) -> void:
	if stage_definition == null:
		hide_hover()
		return
	beacon.show_at(stage_definition.map_position)


# ホバー解除
func hide_hover() -> void:
	beacon.hide_marker()


# 背景色取得
func _get_background_color() -> Color:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return FALLBACK_BACKGROUND_COLOR
	var background_color := current_scene.get_node_or_null("BackgroundColor") as ColorRect
	if background_color == null:
		return FALLBACK_BACKGROUND_COLOR
	return background_color.color
