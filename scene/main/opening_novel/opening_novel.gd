class_name OpeningNovel
extends CanvasLayer

signal finished
signal advanced
signal click_wait_completed

const DEFAULT_TEXT_INTERVAL := 0.04

@export var novel_text: NovelTextInfo
@export var novel_layer := 100

@onready var screen: Control = $Screen
@onready var opening_still: TextureRect = $Screen/OpeningStill
@onready var image_layer: Control = $Screen/ImageLayer
@onready var text_box: Panel = $Screen/TextBox
@onready var textbox_layer: Control = $Screen/TextBoxLayer
@onready var name_label: Label = $Screen/TextBox/NameLabel
@onready var text_label: Label = $Screen/TextBox/TextLabel
@onready var text_layer: NovelTextLayer = $Screen/TextBox/TextLayer
@onready var next_label: Label = $Screen/TextBox/NextLabel
@onready var character_se: AudioStreamPlayer = $CharacterSe
@onready var _web_audio: WebAudioFallbackService = get_node("/root/WebAudioFallback") as WebAudioFallbackService
@onready var debug_panel: NovelDebugPanel = $Screen/DebugPanel
@onready var debug_textbox_outline: Panel = $Screen/DebugTextBoxOutline
@onready var debug_textbox_resize_handle: ColorRect = $Screen/DebugTextBoxOutline/ResizeHandle

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
var _saved_images: Dictionary[int, TextureRect] = {}
var _textboxes: Dictionary[int, Label] = {}
var _saved_textboxes: Dictionary[int, Label] = {}
var _textbox_source_lines: Dictionary[int, int] = {}
var _image_source_lines: Dictionary[int, int] = {}
var _active_novel_text: NovelTextInfo
var _is_debug_dragging := false
var _is_debug_resizing_textbox := false
var _script_load_failed := false


# 初期化
func _ready() -> void:
	_default_background = opening_still.texture
	visible = false
	_set_input_blocked(false)
	screen.gui_input.connect(_on_screen_gui_input)
	debug_panel.image_position_changed.connect(_on_debug_image_position_changed)
	debug_panel.textbox_geometry_changed.connect(_on_debug_textbox_geometry_changed)
	debug_panel.target_selection_changed.connect(_update_debug_textbox_outline)
	debug_panel.drag_mode_changed.connect(_on_debug_drag_mode_changed)
	var debug_state := get_node("/root/DebugState")
	debug_state.connect("debug_enabled_changed", _on_debug_enabled_changed)
	var outline_style := StyleBoxFlat.new()
	outline_style.bg_color = Color(1.0, 0.85, 0.2, 0.0)
	outline_style.border_color = Color(1.0, 0.85, 0.2, 1.0)
	outline_style.set_border_width_all(2)
	debug_textbox_outline.add_theme_stylebox_override("panel", outline_style)
	_refresh_debug_targets()
	debug_textbox_outline.visible = false


# 対象開始
func start() -> void:
	_start_script(novel_text, true)


# with文言開始
func start_with_text(next_novel_text: NovelTextInfo) -> void:
	_start_script(next_novel_text, false)


# ノベルスクリプト開始
func _start_script(next_novel_text: NovelTextInfo, show_default_background: bool) -> void:
	_set_input_blocked(true)
	_script_request_id += 1
	_active_novel_text = next_novel_text
	_script_load_failed = false
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
	text_box.visible = true
	opening_still.texture = _default_background
	opening_still.visible = show_default_background
	_clear_images()
	_image_source_lines.clear()
	_clear_textboxes()
	_textbox_source_lines.clear()
	name_label.text = ""
	name_label.visible = false
	text_label.text = ""
	text_layer.clear_text()
	next_label.visible = false
	layer = novel_layer
	if script_text.strip_edges().is_empty():
		_script_load_failed = true
		var source_path := next_novel_text.script_path if next_novel_text != null else "<null>"
		_set_text_layout("ノベルデータの読み込みに失敗しました。\n%s" % source_path, -1)
		push_error("OpeningNovel refused to skip an unreadable scenario: %s" % source_path)
		return
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
func _set_text_layout(target_text: String, visible_character_count: int) -> void:
	text_label.text = target_text
	text_label.visible_characters = -1
	text_layer.rebuild_from_label(text_label, target_text)
	text_layer.set_visible_characters(visible_character_count)


func _type_text(source_text: String, request_id: int) -> void:
	_typing_request_id += 1
	# typing要求ID
	var typing_request_id := _typing_request_id
	var previous_text := text_label.text
	var previous_visible_characters := text_layer.get_visible_characters()
	if previous_visible_characters < 0:
		previous_visible_characters = previous_text.length()
	_current_text_target = previous_text + source_text
	_set_text_layout(_current_text_target, previous_visible_characters)
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
		text_layer.set_visible_characters(text_layer.get_visible_characters() + 1)
		_play_character_se()
		await get_tree().create_timer(type_interval).timeout
	if request_id != _script_request_id or typing_request_id != _typing_request_id:
		return
	_complete_typing()


# completetyping処理
func _complete_typing() -> void:
	_typing_request_id += 1
	text_label.text = _current_text_target
	text_layer.set_visible_characters(-1)
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
			_command_img(argument, false)
		"img_save":
			_command_img(argument, true)
		"img_remove":
			_command_img_remove(argument)
		"img_save_reset":
			_command_img_save_reset(argument)
		"textbox_set":
			_command_textbox_set(argument, false)
		"textbox_save_set":
			_command_textbox_set(argument, true)
		"textbox_clear":
			_command_textbox_clear(argument, false)
		"textbox_save_clear":
			_command_textbox_clear(argument, true)
		"text":
			_command_text(argument, false)
		"text_save":
			_command_text(argument, true)
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
	name_label.text = _parse_single_argument(character_name)
	name_label.visible = not name_label.text.is_empty()


# bgコマンド
func _command_bg(background_path: String) -> void:
	background_path = _parse_single_argument(background_path)
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
func _command_img(argument: String, is_saved: bool) -> void:
	var command_name := "img_save" if is_saved else "img"
	var arguments := _parse_comma_separated_arguments(argument)
	if arguments.size() != 4:
		push_error(
			"OpeningNovel @%s requires index, position_x, position_y, and path on scenario line %d."
			% [command_name, _line_index]
		)
		return
	if not arguments[0].is_valid_int() or not arguments[1].is_valid_float() or not arguments[2].is_valid_float():
		push_error("OpeningNovel @%s received invalid index or position on scenario line %d." % [command_name, _line_index])
		return
	var image_index := arguments[0].to_int()
	if image_index < 0:
		push_error("OpeningNovel @%s requires a non-negative index on scenario line %d." % [command_name, _line_index])
		return
	var image_path := arguments[3]
	if image_path.is_empty() or not ResourceLoader.exists(image_path, "Texture2D"):
		push_error("OpeningNovel @%s could not find a Texture2D: %s" % [command_name, image_path])
		return
	var texture := load(image_path) as Texture2D
	if texture == null:
		push_error("OpeningNovel @%s could not load a Texture2D: %s" % [command_name, image_path])
		return
	var image_collection := _saved_images if is_saved else _images
	var debug_image_index := _debug_image_index(image_index, is_saved)
	var image := image_collection.get(image_index) as TextureRect
	if image == null:
		image = TextureRect.new()
		image.name = ("SavedImage%d" if is_saved else "Image%d") % image_index
		image.self_modulate = Color("#f0e0ff")
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP
		image_layer.add_child(image)
		image_collection[image_index] = image
	image.texture = texture
	image.position = Vector2(arguments[1].to_float(), arguments[2].to_float())
	image.size = texture.get_size()
	_image_source_lines[debug_image_index] = _line_index - 1
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


func _command_img_save_reset(argument: String) -> void:
	var image_index_text := argument.strip_edges()
	if not image_index_text.is_valid_int():
		push_error("OpeningNovel @img_save_reset requires an index on scenario line %d." % _line_index)
		return
	var image_index := image_index_text.to_int()
	if image_index < 0:
		push_error("OpeningNovel @img_save_reset requires a non-negative index on scenario line %d." % _line_index)
		return
	var image := _saved_images.get(image_index) as TextureRect
	if image == null:
		return
	_saved_images.erase(image_index)
	_image_source_lines.erase(_debug_image_index(image_index, true))
	image_layer.remove_child(image)
	image.queue_free()
	_refresh_debug_images()


func _command_textbox_set(argument: String, is_saved: bool) -> void:
	var command_name := "textbox_save_set" if is_saved else "textbox_set"
	var arguments := _parse_comma_separated_arguments(argument)
	if arguments.size() != 7:
		push_error(
			"OpeningNovel @%s requires index, position_x, position_y, size_x, size_y, horizontal_alignment, and vertical_alignment on scenario line %d."
			% [command_name, _line_index]
		)
		return
	if not arguments[0].is_valid_int():
		push_error("OpeningNovel @%s received an invalid index on scenario line %d." % [command_name, _line_index])
		return
	if arguments[0].to_int() < 0:
		push_error("OpeningNovel @%s requires a non-negative index on scenario line %d." % [command_name, _line_index])
		return
	for index in range(1, 5):
		if not arguments[index].is_valid_float():
			push_error("OpeningNovel @%s received an invalid coordinate or size on scenario line %d." % [command_name, _line_index])
			return
	for index in range(5, 7):
		if not arguments[index].is_valid_int() or arguments[index].to_int() < 0 or arguments[index].to_int() > 3:
			push_error("OpeningNovel @%s received an invalid alignment on scenario line %d." % [command_name, _line_index])
			return
	var textbox_size := Vector2(arguments[3].to_float(), arguments[4].to_float())
	if textbox_size.x < 0.0 or textbox_size.y < 0.0:
		push_error("OpeningNovel @%s requires non-negative sizes on scenario line %d." % [command_name, _line_index])
		return
	var textbox_index := arguments[0].to_int()
	var textbox_collection := _saved_textboxes if is_saved else _textboxes
	var debug_textbox_index := _debug_textbox_index(textbox_index, is_saved)
	var textbox := textbox_collection.get(textbox_index) as Label
	if textbox == null:
		textbox = Label.new()
		textbox.name = ("SavedTextBox%d" if is_saved else "TextBox%d") % textbox_index
		textbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		textbox.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textbox.add_theme_font_override("font", text_label.get_theme_font("font"))
		textbox.add_theme_font_size_override("font_size", text_label.get_theme_font_size("font_size"))
		textbox.add_theme_color_override("font_color", text_label.get_theme_color("font_color"))
		textbox.add_theme_color_override("font_outline_color", text_label.get_theme_color("font_outline_color"))
		textbox.add_theme_constant_override("outline_size", text_label.get_theme_constant("outline_size"))
		textbox_layer.add_child(textbox)
		textbox_collection[textbox_index] = textbox
	_textbox_source_lines[debug_textbox_index] = _line_index - 1
	textbox.position = Vector2(arguments[1].to_float(), arguments[2].to_float())
	textbox.size = textbox_size
	textbox.horizontal_alignment = arguments[5].to_int()
	textbox.vertical_alignment = arguments[6].to_int()
	_refresh_debug_targets()


func _command_textbox_clear(argument: String, is_saved: bool) -> void:
	var command_name := "textbox_save_clear" if is_saved else "textbox_clear"
	var textbox_index_text := argument.strip_edges().trim_prefix("\"").trim_suffix("\"")
	if not textbox_index_text.is_valid_int():
		push_error("OpeningNovel @%s requires an index on scenario line %d." % [command_name, _line_index])
		return
	var textbox_index := textbox_index_text.to_int()
	var textbox_collection := _saved_textboxes if is_saved else _textboxes
	var debug_textbox_index := _debug_textbox_index(textbox_index, is_saved)
	var textbox := textbox_collection.get(textbox_index) as Label
	if textbox == null:
		return
	textbox_collection.erase(textbox_index)
	_textbox_source_lines.erase(debug_textbox_index)
	textbox_layer.remove_child(textbox)
	textbox.queue_free()
	_refresh_debug_targets()


func _command_text(argument: String, is_saved: bool) -> void:
	var command_name := "text_save" if is_saved else "text"
	var arguments := _parse_comma_separated_arguments(argument)
	if arguments.size() != 2 or not arguments[0].is_valid_int():
		push_error("OpeningNovel @%s requires an index and text on scenario line %d." % [command_name, _line_index])
		return
	var textbox_collection := _saved_textboxes if is_saved else _textboxes
	var textbox := textbox_collection.get(arguments[0].to_int()) as Label
	if textbox == null:
		return
	textbox.text = arguments[1]


func _parse_comma_separated_arguments(argument: String) -> Array[String]:
	var arguments: Array[String] = []
	var current_value := ""
	var inside_quotes := false
	var index := 0
	while index < argument.length():
		var character := argument[index]
		if character == "\"":
			if inside_quotes and index + 1 < argument.length() and argument[index + 1] == "\"":
				current_value += "\""
				index += 1
			else:
				inside_quotes = not inside_quotes
		elif character == "," and not inside_quotes:
			arguments.append(current_value.strip_edges())
			current_value = ""
		else:
			current_value += character
		index += 1
	arguments.append(current_value.strip_edges())
	return arguments


func _parse_single_argument(argument: String) -> String:
	var arguments := _parse_comma_separated_arguments(argument)
	return arguments[0] if arguments.size() == 1 else argument.strip_edges()


func _clear_textboxes() -> void:
	for textbox: Label in _textboxes.values():
		textbox_layer.remove_child(textbox)
		textbox.queue_free()
	_textboxes.clear()
	for textbox_index: int in _textbox_source_lines.keys():
		if textbox_index >= 0:
			_textbox_source_lines.erase(textbox_index)
	_refresh_debug_targets()


func _clear_images() -> void:
	for image: TextureRect in _images.values():
		image_layer.remove_child(image)
		image.queue_free()
	_images.clear()
	for image_index: int in _image_source_lines.keys():
		if image_index >= 0:
			_image_source_lines.erase(image_index)
	_refresh_debug_images()


func _refresh_debug_images() -> void:
	_refresh_debug_targets()


func _refresh_debug_targets() -> void:
	if not is_node_ready():
		return
	debug_panel.set_targets(_get_debug_images(), _get_debug_textboxes())
	_update_debug_textbox_outline()


func _on_debug_image_position_changed(image_index: int, position: Vector2) -> void:
	var image := _get_debug_images().get(image_index) as TextureRect
	if image == null:
		_refresh_debug_images()
		return
	image.position = position
	debug_panel.set_selected_position(position)
	_save_image_position(image_index)
	_update_debug_textbox_outline()


func _on_debug_textbox_geometry_changed(textbox_index: int, position: Vector2, size: Vector2) -> void:
	var textbox := _get_debug_textboxes().get(textbox_index) as Label
	if textbox == null:
		_refresh_debug_targets()
		return
	textbox.position = position
	textbox.size = size
	debug_panel.set_selected_geometry(position, size)
	_update_debug_textbox_outline()
	_save_textbox_geometry(textbox_index)


func _update_debug_textbox_outline() -> void:
	if not is_node_ready():
		return
	var textbox: Label
	if debug_panel.get_selected_kind() == "textbox":
		textbox = _get_debug_textboxes().get(debug_panel.get_selected_textbox_index()) as Label
	var debug_enabled := bool(get_node("/root/DebugState").get("debug_enabled"))
	debug_textbox_outline.visible = debug_enabled and textbox != null
	if textbox == null:
		return
	debug_textbox_outline.position = textbox.position
	debug_textbox_outline.size = textbox.size
	debug_textbox_resize_handle.position = textbox.size - debug_textbox_resize_handle.size


func _on_debug_enabled_changed(_is_enabled: bool) -> void:
	_update_debug_textbox_outline()


func _on_debug_drag_mode_changed(is_enabled: bool) -> void:
	if not is_enabled:
		if _is_debug_dragging:
			_save_active_debug_target()
		_is_debug_dragging = false
		_is_debug_resizing_textbox = false
	_update_debug_textbox_outline()


func _save_image_position(image_index: int) -> void:
	var image := _get_debug_images().get(image_index) as TextureRect
	var source_line_index := int(_image_source_lines.get(image_index, -1))
	if image == null or source_line_index < 0 or source_line_index >= _script_lines.size():
		return
	if _active_novel_text == null or _active_novel_text.script_path.is_empty():
		return
	var command := _parse_command(_script_lines[source_line_index].strip_edges())
	var arguments := _parse_comma_separated_arguments(String(command["argument"]))
	var is_saved_image := image_index < 0
	var expected_command_name := "img_save" if is_saved_image else "img"
	var expected_index := _script_image_index(image_index)
	if (
		String(command["name"]) != expected_command_name
		or arguments.size() != 4
		or not arguments[0].is_valid_int()
		or arguments[0].to_int() != expected_index
	):
		push_error(
			"OpeningNovel could not update @%s coordinates on scenario line %d."
			% [expected_command_name, source_line_index + 1]
		)
		return
	_script_lines[source_line_index] = _replace_command_arguments(
		_script_lines[source_line_index],
		{
			1: _format_coordinate(image.position.x),
			2: _format_coordinate(image.position.y),
		}
	)
	_write_debug_script_changes()


func _save_textbox_geometry(textbox_index: int) -> void:
	var textbox := _get_debug_textboxes().get(textbox_index) as Label
	var source_line_index := int(_textbox_source_lines.get(textbox_index, -1))
	if textbox == null or source_line_index < 0 or source_line_index >= _script_lines.size():
		return
	if _active_novel_text == null or _active_novel_text.script_path.is_empty():
		return
	var command := _parse_command(_script_lines[source_line_index].strip_edges())
	var arguments := _parse_comma_separated_arguments(String(command["argument"]))
	var is_saved_textbox := textbox_index < 0
	var expected_command_name := "textbox_save_set" if is_saved_textbox else "textbox_set"
	var expected_index := _script_textbox_index(textbox_index)
	if (
		String(command["name"]) != expected_command_name
		or arguments.size() != 7
		or not arguments[0].is_valid_int()
		or arguments[0].to_int() != expected_index
	):
		push_error(
			"OpeningNovel could not update @%s geometry on scenario line %d."
			% [expected_command_name, source_line_index + 1]
		)
		return
	_script_lines[source_line_index] = _replace_command_arguments(
		_script_lines[source_line_index],
		{
			1: _format_coordinate(textbox.position.x),
			2: _format_coordinate(textbox.position.y),
			3: _format_coordinate(textbox.size.x),
			4: _format_coordinate(textbox.size.y),
		}
	)
	_write_debug_script_changes()


func _replace_command_arguments(source_line: String, replacements: Dictionary) -> String:
	var command_start := 0
	while command_start < source_line.length() and (
		source_line[command_start] == " "
		or source_line[command_start] == "\t"
		or source_line[command_start] == "\r"
	):
		command_start += 1
	if command_start >= source_line.length() or source_line[command_start] != "@":
		return source_line
	var command_end := -1
	for index in range(command_start + 1, source_line.length()):
		if source_line[index] == " " or source_line[index] == "\t":
			command_end = index
			break
	if command_end < 0:
		return source_line
	var argument_start := command_end
	while argument_start < source_line.length() and (
		source_line[argument_start] == " " or source_line[argument_start] == "\t"
	):
		argument_start += 1

	var argument_ranges: Array[Vector2i] = []
	var token_start := argument_start
	var inside_quotes := false
	var index := argument_start
	while index <= source_line.length():
		if index == source_line.length() or (source_line[index] == "," and not inside_quotes):
			var token_end := index
			while token_start < token_end and (
				source_line[token_start] == " "
				or source_line[token_start] == "\t"
				or source_line[token_start] == "\r"
			):
				token_start += 1
			while token_end > token_start and (
				source_line[token_end - 1] == " "
				or source_line[token_end - 1] == "\t"
				or source_line[token_end - 1] == "\r"
			):
				token_end -= 1
			argument_ranges.append(Vector2i(token_start, token_end))
			token_start = index + 1
		elif source_line[index] == "\"":
			if inside_quotes and index + 1 < source_line.length() and source_line[index + 1] == "\"":
				index += 1
			else:
				inside_quotes = not inside_quotes
		index += 1

	var replacement_indices: Array = replacements.keys()
	replacement_indices.sort()
	replacement_indices.reverse()
	var updated_line := source_line
	for argument_index: int in replacement_indices:
		if argument_index < 0 or argument_index >= argument_ranges.size():
			continue
		var token_range := argument_ranges[argument_index]
		updated_line = (
			updated_line.substr(0, token_range.x)
			+ String(replacements[argument_index])
			+ updated_line.substr(token_range.y)
		)
	return updated_line


func _write_debug_script_changes() -> void:
	var file := FileAccess.open(_active_novel_text.script_path, FileAccess.WRITE)
	if file == null:
		push_error(
			"OpeningNovel could not write debug geometry to scenario text: %s (error %d)"
			% [_active_novel_text.script_path, FileAccess.get_open_error()]
		)
		return
	file.store_string("\n".join(_script_lines))


func _save_active_debug_target() -> void:
	if debug_panel.get_selected_kind() == "textbox":
		_save_textbox_geometry(debug_panel.get_selected_textbox_index())
	else:
		_save_image_position(debug_panel.get_selected_image_index())


func _format_coordinate(value: float) -> String:
	var rounded_value := roundf(value * 10.0) / 10.0
	if is_equal_approx(rounded_value, roundf(rounded_value)):
		return str(int(roundf(rounded_value)))
	return "%.1f" % rounded_value


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
	_set_text_layout(_current_text_target, -1)


# cmコマンド
func _command_cm() -> void:
	_typing_request_id += 1
	_is_typing = false
	_current_text_target = ""
	text_label.text = ""
	text_layer.clear_text()
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
	return {"name": command_name, "argument": argument}


func _play_character_se() -> void:
	if character_se.stream == null:
		return
	if _web_audio.play_se(character_se.stream, &"opening_character"):
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
	_clear_textboxes()
	if not _saved_images.is_empty() or not _saved_textboxes.is_empty():
		text_box.visible = false
		visible = true
	_set_input_blocked(false)
	finished.emit()


func _set_input_blocked(is_blocked: bool) -> void:
	screen.mouse_filter = Control.MOUSE_FILTER_STOP if is_blocked else Control.MOUSE_FILTER_IGNORE


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
			if mouse_event.pressed:
				if debug_panel.get_selected_kind() == "textbox":
					var textbox := _get_debug_textboxes().get(debug_panel.get_selected_textbox_index()) as Label
					if textbox == null:
						_is_debug_dragging = false
						return
					var point := mouse_event.position
					var resize_area := Rect2(
						textbox.position + textbox.size - Vector2(18.0, 18.0), Vector2(36.0, 36.0)
					)
					_is_debug_resizing_textbox = resize_area.has_point(point)
					_is_debug_dragging = Rect2(textbox.position, textbox.size).has_point(point)
				else:
					_is_debug_dragging = true
			else:
				if _is_debug_dragging:
					_save_active_debug_target()
				_is_debug_dragging = false
				_is_debug_resizing_textbox = false
			screen.accept_event()
		return
	if event is InputEventMouseMotion and _is_debug_dragging:
		if debug_panel.get_selected_kind() == "textbox":
			var textbox_index := debug_panel.get_selected_textbox_index()
			var textbox := _get_debug_textboxes().get(textbox_index) as Label
			if textbox == null:
				return
			var delta := (event as InputEventMouseMotion).relative
			if _is_debug_resizing_textbox:
				textbox.size = Vector2(
					maxf(1.0, _round_debug_coordinate(textbox.size.x + delta.x)),
					maxf(1.0, _round_debug_coordinate(textbox.size.y + delta.y))
				)
			else:
				textbox.position = _round_debug_position(textbox.position + delta)
			debug_panel.set_selected_geometry(textbox.position, textbox.size)
			_update_debug_textbox_outline()
			screen.accept_event()
			return
		var image_index := debug_panel.get_selected_image_index()
		var image := _get_debug_images().get(image_index) as TextureRect
		if image != null:
			image.position = _round_debug_position(image.position + (event as InputEventMouseMotion).relative)
			debug_panel.set_selected_position(image.position)
			_update_debug_textbox_outline()
		screen.accept_event()


func _round_debug_position(position: Vector2) -> Vector2:
	return Vector2(_round_debug_coordinate(position.x), _round_debug_coordinate(position.y))


func _round_debug_coordinate(value: float) -> float:
	return roundf(value * 10.0) / 10.0


func _get_debug_images() -> Dictionary[int, TextureRect]:
	var images: Dictionary[int, TextureRect] = {}
	for image_index: int in _images:
		images[image_index] = _images[image_index]
	for image_index: int in _saved_images:
		images[_debug_image_index(image_index, true)] = _saved_images[image_index]
	return images


func _get_debug_textboxes() -> Dictionary[int, Label]:
	var textboxes: Dictionary[int, Label] = {}
	for textbox_index: int in _textboxes:
		textboxes[textbox_index] = _textboxes[textbox_index]
	for textbox_index: int in _saved_textboxes:
		textboxes[_debug_textbox_index(textbox_index, true)] = _saved_textboxes[textbox_index]
	return textboxes


func _debug_image_index(image_index: int, is_saved: bool) -> int:
	return -image_index - 1 if is_saved else image_index


func _script_image_index(debug_image_index: int) -> int:
	return -debug_image_index - 1 if debug_image_index < 0 else debug_image_index


func _debug_textbox_index(textbox_index: int, is_saved: bool) -> int:
	return -textbox_index - 1 if is_saved else textbox_index


func _script_textbox_index(debug_textbox_index: int) -> int:
	return -debug_textbox_index - 1 if debug_textbox_index < 0 else debug_textbox_index
