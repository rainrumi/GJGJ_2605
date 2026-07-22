class_name SeedButtonList
extends HFlowContainer

signal seed_drag_started(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_moved(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_drag_released(button: SeedButton, seed: SeedInfo, mouse_position: Vector2)
signal seed_rotation_requested(button: SeedButton, seed: SeedInfo)
signal loadout_edit_requested(button: SeedButton, seed: SeedInfo)

const BUTTON_SCENE := preload("res://scene/ui/seed/seed_button.tscn")

var debug_numbers_visible := false
var sub_skill_drag_enabled := false
var loadout_edit_enabled := false
var source_collection := SeedButton.SourceCollection.EQUIPPED
var minimum_slot_count := 0
var frame_visible := true
var icon_color := Color.WHITE
var use_remaining_sub_skill_color := true
var slot_size := Vector2(16.0, 16.0)
var slot_separation := 2
var _rotation_quarter_turns_by_source: Dictionary = {}


# 初期化
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_slot_separation()


# 種sources設定
func set_seed_sources(sources: Array) -> void:
	_clear_buttons()
	var added_count := 0
	for source in sources:
		if source is Resource and _has_seed(source as Resource):
			_add_seed_button_list(source as Resource)
			added_count += 1
	for _slot_index in range(added_count, minimum_slot_count):
		_add_empty_slot()


# デバッグ番号visible設定
func set_debug_numbers_visible(is_visible: bool) -> void:
	debug_numbers_visible = is_visible
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_debug_numbers_visible(debug_numbers_visible)


# subスキルドラッグenabled設定
func set_sub_skill_drag_enabled(is_enabled: bool) -> void:
	sub_skill_drag_enabled = is_enabled
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_sub_skill_drag_enabled(sub_skill_drag_enabled)


# 編成短押し設定
func set_loadout_edit_enabled(is_enabled: bool) -> void:
	loadout_edit_enabled = is_enabled
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_loadout_edit_enabled(loadout_edit_enabled)


# 元collection設定
func set_source_collection(collection: int) -> void:
	source_collection = collection
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_source_collection(source_collection)


# 固定slot数設定
func set_minimum_slot_count(count: int) -> void:
	minimum_slot_count = maxi(0, count)


# 枠layout設定
func set_slot_layout(size_value: Vector2, separation: int) -> void:
	slot_size = Vector2(maxf(1.0, size_value.x), maxf(1.0, size_value.y))
	slot_separation = maxi(0, separation)
	if is_node_ready():
		_apply_slot_separation()
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_slot_size(slot_size)


# 表示style設定
func set_display_style(
	is_frame_visible: bool,
	color: Color,
	show_remaining_sub_skill_color: bool = false
) -> void:
	frame_visible = is_frame_visible
	icon_color = color
	use_remaining_sub_skill_color = show_remaining_sub_skill_color
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_display_style(frame_visible, icon_color, use_remaining_sub_skill_color)


# 種ブロック回転状態リセット
func reset_rotations() -> void:
	_rotation_quarter_turns_by_source.clear()
	for child in get_children():
		if child is SeedButton:
			(child as SeedButton).set_rotation_quarter_turns(0)


# 種ボタン追加
func _add_seed_button_list(source: Resource) -> void:
	# ボタン
	var button := BUTTON_SCENE.instantiate() as SeedButton
	add_child(button)
	button.set_seed_source(source)
	button.set_slot_size(slot_size)
	button.set_debug_numbers_visible(debug_numbers_visible)
	button.set_sub_skill_drag_enabled(sub_skill_drag_enabled)
	button.set_loadout_edit_enabled(loadout_edit_enabled)
	button.set_source_collection(source_collection)
	button.set_display_style(frame_visible, icon_color, use_remaining_sub_skill_color)
	button.set_rotation_quarter_turns(int(_rotation_quarter_turns_by_source.get(source, 0)))
	button.seed_drag_started.connect(_on_seed_drag_started)
	button.seed_drag_moved.connect(_on_seed_drag_moved)
	button.seed_drag_released.connect(_on_seed_drag_released)
	button.seed_rotation_requested.connect(_on_seed_rotation_requested)
	button.loadout_edit_requested.connect(_on_loadout_edit_requested)


# 空slot追加
func _add_empty_slot() -> void:
	var button := BUTTON_SCENE.instantiate() as SeedButton
	add_child(button)
	button.set_seed_source(null)
	button.set_slot_size(slot_size)
	button.set_display_style(true, icon_color, use_remaining_sub_skill_color)
	button.mouse_filter = Control.MOUSE_FILTER_IGNORE


# buttons消去
func _clear_buttons() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()


# 種スキル判定
func _has_seed(source: Resource) -> bool:
	return source is SeedInfo


# 枠間隔適用
func _apply_slot_separation() -> void:
	add_theme_constant_override("h_separation", slot_separation)
	add_theme_constant_override("v_separation", slot_separation)


# 開始処理
func _on_seed_drag_started(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_started.emit(button, seed, mouse_position)


# 移動処理
func _on_seed_drag_moved(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_moved.emit(button, seed, mouse_position)


# 離上処理
func _on_seed_drag_released(
	button: SeedButton,
	seed: SeedInfo,
	mouse_position: Vector2
) -> void:
	seed_drag_released.emit(button, seed, mouse_position)


# 種ブロック回転要求
func _on_seed_rotation_requested(button: SeedButton, seed: SeedInfo) -> void:
	if button == null or seed == null:
		return
	var source := button.get_seed_source()
	if source != null:
		_rotation_quarter_turns_by_source[source] = button.get_rotation_quarter_turns()
	seed_rotation_requested.emit(button, seed)


# 編成短押し要求
func _on_loadout_edit_requested(button: SeedButton, seed: SeedInfo) -> void:
	loadout_edit_requested.emit(button, seed)
