class_name StageClearUi
extends Control

signal seed_choice_pressed(seed_index: int)
signal seed_choice_hovered(seed_index: int)
signal seed_choice_unhovered
signal abandon_pressed
signal abandon_hovered
signal abandon_unhovered
signal reroll_pressed
signal debug_pressed

const SELECT_GUIDE_TEXT := "夢の種をひとつ選んでください"
const DEBUG_BUTTON_NORMAL_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_FONT_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const DEBUG_BUTTON_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_HOVER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DEBUG_BUTTON_ACTIVE_PRESSED_COLOR := Color(0.76, 0.76, 0.76, 1.0)

# 案内文
@onready var guide_text: Label = $GuideText
# 再抽選ボタン
@onready var reroll_button: Button = $RerollButton
# debugボタン
@onready var debug_button: Button = $DebugButton
# 種選択一覧
@onready var seed_choice_list: StageClearChoiceSeed = $SeedChoices
# 放棄ボタン
@onready var abandon_button: StageClearAbandonButton = $AbandonButton

var _debug_numbers_visible := false
var _seed_choice_active := false


# 初期化
func _ready() -> void:
	_connect_child_signals()
	_apply_debug_button_state()
	_update_reroll_button_state()


# 選択表示
func show_select_mode(abandon_recovery_rate: float) -> void:
	guide_text.text = SELECT_GUIDE_TEXT
	_seed_choice_active = true
	abandon_button.disabled = false
	abandon_button.reset_visual_state()
	abandon_button.set_recovery_rate(abandon_recovery_rate)
	seed_choice_list.set_choices_active(true)
	_update_reroll_button_state()


# 完了表示
func show_finished_mode(message: String) -> void:
	guide_text.text = message
	_seed_choice_active = false
	abandon_button.disabled = true
	abandon_button.reset_visual_state()
	seed_choice_list.set_choices_active(false)
	_update_reroll_button_state()


# 選択肢更新
func setup_seed_choices(seed_options: Array[SeedInfo]) -> void:
	seed_choice_list.setup_choices(seed_options, _seed_choice_active, _debug_numbers_visible)


# debug状態設定
func set_debug_state(is_visible: bool, is_seed_choice_active: bool) -> void:
	_debug_numbers_visible = is_visible
	_seed_choice_active = is_seed_choice_active
	seed_choice_list.set_debug_numbers_visible(_debug_numbers_visible)
	_apply_debug_button_state()
	_update_reroll_button_state()


# 選択数取得
func get_seed_choice_count() -> int:
	return seed_choice_list.get_choice_count()


# 子信号接続
func _connect_child_signals() -> void:
	seed_choice_list.choice_pressed.connect(_on_seed_choice_pressed)
	seed_choice_list.choice_hovered.connect(_on_seed_choice_hovered)
	seed_choice_list.choice_unhovered.connect(_on_seed_choice_unhovered)
	abandon_button.pressed.connect(_on_abandon_button_pressed)
	abandon_button.mouse_entered.connect(_on_abandon_button_mouse_entered)
	abandon_button.mouse_exited.connect(_on_abandon_button_mouse_exited)
	reroll_button.pressed.connect(_on_reroll_button_pressed)
	debug_button.pressed.connect(_on_debug_button_pressed)


# debug外観更新
func _apply_debug_button_state() -> void:
	if _debug_numbers_visible:
		debug_button.add_theme_color_override("font_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_button.add_theme_stylebox_override("normal", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		debug_button.add_theme_stylebox_override("hover", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_HOVER_COLOR))
		debug_button.add_theme_stylebox_override("pressed", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_PRESSED_COLOR))
		debug_button.add_theme_stylebox_override("focus", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		return
	debug_button.add_theme_color_override("font_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_button.remove_theme_stylebox_override("normal")
	debug_button.remove_theme_stylebox_override("hover")
	debug_button.remove_theme_stylebox_override("pressed")
	debug_button.remove_theme_stylebox_override("focus")


# reroll状態更新
func _update_reroll_button_state() -> void:
	reroll_button.visible = _debug_numbers_visible
	reroll_button.disabled = not _debug_numbers_visible or not _seed_choice_active


# debug外観作成
func _create_debug_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		style.set_corner_radius(corner, 2)
	return style


# 種押下通知
func _on_seed_choice_pressed(seed_index: int) -> void:
	seed_choice_pressed.emit(seed_index)


# 種hover通知
func _on_seed_choice_hovered(seed_index: int) -> void:
	seed_choice_hovered.emit(seed_index)


# 種hover解除通知
func _on_seed_choice_unhovered(_seed_index: int) -> void:
	seed_choice_unhovered.emit()


# 放棄押下通知
func _on_abandon_button_pressed() -> void:
	abandon_pressed.emit()


# 放棄hover通知
func _on_abandon_button_mouse_entered() -> void:
	if abandon_button.disabled:
		return
	abandon_hovered.emit()


# 放棄hover解除通知
func _on_abandon_button_mouse_exited() -> void:
	abandon_unhovered.emit()


# reroll通知
func _on_reroll_button_pressed() -> void:
	reroll_pressed.emit()


# debug通知
func _on_debug_button_pressed() -> void:
	debug_pressed.emit()
