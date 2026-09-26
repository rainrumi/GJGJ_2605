class_name StageSelectChoice
extends Button

const HOVER_SCALE := 1.05
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1
const NORMAL_TEXT_COLOR := Color(0.0352941, 0.027451, 0.211765, 1.0)
const HIGH_DIFFICULTY_TEXT_COLOR := Color(1.0, 0.027451, 0.211765, 1.0)
const MAX_REWARD_SEED_ICONS := 8
const REWARD_SEED_MORE_ICON_THRESHOLD := 9

@export var reward_seed_more_texture: Texture2D

@onready var frame: NinePatchRect = $Frame
@onready var name_label: Label = $NameLabel
@onready var difficulty_label: Label = $VBoxContainer/DifficultyLabel
@onready var location_label: Label = $VBoxContainer/LocationLabel
@onready var exploration_label: Label = $VBoxContainer/ExplorationLabel
@onready var reward_flow_container: HFlowContainer = $RewardCenterContainer/RewardHBoxContainer
@onready var reward_icon: TextureRect = $RewardCenterContainer/RewardHBoxContainer/RewardIcon

var _base_scale := Vector2.ONE
var _hovered := false
var _pressed := false
var _scale_tween: Tween
var _reward_seed_icons: Array[TextureRect] = []


# 初期化
func _ready() -> void:
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# setup選択肢処理
func setup_choice(
	stage_definition: StageInfo,
	exploration_percent: int = 0,
	is_current_location: bool = false,
	is_waiting_for_strengthened_clear: bool = false
) -> void:
	if stage_definition == null:
		visible = false
		disabled = true
		difficulty_label.text = ""
		name_label.text = ""
		name_label.visible = false
		location_label.text = ""
		exploration_label.text = ""
		reward_icon.texture = null
		_clear_reward_seed_icons()
		return
	visible = true
	disabled = false
	difficulty_label.text = stage_definition.get_difficulty_text()
	name_label.text = ""
	name_label.visible = false
	location_label.text = "%s%s" % [stage_definition.location, "（現在地）" if is_current_location else ""]
	var exploration_text := "探索率 %d%%" % exploration_percent
	if is_waiting_for_strengthened_clear:
		exploration_text += "（能力試験クリア待ち）"
	exploration_label.text = exploration_text
	reward_icon.texture = stage_definition.reward_icon
	_setup_reward_seed_icons(stage_definition.drop_seed_pool)
	_apply_stage_text_color(stage_definition)


func _setup_reward_seed_icons(seed_pool: SeedPoolInfo) -> void:
	_clear_reward_seed_icons()
	if seed_pool == null:
		return

	var rare_seeds: Array[SeedInfo] = []
	for seed in seed_pool.rare_skills:
		if seed == null or seed.rarity != SeedInfo.Rarity.RARE:
			continue
		rare_seeds.append(seed)

	var use_more_icon := rare_seeds.size() >= REWARD_SEED_MORE_ICON_THRESHOLD
	var seed_icon_count := mini(
		rare_seeds.size(), MAX_REWARD_SEED_ICONS - (1 if use_more_icon else 0)
	)
	for index in range(seed_icon_count):
		var seed := rare_seeds[index]
		var icon := reward_icon.duplicate() as TextureRect
		icon.texture = seed.tiny_texture
		icon.visible = true
		reward_flow_container.add_child(icon)
		_reward_seed_icons.append(icon)

	if use_more_icon:
		var more_icon := reward_icon.duplicate() as TextureRect
		more_icon.texture = reward_seed_more_texture
		more_icon.visible = true
		reward_flow_container.add_child(more_icon)
		_reward_seed_icons.append(more_icon)


func _clear_reward_seed_icons() -> void:
	for icon in _reward_seed_icons:
		if not is_instance_valid(icon):
			continue
		reward_flow_container.remove_child(icon)
		icon.free()
	_reward_seed_icons.clear()


# イベント処理
func _on_button_down() -> void:
	_pressed = true
	_update_scale()


# イベント処理
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
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	# 対象scale
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(frame, "scale", target_scale, TWEEN_DURATION)


# ステージ文言color適用
func _apply_stage_text_color(stage_definition: StageInfo) -> void:
	# フォントcolor
	var font_color := HIGH_DIFFICULTY_TEXT_COLOR if stage_definition.is_high_difficulty else NORMAL_TEXT_COLOR
	difficulty_label.add_theme_color_override("font_color", font_color)
	name_label.add_theme_color_override("font_color", font_color)
	location_label.add_theme_color_override("font_color", font_color)
	exploration_label.add_theme_color_override("font_color", font_color)
