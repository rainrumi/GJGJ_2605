class_name OpeningNovel
extends CanvasLayer

signal finished
signal advanced
signal click_wait_completed

const DEFAULT_TEXT_INTERVAL := 0.04

@export var novel_text: NovelTextInfo

@onready var screen: Control = $Screen
@onready var opening_still: TextureRect = $Screen/OpeningStill
@onready var name_label: Label = $Screen/TextBox/NameLabel
@onready var text_label: Label = $Screen/TextBox/TextLabel
@onready var next_label: Label = $Screen/TextBox/NextLabel
@onready var character_se: AudioStreamPlayer = $CharacterSe

var _script_lines: Array[String] = []
var _line_index := 0
var _is_showing := false
var _is_typing := false
var _is_waiting_for_click := false
var _current_text_target := ""
var _typing_request_id := 0
var _script_request_id := 0
var _default_background: Texture2D


# 初期化
func _ready() -> void:
	_default_background = opening_still.texture
	visible = false
	screen.gui_input.connect(_on_screen_gui_input)


# 対象開始
func start() -> void:
	_start_script(novel_text, true)


# with文言開始
func start_with_text(next_novel_text: NovelTextInfo) -> void:
	_start_script(next_novel_text, false)


# ノベルスクリプト開始
func _start_script(next_novel_text: NovelTextInfo, show_default_background: bool) -> void:
	_script_request_id += 1
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
		"l":
			await _command_l(request_id)
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
	finished.emit()


# イベント処理
func _on_screen_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# マウスイベント
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			if _is_typing:
				_complete_typing()
			elif _is_waiting_for_click:
				click_wait_completed.emit()
			advanced.emit()
