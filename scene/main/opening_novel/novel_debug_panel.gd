class_name NovelDebugPanel
extends Control

signal image_position_changed(image_index: int, position: Vector2)
signal textbox_geometry_changed(textbox_index: int, position: Vector2, size: Vector2)
signal target_selection_changed
signal drag_mode_changed(is_enabled: bool)

@onready var debug_button: Button = $DebugButton
@onready var background: Panel = $Background
@onready var controls: VBoxContainer = $Controls
@onready var image_selector: OptionButton = $Controls/ImageSelector
@onready var x_position: SpinBox = $Controls/PositionRow/XPosition
@onready var y_position: SpinBox = $Controls/PositionRow/YPosition
@onready var width: SpinBox = $Controls/SizeRow/Width
@onready var height: SpinBox = $Controls/SizeRow/Height
@onready var drag_mode_button: Button = $Controls/DragModeButton
@onready var drag_mode_label: Label = $DragModeLabel

var _is_updating_position := false
var _image_positions: Dictionary[int, Vector2] = {}
var _textbox_geometry: Dictionary[int, Dictionary] = {}
var _items: Array[Dictionary] = []
var _debug_state: Node


func _ready() -> void:
	_debug_state = get_node("/root/DebugState")
	debug_button.pressed.connect(Callable(_debug_state, "toggle_debug_enabled"))
	image_selector.item_selected.connect(_on_image_selected)
	x_position.value_changed.connect(_on_position_value_changed)
	y_position.value_changed.connect(_on_position_value_changed)
	width.value_changed.connect(_on_geometry_value_changed)
	height.value_changed.connect(_on_geometry_value_changed)
	drag_mode_button.toggled.connect(_on_drag_mode_toggled)
	var debug_changed_callback := Callable(self, "_on_debug_enabled_changed")
	if not _debug_state.is_connected("debug_enabled_changed", debug_changed_callback):
		_debug_state.connect("debug_enabled_changed", debug_changed_callback)
	_apply_debug_state(bool(_debug_state.get("debug_enabled")))


func set_images(images: Dictionary[int, TextureRect]) -> void:
	_image_positions.clear()
	var textboxes: Dictionary[int, Control] = {}
	for image_index: int in images:
		var image := images[image_index] as TextureRect
		_image_positions[image_index] = image.position
	_set_targets(images, textboxes)


func set_targets(images: Dictionary[int, TextureRect], textboxes: Dictionary[int, Label]) -> void:
	_image_positions.clear()
	_textbox_geometry.clear()
	for image_index: int in images:
		_image_positions[image_index] = images[image_index].position
	for textbox_index: int in textboxes:
		var textbox := textboxes[textbox_index]
		_textbox_geometry[textbox_index] = {"position": textbox.position, "size": textbox.size}
	_set_targets(images, textboxes)


func _set_targets(images: Dictionary, textboxes: Dictionary) -> void:
	var previous_kind := get_selected_kind()
	var previous_index := get_selected_target_index()
	_items.clear()
	image_selector.clear()
	var image_indices: Array = images.keys()
	image_indices.sort()
	for image_index: int in image_indices:
		var image := images[image_index] as TextureRect
		var texture_name := image.texture.resource_path.get_file() if image.texture != null else "Texture2D"
		var command_name := "img_save" if image_index < 0 else "img"
		var command_index := -image_index - 1 if image_index < 0 else image_index
		_add_target("%s %d: %s" % [command_name, command_index, texture_name], "image", image_index)
	var textbox_indices: Array = textboxes.keys()
	textbox_indices.sort()
	for textbox_index: int in textbox_indices:
		var command_name := "textbox_save_set" if textbox_index < 0 else "textbox_set"
		var command_index := -textbox_index - 1 if textbox_index < 0 else textbox_index
		_add_target("%s %d" % [command_name, command_index], "textbox", textbox_index)
	for item_index in _items.size():
		if _items[item_index].kind == previous_kind and _items[item_index].index == previous_index:
			image_selector.select(item_index)
			break
	if image_selector.selected < 0 and not _items.is_empty():
		image_selector.select(0)
	var has_targets := not _items.is_empty()
	controls.modulate = Color.WHITE if has_targets else Color(1.0, 1.0, 1.0, 0.5)
	image_selector.disabled = not has_targets
	x_position.editable = has_targets
	y_position.editable = has_targets
	drag_mode_button.disabled = not has_targets
	_update_selected_fields()
	if not has_targets:
		set_drag_mode(false)


func _add_target(label: String, kind: String, target_index: int) -> void:
	_items.append({"kind": kind, "index": target_index})
	image_selector.add_item(label)


func set_selected_position(position: Vector2) -> void:
	match get_selected_kind():
		"image":
			_image_positions[get_selected_target_index()] = position
		"textbox":
			var textbox_index := get_selected_target_index()
			_textbox_geometry[textbox_index].position = position
	_update_selected_fields()


func set_selected_geometry(position: Vector2, size: Vector2) -> void:
	var textbox_index := get_selected_textbox_index()
	if get_selected_kind() != "textbox":
		return
	_textbox_geometry[textbox_index] = {"position": position, "size": size}
	_update_selected_fields()


func get_selected_image_index() -> int:
	return get_selected_target_index() if get_selected_kind() == "image" else -1


func get_selected_textbox_index() -> int:
	return get_selected_target_index() if get_selected_kind() == "textbox" else -1


func get_selected_target_index() -> int:
	if image_selector.selected < 0 or image_selector.selected >= _items.size():
		return -1
	return int(_items[image_selector.selected].index)


func get_selected_kind() -> String:
	if image_selector.selected < 0 or image_selector.selected >= _items.size():
		return ""
	return String(_items[image_selector.selected].kind)


func is_drag_mode_enabled() -> bool:
	return drag_mode_button.button_pressed


func set_drag_mode(is_enabled: bool) -> void:
	if drag_mode_button.button_pressed == is_enabled:
		_apply_drag_mode(is_enabled)
		return
	drag_mode_button.set_pressed_no_signal(is_enabled)
	_apply_drag_mode(is_enabled)
	drag_mode_changed.emit(is_enabled)


func _update_position_fields(position: Vector2) -> void:
	_is_updating_position = true
	x_position.value = position.x
	y_position.value = position.y
	_is_updating_position = false


func _update_selected_fields() -> void:
	var kind := get_selected_kind()
	var target_index := get_selected_target_index()
	var position := Vector2.ZERO
	var target_size := Vector2.ZERO
	if kind == "image":
		position = _image_positions.get(target_index, Vector2.ZERO)
	elif kind == "textbox":
		var geometry: Dictionary = _textbox_geometry.get(target_index, {})
		position = geometry.get("position", Vector2.ZERO)
		target_size = geometry.get("size", Vector2.ZERO)
	_update_position_fields(position)
	_is_updating_position = true
	width.value = target_size.x
	height.value = target_size.y
	width.editable = kind == "textbox"
	height.editable = kind == "textbox"
	_is_updating_position = false


func _on_image_selected(_item_index: int) -> void:
	_update_selected_fields()
	target_selection_changed.emit()


func _on_position_value_changed(_value: float) -> void:
	if _is_updating_position:
		return
	var target_index := get_selected_target_index()
	if target_index < 0:
		return
	var position := Vector2(x_position.value, y_position.value)
	if get_selected_kind() == "image":
		_image_positions[target_index] = position
		image_position_changed.emit(target_index, position)
	else:
		var geometry: Dictionary = _textbox_geometry[target_index]
		geometry.position = position
		textbox_geometry_changed.emit(target_index, position, geometry.size)


func _on_geometry_value_changed(_value: float) -> void:
	if _is_updating_position or get_selected_textbox_index() < 0:
		return
	var textbox_index := get_selected_textbox_index()
	var position := Vector2(x_position.value, y_position.value)
	var size := Vector2(width.value, height.value)
	_textbox_geometry[textbox_index] = {"position": position, "size": size}
	textbox_geometry_changed.emit(textbox_index, position, size)


func _on_drag_mode_toggled(is_enabled: bool) -> void:
	_apply_drag_mode(is_enabled)
	drag_mode_changed.emit(is_enabled)


func _on_debug_enabled_changed(is_enabled: bool) -> void:
	_apply_debug_state(is_enabled)


func _apply_debug_state(is_enabled: bool) -> void:
	background.visible = is_enabled
	controls.visible = is_enabled
	debug_button.text = "Debug ON" if is_enabled else "Debug"
	if not is_enabled:
		set_drag_mode(false)


func _apply_drag_mode(is_enabled: bool) -> void:
	drag_mode_label.visible = is_enabled and bool(_debug_state.get("debug_enabled"))
	drag_mode_button.text = "ドラッグ指定モード: ON" if is_enabled else "ドラッグ指定モード"
