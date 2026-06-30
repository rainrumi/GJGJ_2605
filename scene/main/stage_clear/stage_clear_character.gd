class_name StageClearCharacter
extends Node2D

const HEAD_FLOWER_DISPLAY_COUNT := 0

# HP表示
@onready var hp_view: HpView = $HpView
# 種一覧
@onready var seed_button_list: SeedButtonList = $SeedButtonList
# 花スロット
@onready var flower_slots: Array[Button] = [
	$FlowerSlots/FlowerSlot1 as Button,
	$FlowerSlots/FlowerSlot2 as Button,
	$FlowerSlots/FlowerSlot3 as Button,
]

var _planted_flowers: Array[SeedInfo] = []
var _current_hp := 0
var _max_hp := 1
var _planned_recovery_rate := 0.0
var _debug_numbers_visible := false


# 初期化
func _ready() -> void:
	_setup_flower_slots()
	_refresh_flower_slots()
	_refresh_seed_button_list()


# HP設定
func set_hp(value: int, max_value: int, animated: bool) -> void:
	_current_hp = clampi(value, 0, max_value)
	_max_hp = maxi(1, max_value)
	hp_view.set_hp(_current_hp, _max_hp, animated)
	hp_view.set_planned_recovery_rate(_planned_recovery_rate)


# 回復予定設定
func set_planned_recovery_rate(recovery_rate: float) -> void:
	_planned_recovery_rate = maxf(0.0, recovery_rate)
	hp_view.set_planned_recovery_rate(_planned_recovery_rate)


# 花一覧設定
func set_planted_flowers(flowers: Array[SeedInfo]) -> void:
	_planted_flowers = flowers.duplicate()
	_refresh_flower_slots()
	_refresh_seed_button_list()


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	_debug_numbers_visible = is_visible
	seed_button_list.set_debug_numbers_visible(_debug_numbers_visible)


# slots初期化
func _setup_flower_slots() -> void:
	for slot in flower_slots:
		slot.disabled = true


# 花slot更新
func _refresh_flower_slots() -> void:
	var display_textures := _get_display_flower_textures()
	for i in range(flower_slots.size()):
		var texture_rect := flower_slots[i].get_node("FlowerTexture") as TextureRect
		if i >= HEAD_FLOWER_DISPLAY_COUNT or i >= display_textures.size():
			texture_rect.texture = null
			flower_slots[i].disabled = true
			continue
		texture_rect.texture = display_textures[i]
		flower_slots[i].disabled = true


# 種一覧更新
func _refresh_seed_button_list() -> void:
	if seed_button_list == null:
		return
	seed_button_list.set_seed_sources(_planted_flowers)
	seed_button_list.set_debug_numbers_visible(_debug_numbers_visible)


# 花画像一覧
func _get_display_flower_textures() -> Array[Texture2D]:
	var textures: Array[Texture2D] = []
	for flower in _planted_flowers:
		var texture := _get_display_flower_texture(flower)
		if texture != null:
			textures.append(texture)
	return textures


# 花画像取得
func _get_display_flower_texture(flower: SeedInfo) -> Texture2D:
	if flower == null:
		return null
	return flower.texture
