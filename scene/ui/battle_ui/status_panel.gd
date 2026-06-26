class_name StatusPanel
extends Control

signal debug_message_requested(is_active: bool)
signal debug_reroll_requested
signal debug_stomach_size_requested(delta_columns: int, delta_rows: int)
signal debug_seed_requested

const DEBUG_BUTTON_NORMAL_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_FONT_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const DEBUG_BUTTON_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_HOVER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DEBUG_BUTTON_ACTIVE_PRESSED_COLOR := Color(0.76, 0.76, 0.76, 1.0)

@onready var message_text: Label = $MessageText
@onready var debug_stomach_x_plus_button: Button = $DebugStomachXPlusButton
@onready var debug_stomach_x_minus_button: Button = $DebugStomachXMinusButton
@onready var debug_stomach_y_plus_button: Button = $DebugStomachYPlusButton
@onready var debug_stomach_y_minus_button: Button = $DebugStomachYMinusButton
@onready var debug_reroll_button: Button = $DebugRerollButton
@onready var debug_seed_button: Button = $DebugSeedButton
@onready var debug_message_button: Button = $DebugMessageButton

var debug_message := ""
var debug_button_active := false


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	_set_debug_controls_visible(false)
	debug_stomach_x_plus_button.pressed.connect(_on_debug_stomach_x_plus_button_pressed)
	debug_stomach_x_minus_button.pressed.connect(_on_debug_stomach_x_minus_button_pressed)
	debug_stomach_y_plus_button.pressed.connect(_on_debug_stomach_y_plus_button_pressed)
	debug_stomach_y_minus_button.pressed.connect(_on_debug_stomach_y_minus_button_pressed)
	debug_reroll_button.pressed.connect(_on_debug_reroll_button_pressed)
	debug_seed_button.pressed.connect(_on_debug_seed_button_pressed)
	debug_message_button.pressed.connect(_on_debug_message_button_pressed)
	_connect_debug_state()
	set_debug_button_active(DebugState.debug_enabled)


# 文言を反映
func set_message(message: String) -> void:
	message_text.text = message


# デバッグ文言
func set_debug_message(message: String) -> void:
	debug_message = message


# ボタン状態
func set_debug_button_active(is_active: bool) -> void:
	debug_button_active = is_active
	if is_active:
		_apply_active_style()
		return
	_apply_normal_style()


# Debug切替
func toggle_debug_message() -> void:
	DebugState.toggle_debug_enabled()


# デバッグstate接続
func _connect_debug_state() -> void:
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)


# 変更処理
func _on_debug_enabled_changed(is_enabled: bool) -> void:
	set_debug_button_active(is_enabled)
	debug_message_requested.emit(is_enabled)


# Reroll要求
func request_debug_reroll() -> void:
	if not debug_button_active:
		return
	debug_reroll_requested.emit()


# 入力無視設定
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_stomach_x_plus_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_stomach_x_minus_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_stomach_y_plus_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_stomach_y_minus_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_seed_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_message_button.mouse_filter = Control.MOUSE_FILTER_STOP


# 有効表示
func _apply_active_style() -> void:
	_set_debug_controls_visible(true)
	debug_message_button.add_theme_color_override("font_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
	debug_message_button.add_theme_stylebox_override("normal", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
	debug_message_button.add_theme_stylebox_override("hover", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_HOVER_COLOR))
	debug_message_button.add_theme_stylebox_override("pressed", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_PRESSED_COLOR))
	debug_message_button.add_theme_stylebox_override("focus", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))


# 通常表示
func _apply_normal_style() -> void:
	_set_debug_controls_visible(false)
	debug_message_button.add_theme_color_override("font_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.remove_theme_stylebox_override("normal")
	debug_message_button.remove_theme_stylebox_override("hover")
	debug_message_button.remove_theme_stylebox_override("pressed")
	debug_message_button.remove_theme_stylebox_override("focus")


# 枠を作成
func _create_debug_button_style(color: Color) -> StyleBoxFlat:
	# スタイル
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		style.set_corner_radius(corner, 2)
	return style


# デバッグcontrolsvisibl設定
func _set_debug_controls_visible(is_visible: bool) -> void:
	debug_stomach_x_plus_button.visible = is_visible
	debug_stomach_x_minus_button.visible = is_visible
	debug_stomach_y_plus_button.visible = is_visible
	debug_stomach_y_minus_button.visible = is_visible
	debug_reroll_button.visible = is_visible
	debug_seed_button.visible = is_visible


# Debug押下
func _on_debug_message_button_pressed() -> void:
	toggle_debug_message()


# Reroll押下
func _on_debug_reroll_button_pressed() -> void:
	request_debug_reroll()


# 押下処理
func _on_debug_seed_button_pressed() -> void:
	if not debug_button_active:
		return
	debug_seed_requested.emit()


# 押下処理
func _on_debug_stomach_x_plus_button_pressed() -> void:
	debug_stomach_size_requested.emit(1, 0)


# 押下処理
func _on_debug_stomach_x_minus_button_pressed() -> void:
	debug_stomach_size_requested.emit(-1, 0)


# 押下処理
func _on_debug_stomach_y_plus_button_pressed() -> void:
	debug_stomach_size_requested.emit(0, 1)


# 押下処理
func _on_debug_stomach_y_minus_button_pressed() -> void:
	debug_stomach_size_requested.emit(0, -1)
