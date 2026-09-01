class_name NovelDebugPanel
extends Control

signal image_position_changed(image_index: int, position: Vector2)
signal drag_mode_changed(is_enabled: bool)

@onready var debug_button: Button = $DebugButton
@onready var background: Panel = $Background
@onready var controls: VBoxContainer = $Controls
@onready var image_selector: OptionButton = $Controls/ImageSelector
@onready var x_position: SpinBox = $Controls/PositionRow/XPosition
@onready var y_position: SpinBox = $Controls/PositionRow/YPosition
@onready var drag_mode_button: Button = $Controls/DragModeButton
@onready var drag_mode_label: Label = $DragModeLabel

var _is_updating_position := false
var _image_positions: Dictionary[int, Vector2] = {}
var _debug_state: Node


func _ready() -> void:
	_debug_state = get_node("/root/DebugState")
	debug_button.pressed.connect(Callable(_debug_state, "toggle_debug_enabled"))
	image_selector.item_selected.connect(_on_image_selected)
	x_position.value_changed.connect(_on_position_value_changed)
	y_position.value_changed.connect(_on_position_value_changed)
	drag_mode_button.toggled.connect(_on_drag_mode_toggled)
	var debug_changed_callback := Callable(self, "_on_debug_enabled_changed")
	if not _debug_state.is_connected("debug_enabled_changed", debug_changed_callback):
		_debug_state.connect("debug_enabled_changed", debug_changed_callback)
	_apply_debug_state(bool(_debug_state.get("debug_enabled")))


func set_images(images: Dictionary[int, TextureRect]) -> void:
	_image_positions.clear()
	var previous_index := get_selected_image_index()
	image_selector.clear()
	var indices: Array = images.keys()
	indices.sort()
	for image_index: int in indices:
		var image := images[image_index] as TextureRect
		_image_positions[image_index] = image.position
		var texture_name := image.texture.resource_path.get_file() if image.texture != null else "Texture2D"
		image_selector.add_item("img %d: %s" % [image_index, texture_name])
		image_selector.set_item_metadata(image_selector.item_count - 1, image_index)
		if image_index == previous_index:
			image_selector.select(image_selector.item_count - 1)
	controls.modulate = Color.WHITE if not indices.is_empty() else Color(1.0, 1.0, 1.0, 0.5)
	image_selector.disabled = indices.is_empty()
	x_position.editable = not indices.is_empty()
	y_position.editable = not indices.is_empty()
	drag_mode_button.disabled = indices.is_empty()
	if indices.is_empty():
		set_drag_mode(false)
		_update_position_fields(Vector2.ZERO)
		return
	var selected_index := get_selected_image_index()
	_update_position_fields(_image_positions[selected_index])


func set_selected_position(position: Vector2) -> void:
	var image_index := get_selected_image_index()
	if image_index >= 0:
		_image_positions[image_index] = position
	_update_position_fields(position)


func get_selected_image_index() -> int:
	if image_selector.item_count == 0 or image_selector.selected < 0:
		return -1
	return int(image_selector.get_item_metadata(image_selector.selected))


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


func _on_image_selected(_item_index: int) -> void:
	var image_index := get_selected_image_index()
	if image_index >= 0:
		_update_position_fields(_image_positions[image_index])


func _on_position_value_changed(_value: float) -> void:
	if _is_updating_position:
		return
	var image_index := get_selected_image_index()
	if image_index < 0:
		return
	var position := Vector2(x_position.value, y_position.value)
	_image_positions[image_index] = position
	image_position_changed.emit(image_index, position)


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
