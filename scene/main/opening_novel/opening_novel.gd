class_name OpeningNovel
extends CanvasLayer

signal finished
signal advanced
signal click_wait_completed

const DEFAULT_TEXT_INTERVAL := 0.04

@export var novel_text: NovelTextInfo

@onready var screen: Control = $Screen
@onready var opening_still: TextureRect = $Screen/OpeningStill
@onready var image_layer: Control = $Screen/ImageLayer
@onready var name_label: Label = $Screen/TextBox/NameLabel
@onready var text_label: Label = $Screen/TextBox/TextLabel
@onready var next_label: Label = $Screen/TextBox/NextLabel
@onready var character_se: AudioStreamPlayer = $CharacterSe
@onready var debug_panel: NovelDebugPanel = $Screen/DebugPanel

var _script_lines: Array[String] = []
var _line_index := 0
var _is_showing := false
var _is_typing := false
var _is_waiting_for_click := false
var _current_text_target := ""
var _typing_request_id := 0
var _script_request_id := 0
var _default_background: Texture2D
var _images: Dictionary[int, TextureRect] = {}
var _image_source_lines: Dictionary[int, int] = {}
var _active_novel_text: NovelTextInfo
var _is_debug_dragging := false


# 初期化
func _ready() -> void:
	_default_background = opening_still.texture
	visible = false
	screen.gui_input.connect(_on_screen_gui_input)
	debug_panel.image_position_changed.connect(_on_debug_image_position_changed)
	debug_panel.drag_mode_changed.connect(_on_debug_drag_mode_changed)
	_refresh_debug_images()


# 対象開始
func start() -> void:
	_start_script(novel_text, true)


# with文言開始
func start_with_text(next_novel_text: NovelTextInfo) -> void:
	_start_script(next_novel_text, false)


# ノベルスクリプト開始
func _start_script(next_novel_text: NovelTextInfo, show_default_background: bool) -> void:
	_script_request_id += 1
	_active_novel_text = next_novel_text
	# requestID
	var request_id := _script_request_id
	_script_lines.clear()
	var script_text := next_novel_text.get_script_text() if next_novel_text != null else ""
	for line in script_text.split("\n", true):
		_script_lines.append(line)
	_line_index = 0
	_is_showing = true
	_is_typing = false
	_is_waiting_for_click = false
	_current_text_target = ""
	_typing_request_id += 1
	visible = true
	opening_still.texture = _default_background
	opening_still.visible = show_default_background
	_clear_images()
	name_label.text = ""
	name_label.visible = false
	text_label.text = ""
	next_label.visible = false
	layer = 100
	_run_script(request_id)


# ノベルスクリプト実行
func _run_script(request_id: int) -> void:
	while request_id == _script_request_id and _line_index < _script_lines.size():
		var source_line := _script_lines[_line_index]
		_line_index += 1
		var trimmed_line := source_line.strip_edges()
		if trimmed_line.is_empty():
			continue
		if trimmed_line.begins_with("@"):
			await _execute_command(trimmed_line, request_id)
		else:
			await _type_text(source_line, request_id)
		if not is_inside_tree():
			return
	if request_id == _script_request_id:
		_finish()


# テキスト表示
func _type_text(source_text: String, request_id: int) -> void:
	_typing_request_id += 1
	# typing要求ID
	var typing_request_id := _typing_request_id
	_current_text_target = text_label.text + source_text
	next_label.visible = false
	_is_typing = true
	# 文字間隔
	var type_interval := _get_text_interval()
	if type_interval <= 0.0:
		_complete_typing()
		return
	for character in source_text:
		if request_id != _script_request_id or typing_request_id != _typing_request_id:
			return
		text_label.text += character
		_play_character_se()
		await get_tree().create_timer(type_interval).timeout
	if request_id != _script_request_id or typing_request_id != _typing_request_id:
		return
	_complete_typing()


# completetyping処理
func _complete_typing() -> void:
	_typing_request_id += 1
	text_label.text = _current_text_target
	_is_typing = false


# コマンド実行
func _execute_command(command_line: String, request_id: int) -> void:
	var command := _parse_command(command_line)
	var command_name := String(command["name"])
	var argument := String(command["argument"])
	match command_name:
		"name":
			_command_name(argument)
		"bg":
			_command_bg(argument)
		"img":
			_command_img(argument)
		"img_remove":
			_command_img_remove(argument)
		"l":
			await _command_l(request_id)
		"r":
			_command_r()
		"cm":
			_command_cm()
		"lcm":
			await _command_lcm(request_id)
		_:
			push_error(
				"OpeningNovel found an unknown command '@%s' on scenario line %d."
				% [command_name, _line_index]
			)


# nameコマンド
func _command_name(character_name: String) -> void:
	name_label.text = character_name
	name_label.visible = not character_name.is_empty()


# bgコマンド
func _command_bg(background_path: String) -> void:
	if background_path.is_empty():
		opening_still.texture = null
		opening_still.visible = false
		return
	if not ResourceLoader.exists(background_path, "Texture2D"):
		push_error("OpeningNovel @bg could not find a Texture2D: %s" % background_path)
		return
	var background := load(background_path) as Texture2D
	if background == null:
		push_error("OpeningNovel @bg could not load a Texture2D: %s" % background_path)
		return
	opening_still.texture = background
	opening_still.visible = true


# imgコマンド
func _command_img(argument: String) -> void:
	var arguments := _parse_comma_separated_arguments(argument)
	if arguments.size() != 4:
		push_error(
			"OpeningNovel @img requires index, position_x, position_y, and path on scenario line %d."
			% _line_index
		)
		return
	if not arguments[0].is_valid_int() or not arguments[1].is_valid_float() or not arguments[2].is_valid_float():
		push_error("OpeningNovel @img received invalid index or position on scenario line %d." % _line_index)
		return
	var image_index := arguments[0].to_int()
	if image_index < 0:
		push_error("OpeningNovel @img requires a non-negative index on scenario line %d." % _line_index)
		return
	var image_path := arguments[3]
	if image_path.is_empty() or not ResourceLoader.exists(image_path, "Texture2D"):
		push_error("OpeningNovel @img could not find a Texture2D: %s" % image_path)
		return
	var texture := load(image_path) as Texture2D
	if texture == null:
		push_error("OpeningNovel @img could not load a Texture2D: %s" % image_path)
		return
	var image := _images.get(image_index) as TextureRect
	if image == null:
		image = TextureRect.new()
		image.name = "Image%d" % image_index
		image.self_modulate = Color("#f0e0ff")
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP
		image_layer.add_child(image)
		_images[image_index] = image
	image.texture = texture
	image.position = Vector2(arguments[1].to_float(), arguments[2].to_float())
	image.size = texture.get_size()
	_image_source_lines[image_index] = _line_index - 1
	_refresh_debug_images()


# img_removeコマンド
func _command_img_remove(argument: String) -> void:
	var image_index_text := argument.strip_edges()
	if not image_index_text.is_valid_int():
		push_error("OpeningNovel @img_remove requires an index on scenario line %d." % _line_index)
		return
	var image_index := image_index_text.to_int()
	if image_index < 0:
		push_error("OpeningNovel @img_remove requires a non-negative index on scenario line %d." % _line_index)
		return
	var image := _images.get(image_index) as TextureRect
	if image == null:
		return
	_images.erase(image_index)
	_image_source_lines.erase(image_index)
	image_layer.remove_child(image)
	image.queue_free()
	_refresh_debug_images()


func _parse_comma_separated_arguments(argument: String) -> Array[String]:
	var arguments: Array[String] = []
	for value in argument.split(",", true):
		var parsed_value := value.strip_edges()
		if parsed_value.length() >= 2 and parsed_value.begins_with("\"") and parsed_value.ends_with("\""):
			parsed_value = parsed_value.substr(1, parsed_value.length() - 2)
		arguments.append(parsed_value)
	return arguments


func _clear_images() -> void:
	for image: TextureRect in _images.values():
		image_layer.remove_child(image)
		image.queue_free()
	_images.clear()
	_image_source_lines.clear()
	_refresh_debug_images()


func _refresh_debug_images() -> void:
	if not is_node_ready():
		return
	debug_panel.set_images(_images)


func _on_debug_image_position_changed(image_index: int, position: Vector2) -> void:
	var image := _images.get(image_index) as TextureRect
	if image == null:
		_refresh_debug_images()
		return
	image.position = position
	debug_panel.set_selected_position(position)
	_save_image_position(image_index)


func _on_debug_drag_mode_changed(is_enabled: bool) -> void:
	if not is_enabled:
		if _is_debug_dragging:
			_save_image_position(debug_panel.get_selected_image_index())
		_is_debug_dragging = false


func _save_image_position(image_index: int) -> void:
	var image := _images.get(image_index) as TextureRect
	var source_line_index := int(_image_source_lines.get(image_index, -1))
	if image == null or source_line_index < 0 or source_line_index >= _script_lines.size():
		return
	if _active_novel_text == null or _active_novel_text.script_path.is_empty():
		return
	var command := _parse_command(_script_lines[source_line_index].strip_edges())
	var arguments := _parse_comma_separated_arguments(String(command["argument"]))
	if String(command["name"]) != "img" or arguments.size() != 4:
		push_error(
			"OpeningNovel could not update @img coordinates on scenario line %d."
			% (source_line_index + 1)
		)
		return
	_script_lines[source_line_index] = (
		"@img %d, %s, %s, \"%s\""
		% [image_index, _format_coordinate(image.position.x), _format_coordinate(image.position.y), arguments[3]]
	)
	var file := FileAccess.open(_active_novel_text.script_path, FileAccess.WRITE)
	if file == null:
		push_error(
			"OpeningNovel could not write debug coordinates to scenario text: %s (error %d)"
			% [_active_novel_text.script_path, FileAccess.get_open_error()]
		)
		return
	file.store_string("\n".join(_script_lines))


func _format_coordinate(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))
	return str(value)


# lコマンド
func _command_l(request_id: int) -> void:
	if request_id != _script_request_id or not _is_showing:
		return
	_is_waiting_for_click = true
	next_label.visible = true
	await click_wait_completed
	if request_id != _script_request_id:
		return
	_is_waiting_for_click = false
	next_label.visible = false


# rコマンド
func _command_r() -> void:
	_current_text_target = text_label.text + "\n"
	text_label.text = _current_text_target


# cmコマンド
func _command_cm() -> void:
	_typing_request_id += 1
	_is_typing = false
	_current_text_target = ""
	text_label.text = ""
	next_label.visible = false


# lcmコマンド
func _command_lcm(request_id: int) -> void:
	await _command_l(request_id)
	if request_id != _script_request_id:
		return
	_command_cm()


# コマンド解析
func _parse_command(command_line: String) -> Dictionary:
	var command_body := command_line.trim_prefix("@").strip_edges()
	var separator_index := -1
	for index in range(command_body.length()):
		if command_body[index] == " " or command_body[index] == "\t":
			separator_index = index
			break
	if separator_index < 0:
		return {"name": command_body, "argument": ""}
	var command_name := command_body.substr(0, separator_index)
	var argument := command_body.substr(separator_index + 1).strip_edges()
	if argument.length() >= 2 and argument.begins_with("\"") and argument.ends_with("\""):
		argument = argument.substr(1, argument.length() - 2)
	return {"name": command_name, "argument": argument}


func _play_character_se() -> void:
	if character_se.stream == null:
		return
	character_se.stop()
	character_se.play()


func _get_text_interval() -> float:
	var game_settings := get_node_or_null("/root/GameSettings")
	if game_settings != null and game_settings.has_method("get_text_interval"):
		return float(game_settings.call("get_text_interval"))
	push_error("OpeningNovel requires the GameSettings autoload to provide get_text_interval().")
	return DEFAULT_TEXT_INTERVAL


# 対象終了
func _finish() -> void:
	_script_request_id += 1
	_typing_request_id += 1
	_is_showing = false
	_is_typing = false
	_is_waiting_for_click = false
	next_label.visible = false
	visible = false
	opening_still.visible = false
	_clear_images()
	finished.emit()


# イベント処理
func _on_screen_gui_input(event: InputEvent) -> void:
	if bool(get_node("/root/DebugState").get("debug_enabled")) and debug_panel.is_drag_mode_enabled():
		_handle_debug_drag_input(event)
		return
	if event is InputEventMouseButton:
		# マウスイベント
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _is_typing:
				_complete_typing()
			elif _is_waiting_for_click:
				click_wait_completed.emit()
			advanced.emit()


func _handle_debug_drag_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			if not mouse_event.pressed and _is_debug_dragging:
				_save_image_position(debug_panel.get_selected_image_index())
			_is_debug_dragging = mouse_event.pressed
			screen.accept_event()
		return
	if event is InputEventMouseMotion and _is_debug_dragging:
		var image_index := debug_panel.get_selected_image_index()
		var image := _images.get(image_index) as TextureRect
		if image != null:
			image.position += (event as InputEventMouseMotion).relative
			debug_panel.set_selected_position(image.position)
		screen.accept_event()
