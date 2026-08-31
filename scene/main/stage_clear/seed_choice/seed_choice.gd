class_name StageClearSeedChoice
extends Button

# 枠ノード
@onready var frame: StageClearSeedChoiceFrame = $Frame
# レア表示
@onready var valuable_icon: StageClearSeedChoiceIconRare = $ValuableIcon
# 種画像
@onready var seed_texture_rect: StageClearSeedChoiceTexture = $Texture
# 名前表示
@onready var name_label: StageClearSeedChoiceLabelName = $NameLabel
# 効果表示
@onready var effect_label: StageClearSeedChoiceLabelEffect = $EffectLabel
@onready var performance_mark: Label = $PerformanceMark

var current_seed: SeedInfo
var debug_numbers_visible := false
var _hovered := false
var _pressed := false


# 初期化
func _ready() -> void:
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	if not DebugState.seed_performance_mark_changed.is_connected(_on_seed_performance_mark_changed):
		DebugState.seed_performance_mark_changed.connect(_on_seed_performance_mark_changed)
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)
	_refresh_performance_mark()


# 選択肢設定
func setup_choice(seed: SeedInfo) -> void:
	current_seed = seed
	frame.setup_choice(seed)
	valuable_icon.setup_choice(seed)
	seed_texture_rect.setup_choice(seed)
	name_label.setup_choice(seed)
	effect_label.setup_choice(seed)
	_refresh_performance_mark()


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	name_label.set_debug_numbers_visible(is_visible)
	_refresh_performance_mark()


# GUI入力処理
func _on_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_button := event as InputEventMouseButton
	if mouse_button.button_index != MOUSE_BUTTON_RIGHT or not mouse_button.pressed:
		return
	if DebugState.toggle_seed_performance_mark(current_seed):
		accept_event()


# 性能チェック表示更新
func _refresh_performance_mark() -> void:
	if performance_mark == null:
		return
	performance_mark.visible = (
		debug_numbers_visible
		and current_seed != null
		and DebugState.is_seed_performance_marked(current_seed.skill_id)
	)


# 性能チェック変更処理
func _on_seed_performance_mark_changed(seed_id: int, _is_marked: bool) -> void:
	if current_seed != null and current_seed.skill_id == seed_id:
		_refresh_performance_mark()


# デバッグ状態変更処理
func _on_debug_enabled_changed(_is_enabled: bool) -> void:
	_refresh_performance_mark()


# 無効設定
func set_choice_disabled(value: bool) -> void:
	disabled = value
	if disabled:
		_reset_scale_state()


# 押下開始
func _on_button_down() -> void:
	_pressed = true
	_update_scale()


# 押下終了
func _on_button_up() -> void:
	_pressed = false
	_hovered = false
	_update_scale()


# ホバー開始
func _on_mouse_entered() -> void:
	_hovered = true
	_update_scale()


# ホバー終了
func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_update_scale()


# scale更新
func _update_scale() -> void:
	frame.set_interaction_state(_hovered, _pressed)


# scale初期化
func _reset_scale_state() -> void:
	_hovered = false
	_pressed = false
	frame.reset_visual_state()
