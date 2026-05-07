extends Node2D

signal selection_finished(recovered_hp_rate: float)

const HP_RECOVERY_RATE := 0.1
const RARITY_NORMAL := "normal"
const RARITY_HIGH := "high"
const HEAD_FLOWER_DISPLAY_COUNT := 1
const ABANDON_BUTTON_PRESSED_MODULATE := Color(0.84, 0.74, 0.82, 1.0)
const ABANDON_BUTTON_DEFAULT_MODULATE := Color(1.0, 1.0, 1.0, 1.0)

const FLOWER_TEXTURE_NORMAL := preload("res://art/dreamseed/flower/tex_passive_flower_1000.png")
const FLOWER_TEXTURE_HIGH := preload("res://art/dreamseed/flower/tex_seed_2000_demo_1000.png")

const SEED_OPTIONS: Array[Dictionary] = [
	{
		"name": "カーネーション",
		"rarity": RARITY_NORMAL,
		"effect": "HP +40%",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_100.png"),
		"flower_texture": FLOWER_TEXTURE_NORMAL,
	},
	{
		"name": "カモミール",
		"rarity": RARITY_NORMAL,
		"effect": "毎ターン終了時にHP +5%",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_200.png"),
		"flower_texture": FLOWER_TEXTURE_NORMAL,
	},
	{
		"name": "カゲツ",
		"rarity": RARITY_HIGH,
		"effect": "高級花のダメージ -20%",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_300.png"),
		"flower_texture": FLOWER_TEXTURE_HIGH,
	},
]

@export var max_normal_flowers := 3
@export var max_high_flowers := 2

@onready var planted_info_text: Label = $CharacterArea/PlantedInfoFrame/PlantedInfoText
@onready var guide_text: Label = $UI/GuideText
@onready var seed_buttons: Array[Button] = [
	$UI/SeedChoices/SeedChoice1 as Button,
	$UI/SeedChoices/SeedChoice2 as Button,
	$UI/SeedChoices/SeedChoice3 as Button,
]
@onready var abandon_button: Button = $UI/AbandonButton
@onready var abandon_button_frame: TextureRect = $UI/AbandonButton/Frame
@onready var flower_slots: Array[Button] = [
	$CharacterArea/FlowerSlots/FlowerSlot1 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot2 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot3 as Button,
]

var planted_flowers: Array[Dictionary] = []


func _ready() -> void:
	_initialize_planted_flowers()
	_setup_seed_buttons()
	_setup_flower_slots()
	abandon_button.button_down.connect(_on_abandon_button_down)
	abandon_button.button_up.connect(_on_abandon_button_up)
	abandon_button.pressed.connect(_on_abandon_button_pressed)
	_show_select_mode()


func _initialize_planted_flowers() -> void:
	planted_flowers = [
		_create_flower("いつもの花", RARITY_NORMAL, FLOWER_TEXTURE_NORMAL),
	]
	_refresh_flower_slots()


func _setup_seed_buttons() -> void:
	for i in range(seed_buttons.size()):
		var button := seed_buttons[i]
		button.pressed.connect(_on_seed_button_pressed.bind(i))
		_apply_seed_button(button, SEED_OPTIONS[i])


func _setup_flower_slots() -> void:
	for slot in flower_slots:
		slot.disabled = true


func _apply_seed_button(button: Button, seed: Dictionary) -> void:
	var seed_texture := button.get_node("SeedTexture") as TextureRect
	var title_label := button.get_node("NameLabel") as Label
	var effect_label := button.get_node("EffectLabel") as Label
	seed_texture.texture = seed["seed_texture"] as Texture2D
	title_label.text = str(seed["name"])
	effect_label.text = str(seed["effect"])


func _show_select_mode() -> void:
	guide_text.text = "夢の種をひとつ選んでください"
	abandon_button.disabled = false
	_reset_abandon_button_visual()
	abandon_button.text = "放棄する（HP +10%回復）"
	for button in seed_buttons:
		button.disabled = false
	for slot in flower_slots:
		slot.disabled = true


func _on_seed_button_pressed(seed_index: int) -> void:
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
	selection_finished.emit(HP_RECOVERY_RATE)
	_show_finished_mode("種を見送り、HPを10%回復しました")


func _show_finished_mode(message: String) -> void:
	guide_text.text = message
	abandon_button.disabled = true
	_reset_abandon_button_visual()
	for button in seed_buttons:
		button.disabled = true
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
	planted_info_text.text = "植えられる本数\n通常 あと %d本\n高級 あと %d本" % [normal_remaining, high_remaining]


func _on_abandon_button_down() -> void:
	abandon_button_frame.modulate = ABANDON_BUTTON_PRESSED_MODULATE


func _on_abandon_button_up() -> void:
	_reset_abandon_button_visual()


func _reset_abandon_button_visual() -> void:
	abandon_button_frame.modulate = ABANDON_BUTTON_DEFAULT_MODULATE
