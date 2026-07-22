class_name OwnedSeedPanel
extends Panel

signal closed
signal equip_requested(seed: SeedInfo)
signal unequip_requested(seed: SeedInfo)
signal seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_rotation_requested(button: SeedButton, seed: SeedInfo)

const EQUIPPED_SLOT_COUNT := 6
const STORED_PAGE_SIZE := 12
const SLOT_ICON_COLOR := Color(0.015, 0.01, 0.02, 1.0)

@onready var equipped_list: SeedButtonList = $UpperArea/EquippedList
@onready var stored_list: SeedButtonList = $StoredArea/StoredList
@onready var close_button: Button = $UpperArea/CloseButton
@onready var previous_page_button: Button = $StoredArea/PreviousPageButton
@onready var next_page_button: Button = $StoredArea/NextPageButton
@onready var page_label: Label = $StoredArea/PageLabel

var _equipped_seeds: Array[SeedInfo] = []
var _stored_seeds: Array[SeedInfo] = []
var _stored_page := 0
var _debug_numbers_visible := false


# 初期化
func _ready() -> void:
	_configure_seed_lists()
	_connect_signals()
	_refresh()


# 所有種設定
func set_seed_inventory(equipped_seeds: Array, stored_seeds: Array) -> void:
	_equipped_seeds = _get_valid_seeds(equipped_seeds, EQUIPPED_SLOT_COUNT)
	_stored_seeds = _get_valid_seeds(stored_seeds)
	_stored_page = mini(_stored_page, _get_last_page())
	if is_node_ready():
		_refresh()


# デバッグ番号設定
func set_debug_numbers_visible(is_visible: bool) -> void:
	_debug_numbers_visible = is_visible
	if not is_node_ready():
		return
	equipped_list.set_debug_numbers_visible(_debug_numbers_visible)
	stored_list.set_debug_numbers_visible(_debug_numbers_visible)


# panel表示
func open_panel() -> void:
	visible = true
	_refresh()


# panel非表示
func close_panel() -> void:
	visible = false
	closed.emit()


# 種list設定
func _configure_seed_lists() -> void:
	equipped_list.set_minimum_slot_count(EQUIPPED_SLOT_COUNT)
	equipped_list.set_source_collection(SeedButton.SourceCollection.EQUIPPED)
	equipped_list.set_loadout_edit_enabled(true)
	equipped_list.set_sub_skill_drag_enabled(true)
	equipped_list.set_display_style(true, SLOT_ICON_COLOR)
	stored_list.set_minimum_slot_count(STORED_PAGE_SIZE)
	stored_list.set_source_collection(SeedButton.SourceCollection.STORED)
	stored_list.set_loadout_edit_enabled(true)
	stored_list.set_sub_skill_drag_enabled(true)
	stored_list.set_display_style(true, SLOT_ICON_COLOR)


# signal接続
func _connect_signals() -> void:
	close_button.pressed.connect(close_panel)
	previous_page_button.pressed.connect(_on_previous_page_pressed)
	next_page_button.pressed.connect(_on_next_page_pressed)
	equipped_list.loadout_edit_requested.connect(_on_unequip_requested)
	stored_list.loadout_edit_requested.connect(_on_equip_requested)
	_connect_seed_list_signals(equipped_list)
	_connect_seed_list_signals(stored_list)


# 種list共通signal接続
func _connect_seed_list_signals(seed_list: SeedButtonList) -> void:
	seed_list.seed_drag_started.connect(_on_seed_drag_started)
	seed_list.seed_drag_moved.connect(_on_seed_drag_moved)
	seed_list.seed_drag_released.connect(_on_seed_drag_released)
	seed_list.seed_rotation_requested.connect(_on_seed_rotation_requested)


# 表示更新
func _refresh() -> void:
	equipped_list.set_seed_sources(_equipped_seeds)
	stored_list.set_seed_sources(_get_stored_page_seeds())
	equipped_list.set_debug_numbers_visible(_debug_numbers_visible)
	stored_list.set_debug_numbers_visible(_debug_numbers_visible)
	var page_count := maxi(1, _get_last_page() + 1)
	page_label.text = "%d / %d" % [_stored_page + 1, page_count]
	previous_page_button.visible = _stored_page > 0
	next_page_button.visible = _stored_page < _get_last_page()


# 所持page種取得
func _get_stored_page_seeds() -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	var start_index := _stored_page * STORED_PAGE_SIZE
	var end_index := mini(start_index + STORED_PAGE_SIZE, _stored_seeds.size())
	for index in range(start_index, end_index):
		seeds.append(_stored_seeds[index])
	return seeds


# 最終page取得
func _get_last_page() -> int:
	if _stored_seeds.is_empty():
		return 0
	return int((_stored_seeds.size() - 1) / STORED_PAGE_SIZE)


# 有効種取得
func _get_valid_seeds(sources: Array, limit: int = -1) -> Array[SeedInfo]:
	var seeds: Array[SeedInfo] = []
	for source in sources:
		if source is SeedInfo:
			seeds.append(source as SeedInfo)
			if limit >= 0 and seeds.size() >= limit:
				break
	return seeds


# 前page押下
func _on_previous_page_pressed() -> void:
	if _stored_page <= 0:
		return
	_stored_page -= 1
	_refresh()


# 次page押下
func _on_next_page_pressed() -> void:
	if _stored_page >= _get_last_page():
		return
	_stored_page += 1
	_refresh()


# 装備要求
func _on_equip_requested(_button: SeedButton, seed: SeedInfo) -> void:
	equip_requested.emit(seed)


# 装備解除要求
func _on_unequip_requested(_button: SeedButton, seed: SeedInfo) -> void:
	unequip_requested.emit(seed)


# 種ドラッグ開始
func _on_seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	seed_drag_started.emit(button, seed, mouse_position)


# 種ドラッグ移動
func _on_seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	seed_drag_moved.emit(button, seed, mouse_position)


# 種ドラッグ解放
func _on_seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	seed_drag_released.emit(button, seed, mouse_position)


# 種回転要求
func _on_seed_rotation_requested(button: SeedButton, seed: SeedInfo) -> void:
	seed_rotation_requested.emit(button, seed)
