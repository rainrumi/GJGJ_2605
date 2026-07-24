class_name StageClearCharacter
extends Node2D

const HEAD_FLOWER_DISPLAY_COUNT := 0

signal seed_equip_requested(seed: SeedInfo)
signal seed_unequip_requested(seed: SeedInfo)
signal seed_move_requested(
	seed: SeedInfo,
	source_collection: int,
	source_index: int,
	target_collection: int,
	target_index: int
)

# HP表示
@onready var hp_view: HpView = $HpView
# 所有種パネル表示ボタン
@onready var owned_seed_open_button: TextureButton = $OwnedSeedOpenButton
# 所有種パネル
@onready var owned_seed_panel: OwnedSeedPanel = $OwnedSeedPanel
# 花スロット
@onready var flower_slots: Array[Button] = [
	$FlowerSlots/FlowerSlot1 as Button,
	$FlowerSlots/FlowerSlot2 as Button,
	$FlowerSlots/FlowerSlot3 as Button,
]

var _planted_flowers: Array[SeedInfo] = []
var _stored_seeds: Array[SeedInfo] = []
var _current_hp := 0
var _max_hp := 1
var _planned_recovery_rate := 0.0
var _debug_numbers_visible := false


# 初期化
func _ready() -> void:
	hp_view.tooltip_requested.connect(_on_hp_view_tooltip_requested)
	hp_view.tooltip_hide_requested.connect(_on_hp_view_tooltip_hide_requested)
	owned_seed_open_button.pressed.connect(_open_owned_seed_panel)
	owned_seed_panel.closed.connect(close_owned_seed_panel)
	owned_seed_panel.equip_requested.connect(_on_seed_equip_requested)
	owned_seed_panel.unequip_requested.connect(_on_seed_unequip_requested)
	owned_seed_panel.seed_drag_released.connect(_on_seed_drag_released)
	_setup_flower_slots()
	_refresh_flower_slots()
	_refresh_owned_seed_panel()
	close_owned_seed_panel()


# HP設定
func set_hp(value: int, max_value: int, animated: bool) -> void:
	_current_hp = clampi(value, 0, max_value)
	_max_hp = maxi(1, max_value)
	hp_view.set_hp(_current_hp, _max_hp, animated)
	hp_view.set_planned_recovery_rate(_planned_recovery_rate)


# HPツール情報設定
func set_hp_tooltip_info(
	rest_minutes: int,
	rest_hp_rate: float,
	rest_recovery_bonus_rate: float
) -> void:
	hp_view.set_tooltip_info(rest_minutes, rest_hp_rate, rest_recovery_bonus_rate)


# HPツール表示
func show_hp_tooltip() -> void:
	hp_view.show_tooltip()


# HPツールat表示
func show_hp_tooltip_at(anchor_global_position: Vector2) -> void:
	hp_view.show_tooltip_at(anchor_global_position)


# HPツール非表示
func hide_hp_tooltip() -> void:
	hp_view.hide_tooltip()


# HP表示hover通知
func _on_hp_view_tooltip_requested(_view: HpView) -> void:
	show_hp_tooltip()


# HP表示hover解除通知
func _on_hp_view_tooltip_hide_requested(_view: HpView) -> void:
	hide_hp_tooltip()


# 回復予定設定
func set_planned_recovery_rate(recovery_rate: float) -> void:
	_planned_recovery_rate = maxf(0.0, recovery_rate)
	hp_view.set_planned_recovery_rate(_planned_recovery_rate)


# 花一覧設定
func set_planted_flowers(flowers: Array[SeedInfo]) -> void:
	_planted_flowers = flowers.duplicate()
	_refresh_flower_slots()
	_refresh_owned_seed_panel()


# 種inventory設定
func set_seed_inventory(
	equipped_seeds: Array[SeedInfo],
	stored_seeds: Array[SeedInfo]
) -> void:
	_planted_flowers = equipped_seeds.duplicate()
	_stored_seeds = stored_seeds.duplicate()
	_refresh_flower_slots()
	_refresh_owned_seed_panel()


# 所有種panel非表示
func close_owned_seed_panel() -> void:
	owned_seed_panel.visible = false
	owned_seed_open_button.visible = true


# debug表示
func set_debug_numbers_visible(is_visible: bool) -> void:
	_debug_numbers_visible = is_visible
	owned_seed_panel.set_debug_numbers_visible(_debug_numbers_visible)


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


# 所有種パネル更新
func _refresh_owned_seed_panel() -> void:
	if owned_seed_panel == null:
		return
	owned_seed_panel.set_seed_inventory(_planted_flowers, _stored_seeds)
	owned_seed_panel.set_debug_numbers_visible(_debug_numbers_visible)


# 所有種panel表示
func _open_owned_seed_panel() -> void:
	hide_hp_tooltip()
	owned_seed_open_button.visible = false
	owned_seed_panel.open_panel()


# 種装備要求
func _on_seed_equip_requested(seed: SeedInfo) -> void:
	seed_equip_requested.emit(seed)


# 種装備解除要求
func _on_seed_unequip_requested(seed: SeedInfo) -> void:
	seed_unequip_requested.emit(seed)


# 種ドラッグ解放
func _on_seed_drag_released(
	source_button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	if not owned_seed_panel.owns_seed_button(source_button):
		return
	var target_button := owned_seed_panel.get_seed_slot_at_position(mouse_position)
	if target_button == null:
		return
	var source_index := owned_seed_panel.get_inventory_slot_index(source_button)
	var target_index := owned_seed_panel.get_inventory_slot_index(target_button)
	seed_move_requested.emit(
		seed,
		source_button.get_source_collection(),
		source_index,
		target_button.get_source_collection(),
		target_index
	)


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
