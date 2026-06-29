class_name StageSelectDebugButton
extends Button

const NORMAL_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const ACTIVE_FONT_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const ACTIVE_HOVER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const ACTIVE_PRESSED_COLOR := Color(0.76, 0.76, 0.76, 1.0)


# 初期化
func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)
	_apply_state()


# 押下処理
func _on_pressed() -> void:
	DebugState.toggle_debug_enabled()


# 変更処理
func _on_debug_enabled_changed(_is_enabled: bool) -> void:
	_apply_state()


# 状態適用
func _apply_state() -> void:
	if DebugState.debug_enabled:
		add_theme_color_override("font_color", ACTIVE_FONT_COLOR)
		add_theme_color_override("font_hover_color", ACTIVE_FONT_COLOR)
		add_theme_color_override("font_pressed_color", ACTIVE_FONT_COLOR)
		add_theme_stylebox_override("normal", _create_button_style(ACTIVE_COLOR))
		add_theme_stylebox_override("hover", _create_button_style(ACTIVE_HOVER_COLOR))
		add_theme_stylebox_override("pressed", _create_button_style(ACTIVE_PRESSED_COLOR))
		add_theme_stylebox_override("focus", _create_button_style(ACTIVE_COLOR))
		return
	add_theme_color_override("font_color", NORMAL_FONT_COLOR)
	add_theme_color_override("font_hover_color", NORMAL_FONT_COLOR)
	add_theme_color_override("font_pressed_color", NORMAL_FONT_COLOR)
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("hover")
	remove_theme_stylebox_override("pressed")
	remove_theme_stylebox_override("focus")


# ボタンstyle作成
func _create_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		style.set_corner_radius(corner, 2)
	return style
