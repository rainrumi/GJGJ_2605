extends Node2D

signal selection_finished(recovered_hp_rate: float)

const HP_RECOVERY_RATE := 0.1
const MAX_HP := 100
const HP_GAUGE_TWEEN_DURATION := 0.35
const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const HOVER_TWEEN_DURATION := 0.1
const RARITY_NORMAL := "normal"
const RARITY_HIGH := "high"
const HEAD_FLOWER_DISPLAY_COUNT := 1
const ABANDON_BUTTON_PRESSED_MODULATE := Color(1.0, 1.0, 1.0, 1.0)
const ABANDON_BUTTON_DEFAULT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

const FLOWER_TEXTURE_NORMAL := preload("res://art/dreamseed/flower/tex_passive_flower_1000.png")
const FLOWER_TEXTURE_HIGH := preload("res://art/dreamseed/flower/tex_seed_2000_demo_1000.png")
const SEED_FRAME_NORMAL := preload("res://art/stage_clear/ui_choise_seed_frame_1000_LV_100.png")
const SEED_FRAME_HIGH := preload("res://art/stage_clear/ui_choise_seed_frame_1000_LV_200.png")

const SEED_OPTIONS: Array[Dictionary] = [
	{
		"name": "カーネーション",
		"rarity": RARITY_NORMAL,
		"effect": "HP +10%",
		"effect_font_size": 21,
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_100.png"),
		"frame_texture": SEED_FRAME_NORMAL,
		"flower_texture": FLOWER_TEXTURE_NORMAL,
	},
	{
		"name": "カモミール",
		"rarity": RARITY_NORMAL,
		"effect": "悪夢を消化するときに追加でHP+5%回復",
		"effect_font_size": 19,
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_200.png"),
		"frame_texture": SEED_FRAME_NORMAL,
		"flower_texture": FLOWER_TEXTURE_NORMAL,
	},
	{
		"name": "カプチーノ",
		"rarity": RARITY_HIGH,
		"effect": "胃の中に入っている悪夢がひとつの間だけ、受けるダメージ-50%",
		"effect_font_size": 17,
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_300.png"),
		"frame_texture": SEED_FRAME_HIGH,
		"flower_texture": FLOWER_TEXTURE_HIGH,
	},
]

@export var max_normal_flowers := 3
@export var max_high_flowers := 2

@onready var hp_gauge: NinePatchRect = $CharacterArea/HpFrame/HpGauge
@onready var hp_text: Label = $CharacterArea/HpFrame/HpText
@onready var planted_info_text: Label = $CharacterArea/PlantedInfoFrame/PlantedInfoText
@onready var guide_text: Label = $UI/GuideText
@onready var seed_choices: Array[StageClearSeedChoice] = [
	$UI/SeedChoices/SeedChoice1 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice2 as StageClearSeedChoice,
	$UI/SeedChoices/SeedChoice3 as StageClearSeedChoice,
]
@onready var abandon_button: Button = $UI/AbandonButton
@onready var abandon_button_frame: TextureRect = $UI/AbandonButton/Frame
@onready var flower_slots: Array[Button] = [
	$CharacterArea/FlowerSlots/FlowerSlot1 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot2 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot3 as Button,
]

var planted_flowers: Array[Dictionary] = []
var current_hp := MAX_HP
var _hp_gauge_full_width := 0.0
var _hp_gauge_tween: Tween
var _abandon_button_base_scale := Vector2.ONE
var _abandon_button_hover_tween: Tween
var _abandon_button_hovered := false
var _abandon_button_pressed := false


func _ready() -> void:
	_capture_hp_gauge_size()
	_capture_button_scales()
	_initialize_planted_flowers()
	_setup_seed_choices()
	_setup_flower_slots()
	abandon_button.button_down.connect(_on_abandon_button_down)
	abandon_button.button_up.connect(_on_abandon_button_up)
	abandon_button.pressed.connect(_on_abandon_button_pressed)
	abandon_button.mouse_entered.connect(_on_abandon_button_mouse_entered)
	abandon_button.mouse_exited.connect(_on_abandon_button_mouse_exited)
	_set_hp(current_hp, false)
	_show_select_mode()


func setup_hp(value: int) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	if is_node_ready():
		_set_hp(current_hp, false)
		_show_select_mode()


func _initialize_planted_flowers() -> void:
	planted_flowers = [
		_create_flower("ひとつめの花", RARITY_NORMAL, FLOWER_TEXTURE_NORMAL),
	]
	_refresh_flower_slots()


func _setup_seed_choices() -> void:
	for i in range(seed_choices.size()):
		var seed_choice := seed_choices[i]
		var seed: Dictionary = SEED_OPTIONS[i]
		seed_choice.setup_choice(
			str(seed["name"]),
			str(seed["effect"]),
			seed["seed_texture"] as Texture2D,
			seed["frame_texture"] as Texture2D,
			int(seed["effect_font_size"])
		)
		seed_choice.pressed.connect(_on_seed_choice_pressed.bind(i))


func _setup_flower_slots() -> void:
	for slot in flower_slots:
		slot.disabled = true


func _show_select_mode() -> void:
	guide_text.text = "夢の種をひとつ選んでください"
	abandon_button.disabled = false
	_reset_abandon_button_visual()
	_reset_abandon_button_scale()
	abandon_button.text = "放棄する　HP +10%回復"
	for seed_choice in seed_choices:
		seed_choice.set_choice_disabled(false)
	for slot in flower_slots:
		slot.disabled = true


func _on_seed_choice_pressed(seed_index: int) -> void:
	var seed: Dictionary = SEED_OPTIONS[seed_index]
	if _can_plant_seed(seed):
		planted_flowers.append(_create_flower_from_seed(seed))
		_refresh_flower_slots()
		selection_finished.emit(0.0)
		_show_finished_mode("%sを植えました" % str(seed["name"]))
		return
	_replace_flower(seed)
	_refresh_flower_slots()
	selection_finished.emit(0.0)
	_show_finished_mode("%sを植え替えました" % str(seed["name"]))


func _on_abandon_button_pressed() -> void:
	var recovered_hp := mini(MAX_HP, current_hp + ceili(float(MAX_HP) * HP_RECOVERY_RATE))
	_set_hp(recovered_hp, true)
	selection_finished.emit(HP_RECOVERY_RATE)
	_reset_abandon_button_scale()
	_show_finished_mode("種を放棄してHPを10%回復しました")


func _show_finished_mode(message: String) -> void:
	guide_text.text = message
	abandon_button.disabled = true
	_reset_abandon_button_visual()
	_reset_abandon_button_scale()
	for seed_choice in seed_choices:
		seed_choice.set_choice_disabled(true)
	for slot in flower_slots:
		slot.disabled = true


func _create_flower_from_seed(seed: Dictionary) -> Dictionary:
	return _create_flower(
		str(seed["name"]),
		str(seed["rarity"]),
		seed["flower_texture"] as Texture2D
	)


func _create_flower(name: String, rarity: String, flower_texture: Texture2D) -> Dictionary:
	return {
		"name": name,
		"rarity": rarity,
		"flower_texture": flower_texture,
	}


func _can_plant_seed(seed: Dictionary) -> bool:
	var rarity := str(seed["rarity"])
	return _count_planted_by_rarity(rarity) < _get_max_flowers_by_rarity(rarity)


func _replace_flower(seed: Dictionary) -> void:
	var rarity := str(seed["rarity"])
	for i in range(planted_flowers.size()):
		if str(planted_flowers[i]["rarity"]) != rarity:
			continue
		planted_flowers[i] = _create_flower_from_seed(seed)
		return


func _count_planted_by_rarity(rarity: String) -> int:
	var count := 0
	for flower in planted_flowers:
		if str(flower["rarity"]) == rarity:
			count += 1
	return count


func _get_max_flowers_by_rarity(rarity: String) -> int:
	match rarity:
		RARITY_NORMAL:
			return max_normal_flowers
		RARITY_HIGH:
			return max_high_flowers
	return 0


func _refresh_flower_slots() -> void:
	for i in range(flower_slots.size()):
		var texture_rect := flower_slots[i].get_node("FlowerTexture") as TextureRect
		if i >= HEAD_FLOWER_DISPLAY_COUNT or i >= planted_flowers.size():
			texture_rect.texture = null
			flower_slots[i].disabled = true
			continue
		texture_rect.texture = planted_flowers[i]["flower_texture"] as Texture2D
		flower_slots[i].disabled = true
	_update_planted_info_text()


func _update_planted_info_text() -> void:
	var normal_remaining := maxi(0, max_normal_flowers - _count_planted_by_rarity(RARITY_NORMAL))
	var high_remaining := maxi(0, max_high_flowers - _count_planted_by_rarity(RARITY_HIGH))
	planted_info_text.text = "植えられる本数\n通常　あと %d本\n高級　あと %d本" % [normal_remaining, high_remaining]


func _on_abandon_button_down() -> void:
	_abandon_button_pressed = true
	abandon_button_frame.modulate = ABANDON_BUTTON_PRESSED_MODULATE
	_update_abandon_button_scale()


func _on_abandon_button_up() -> void:
	_abandon_button_pressed = false
	_abandon_button_hovered = false
	_reset_abandon_button_visual()
	_update_abandon_button_scale()


func _reset_abandon_button_visual() -> void:
	abandon_button_frame.modulate = ABANDON_BUTTON_DEFAULT_MODULATE


func _capture_button_scales() -> void:
	abandon_button_frame.pivot_offset = abandon_button_frame.size * 0.5
	_abandon_button_base_scale = abandon_button_frame.scale


func _capture_hp_gauge_size() -> void:
	_hp_gauge_full_width = hp_gauge.size.x


func _set_hp(value: int, animated: bool) -> void:
	current_hp = clampi(value, 0, MAX_HP)
	hp_text.text = "%d/%d" % [current_hp, MAX_HP]
	var hp_ratio := clampf(float(current_hp) / float(MAX_HP), 0.0, 1.0)
	var target_size := Vector2(_hp_gauge_full_width * hp_ratio, hp_gauge.size.y)
	if _hp_gauge_tween != null and _hp_gauge_tween.is_valid():
		_hp_gauge_tween.kill()
	if current_hp > 0:
		hp_gauge.visible = true
	if not animated:
		hp_gauge.size = target_size
		if current_hp == 0:
			hp_gauge.visible = false
		return
	_hp_gauge_tween = create_tween()
	_hp_gauge_tween.set_trans(Tween.TRANS_QUAD)
	_hp_gauge_tween.set_ease(Tween.EASE_OUT)
	_hp_gauge_tween.tween_property(hp_gauge, "size", target_size, HP_GAUGE_TWEEN_DURATION)
	if current_hp == 0:
		_hp_gauge_tween.tween_callback(func() -> void: hp_gauge.visible = false)


func _on_abandon_button_mouse_entered() -> void:
	_abandon_button_hovered = true
	_update_abandon_button_scale()


func _on_abandon_button_mouse_exited() -> void:
	_abandon_button_hovered = false
	_abandon_button_pressed = false
	_update_abandon_button_scale()


func _update_abandon_button_scale() -> void:
	if _abandon_button_hover_tween != null and _abandon_button_hover_tween.is_valid():
		_abandon_button_hover_tween.kill()
	var target_scale := _abandon_button_base_scale
	if _abandon_button_hovered:
		target_scale *= HOVER_SCALE
	if _abandon_button_pressed:
		target_scale = _abandon_button_base_scale * PRESSED_SCALE
	_abandon_button_hover_tween = create_tween()
	_abandon_button_hover_tween.set_trans(Tween.TRANS_QUAD)
	_abandon_button_hover_tween.set_ease(Tween.EASE_OUT)
	_abandon_button_hover_tween.tween_property(
		abandon_button_frame,
		"scale",
		target_scale,
		HOVER_TWEEN_DURATION
	)


func _reset_abandon_button_scale() -> void:
	_abandon_button_hovered = false
	_abandon_button_pressed = false
	if _abandon_button_hover_tween != null and _abandon_button_hover_tween.is_valid():
		_abandon_button_hover_tween.kill()
	abandon_button_frame.scale = _abandon_button_base_scale
