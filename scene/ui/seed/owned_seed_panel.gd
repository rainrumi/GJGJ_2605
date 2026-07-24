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
const SLOT_SIZE := Vector2(30.0, 30.0)
const SLOT_SEPARATION := 10
const EQUIPPED_TOOLTIP_TEXT := "ここに入れている夢の種はメインスキルの効果を発揮します。ドラッグして食べるとサブスキルの効果を発揮します。"
const STORED_TOOLTIP_TEXT := "現在所持している夢の種です。何も効果を発揮しませんが、ドラッグして食べるとサブスキルの効果を発揮します"

@onready var equipped_list: SeedButtonList = $UpperArea/EquippedList
@onready var stored_list: SeedButtonList = $StoredArea/StoredList
@onready var equipped_label: Label = $UpperArea/EquippedLabel
@onready var stored_label: Label = $StoredArea/StoredLabel
@onready var close_button: TextureButton = $CloseButton
@onready var panel_lock_toggle: CheckBox = $PanelLockToggle
@onready var previous_page_button: Button = $StoredArea/PreviousPageButton
@onready var next_page_button: Button = $StoredArea/NextPageButton
@onready var heading_tooltip: SeedTooltip = $HeadingTooltip
@onready var drag_preview: TextureRect = $DragPreview

var _equipped_seeds: Array[SeedInfo] = []
var _stored_seeds: Array[SeedInfo] = []
var _stored_page := 0
var _debug_numbers_visible := false


# 初期化
func _ready() -> void:
	_configure_seed_lists()
	_connect_signals()
	_refresh()


# 入力
func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or panel_lock_toggle.button_pressed:
		return
	if not event is InputEventMouseButton:
		return
	var mouse_event := event as InputEventMouseButton
	if get_global_rect().has_point(mouse_event.global_position):
		return
	close_panel()


# 所有種設定
func set_seed_inventory(equipped_seeds: Array, stored_seeds: Array) -> void:
	_equipped_seeds = _get_seed_slots(equipped_seeds, EQUIPPED_SLOT_COUNT)
	_stored_seeds = _get_seed_slots(stored_seeds)
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
	heading_tooltip.hide_tooltip()
	drag_preview.visible = false
	visible = false
	closed.emit()


# パネル内ドラッグ表示判定
func should_show_seed_texture_drag(button: SeedButton, mouse_position: Vector2) -> bool:
	return owns_seed_button(button) and visible and get_global_rect().has_point(mouse_position)


# パネル所有種ボタン判定
func owns_seed_button(button: SeedButton) -> bool:
	return (
		button != null
		and (button.get_parent() == equipped_list or button.get_parent() == stored_list)
	)


# 指定位置のinventory枠取得
func get_seed_slot_at_position(mouse_position: Vector2) -> SeedButton:
	if not visible:
		return null
	for seed_list in [equipped_list, stored_list]:
		for child in seed_list.get_children():
			if child is SeedButton and (child as SeedButton).get_global_rect().has_point(mouse_position):
				return child as SeedButton
	return null


# inventory内slot番号取得
func get_inventory_slot_index(button: SeedButton) -> int:
	if button == null:
		return -1
	if button.get_parent() == equipped_list:
		return button.get_index()
	if button.get_parent() == stored_list:
		return _stored_page * STORED_PAGE_SIZE + button.get_index()
	return -1


# 種list設定
func _configure_seed_lists() -> void:
	equipped_list.set_slot_layout(SLOT_SIZE, SLOT_SEPARATION)
	equipped_list.set_minimum_slot_count(EQUIPPED_SLOT_COUNT)
	equipped_list.set_source_collection(SeedButton.SourceCollection.EQUIPPED)
	equipped_list.set_loadout_edit_enabled(true)
	equipped_list.set_sub_skill_drag_enabled(true)
	equipped_list.set_display_style(true, SLOT_ICON_COLOR)
	stored_list.set_slot_layout(SLOT_SIZE, SLOT_SEPARATION)
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
	equipped_label.mouse_entered.connect(_on_equipped_label_mouse_entered)
	equipped_label.mouse_exited.connect(_on_heading_label_mouse_exited)
	stored_label.mouse_entered.connect(_on_stored_label_mouse_entered)
	stored_label.mouse_exited.connect(_on_heading_label_mouse_exited)
	visibility_changed.connect(_on_visibility_changed)
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


# 種slot取得
func _get_seed_slots(sources: Array, limit: int = -1) -> Array[SeedInfo]:
	var slots: Array[SeedInfo] = []
	for source in sources:
		if source is SeedInfo:
			slots.append(source as SeedInfo)
		else:
			slots.append(null)
		if limit >= 0 and slots.size() >= limit:
			break
	return slots


# 装備見出しhover開始
func _on_equipped_label_mouse_entered() -> void:
	heading_tooltip.set_text(EQUIPPED_TOOLTIP_TEXT)
	heading_tooltip.show_tooltip_at(equipped_label.global_position)


# 所持見出しhover開始
func _on_stored_label_mouse_entered() -> void:
	heading_tooltip.set_text(STORED_TOOLTIP_TEXT)
	heading_tooltip.show_tooltip_at(stored_label.global_position)


# 見出しhover終了
func _on_heading_label_mouse_exited() -> void:
	heading_tooltip.hide_tooltip()


# 表示状態変更
func _on_visibility_changed() -> void:
	if not visible and heading_tooltip != null:
		heading_tooltip.hide_tooltip()
	if not visible and drag_preview != null:
		drag_preview.visible = false


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
	_update_drag_preview(button, seed, mouse_position)
	seed_drag_started.emit(button, seed, mouse_position)


# 種ドラッグ移動
func _on_seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	_update_drag_preview(button, seed, mouse_position)
	seed_drag_moved.emit(button, seed, mouse_position)


# 種ドラッグ解放
func _on_seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	drag_preview.visible = false
	seed_drag_released.emit(button, seed, mouse_position)


# 種回転要求
func _on_seed_rotation_requested(button: SeedButton, seed: SeedInfo) -> void:
	seed_rotation_requested.emit(button, seed)


# ドラッグ中種texture更新
func _update_drag_preview(button: SeedButton, seed: SeedInfo, mouse_position: Vector2) -> void:
	if seed == null or not should_show_seed_texture_drag(button, mouse_position):
		drag_preview.visible = false
		return
	heading_tooltip.hide_tooltip()
	if button.tooltip_panel != null:
		button.tooltip_panel.hide_tooltip()
	drag_preview.texture = seed.texture
	drag_preview.self_modulate = Color.WHITE
	drag_preview.rotation = button.icon_rect.rotation
	drag_preview.global_position = mouse_position - drag_preview.size * 0.5
	drag_preview.visible = drag_preview.texture != null
