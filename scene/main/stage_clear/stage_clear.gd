extends Node2D

signal selection_finished(recovered_hp_rate: float)

const HP_RECOVERY_RATE := 0.1
const RARITY_NORMAL := "normal"
const RARITY_HIGH := "high"
const MAX_FLOWERS_BY_RARITY: Dictionary = {
	"normal": 2,
	"high": 1,
}

const SEED_OPTIONS: Array[Dictionary] = [
	{
		"name": "カーネーション",
		"rarity": RARITY_NORMAL,
		"effect": "HP +40%",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_100.png"),
		"flower_texture": preload("res://art/dreamseed/flower/tex_passive_flower_1000.png"),
	},
	{
		"name": "カモミール",
		"rarity": RARITY_NORMAL,
		"effect": "悪夢消化時に追加でHP +5%回復",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_200.png"),
		"flower_texture": preload("res://art/dreamseed/flower/tex_passive_flower_1000.png"),
	},
	{
		"name": "カゲチーノ",
		"rarity": RARITY_HIGH,
		"effect": "胃袋の悪夢から受けるダメージ -20%",
		"seed_texture": preload("res://art/stage_clear/tex_seed_1000_No_300.png"),
		"flower_texture": preload("res://art/dreamseed/flower/tex_seed_2000_demo_1000.png"),
	},
]

@onready var guide_text: Label = $UI/GuideFrame/GuideText
@onready var seed_buttons: Array[Button] = [
	$UI/SeedChoices/SeedChoice1 as Button,
	$UI/SeedChoices/SeedChoice2 as Button,
	$UI/SeedChoices/SeedChoice3 as Button,
]
@onready var abandon_button: Button = $UI/AbandonButton
@onready var flower_slots: Array[Button] = [
	$CharacterArea/FlowerSlots/FlowerSlot1 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot2 as Button,
	$CharacterArea/FlowerSlots/FlowerSlot3 as Button,
]

var planted_flowers: Array[Dictionary] = []
var selected_seed_index := -1
var waiting_for_replacement := false


func _ready() -> void:
	_initialize_planted_flowers()
	_setup_seed_buttons()
	_setup_flower_slots()
	abandon_button.pressed.connect(_on_abandon_button_pressed)
	_show_select_mode()


func _initialize_planted_flowers() -> void:
	planted_flowers = [
		{
			"name": "既存の花",
			"rarity": RARITY_NORMAL,
			"flower_texture": preload("res://art/dreamseed/flower/tex_passive_flower_1000.png"),
		},
		{
			"name": "既存の花",
			"rarity": RARITY_NORMAL,
			"flower_texture": preload("res://art/dreamseed/flower/tex_passive_flower_1000.png"),
		},
		{
			"name": "高級な花",
			"rarity": RARITY_HIGH,
			"flower_texture": preload("res://art/dreamseed/flower/tex_seed_2000_demo_1000.png"),
		},
	]
	_refresh_flower_slots()


func _setup_seed_buttons() -> void:
	for i in range(seed_buttons.size()):
		var button := seed_buttons[i]
		button.pressed.connect(_on_seed_button_pressed.bind(i))
		var seed: Dictionary = SEED_OPTIONS[i]
		_apply_seed_button(button, seed)


func _setup_flower_slots() -> void:
	for i in range(flower_slots.size()):
		flower_slots[i].pressed.connect(_on_flower_slot_pressed.bind(i))


func _apply_seed_button(button: Button, seed: Dictionary) -> void:
	var seed_texture := button.get_node("SeedTexture") as TextureRect
	var title_label := button.get_node("NameLabel") as Label
	var effect_label := button.get_node("EffectLabel") as Label
	seed_texture.texture = seed["seed_texture"] as Texture2D
	title_label.text = str(seed["name"])
	effect_label.text = str(seed["effect"])


func _show_select_mode() -> void:
	waiting_for_replacement = false
	selected_seed_index = -1
	guide_text.text = "夢の種をひとつ選んでください"
	abandon_button.disabled = false
	abandon_button.text = "放棄する（HP +10%回復）"
	for button in seed_buttons:
		button.disabled = false
	for slot in flower_slots:
		slot.disabled = true


func _show_replacement_mode(seed_index: int) -> void:
	waiting_for_replacement = true
	selected_seed_index = seed_index
	var seed: Dictionary = SEED_OPTIONS[seed_index]
	guide_text.text = "頭がいっぱいです。同じレアリティの花を抜くか、選択を放棄してください"
	abandon_button.disabled = false
	abandon_button.text = "この選択を放棄する（HP +10%回復）"
	for button in seed_buttons:
		button.disabled = true
	for i in range(flower_slots.size()):
		var planted: Dictionary = planted_flowers[i]
		flower_slots[i].disabled = planted["rarity"] != seed["rarity"]


func _on_seed_button_pressed(seed_index: int) -> void:
	var seed: Dictionary = SEED_OPTIONS[seed_index]
	if _can_plant_seed(seed):
		_plant_seed(seed)
		return
	_show_replacement_mode(seed_index)


func _on_flower_slot_pressed(slot_index: int) -> void:
	if not waiting_for_replacement or selected_seed_index == -1:
		return
	var seed: Dictionary = SEED_OPTIONS[selected_seed_index]
	if planted_flowers[slot_index]["rarity"] != seed["rarity"]:
		return
	planted_flowers[slot_index] = _create_flower_from_seed(seed)
	_refresh_flower_slots()
	selection_finished.emit(0.0)
	_show_finished_mode("%sを植えました" % str(seed["name"]))


func _on_abandon_button_pressed() -> void:
	selection_finished.emit(HP_RECOVERY_RATE)
	_show_finished_mode("夢の種を放棄してHPを10%回復しました")


func _can_plant_seed(seed: Dictionary) -> bool:
	var rarity := str(seed["rarity"])
	return _count_planted_by_rarity(rarity) < int(MAX_FLOWERS_BY_RARITY[rarity])


func _plant_seed(seed: Dictionary) -> void:
	planted_flowers.append(_create_flower_from_seed(seed))
	_refresh_flower_slots()
	selection_finished.emit(0.0)
	_show_finished_mode("%sを植えました" % str(seed["name"]))


func _show_finished_mode(message: String) -> void:
	waiting_for_replacement = false
	selected_seed_index = -1
	guide_text.text = message
	abandon_button.disabled = true
	for button in seed_buttons:
		button.disabled = true
	for slot in flower_slots:
		slot.disabled = true


func _create_flower_from_seed(seed: Dictionary) -> Dictionary:
	return {
		"name": seed["name"],
		"rarity": seed["rarity"],
		"flower_texture": seed["flower_texture"],
	}


func _count_planted_by_rarity(rarity: String) -> int:
	var count := 0
	for flower in planted_flowers:
		if flower["rarity"] == rarity:
			count += 1
	return count


func _refresh_flower_slots() -> void:
	for i in range(flower_slots.size()):
		var texture_rect := flower_slots[i].get_node("FlowerTexture") as TextureRect
		if i >= planted_flowers.size():
			texture_rect.texture = null
			flower_slots[i].disabled = true
			continue
		texture_rect.texture = planted_flowers[i]["flower_texture"] as Texture2D
