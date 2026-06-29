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


# 選択肢設定
func setup_choice(seed: SeedInfo) -> void:
	current_seed = seed
	frame.setup_choice(seed)
	valuable_icon.setup_choice(seed)
	seed_texture_rect.setup_choice(seed)
	name_label.setup_choice(seed)
	effect_label.setup_choice(seed)


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	name_label.set_debug_numbers_visible(is_visible)


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
