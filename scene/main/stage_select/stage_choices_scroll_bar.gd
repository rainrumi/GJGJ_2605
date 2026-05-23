extends VScrollBar

const FALLBACK_MAIN_BACKGROUND_COLOR := Color(0.1254902, 0.1254902, 0.1254902, 1.0)
const GRABBER_STYLE_NAMES: Array[StringName] = [
	&"grabber",
	&"grabber_highlight",
	&"grabber_pressed",
]


func match_main_background_color() -> void:
	var background_color := _get_main_background_color()
	for style_name in GRABBER_STYLE_NAMES:
		_apply_grabber_color(style_name, background_color)


func _apply_grabber_color(style_name: StringName, background_color: Color) -> void:
	var style_box := get_theme_stylebox(style_name)
	if not style_box is StyleBoxTexture:
		return
	var knob_style := style_box.duplicate() as StyleBoxTexture
	knob_style.modulate_color = background_color
	add_theme_stylebox_override(style_name, knob_style)


func _get_main_background_color() -> Color:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return FALLBACK_MAIN_BACKGROUND_COLOR
	var background_color := current_scene.get_node_or_null("BackgroundColor") as ColorRect
	if background_color == null:
		return FALLBACK_MAIN_BACKGROUND_COLOR
	return background_color.color
