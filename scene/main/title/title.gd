extends Node2D

signal start_game
signal settings_requested
signal quit_requested
signal debug_novel_requested(novel_text: NovelTextInfo)

const NOVEL_DIRECTORY := "res://resource/novel"
const NOVEL_BUTTON_FONT_SIZE := 8
const DEBUG_NOVEL_AREA_DIRECTORIES := [
	"area_eramia",
	"area_gonsal",
	"area_felis",
	"area_nerix",
	"area_zaika",
	"area_mirune",
	"area_corotta",
]

@onready var debug_button: Button = $DebugButton
@onready var novel_debug_panel: PanelContainer = $NovelDebugPanel
@onready var novel_button_list: VBoxContainer = $NovelDebugPanel/Margin/Scroll/NovelButtonList


# 初期化
func _ready() -> void:
	debug_button.pressed.connect(_on_debug_button_pressed)
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)
	_build_novel_buttons()
	_apply_debug_state(DebugState.debug_enabled)


# ノベルボタン構築
func _build_novel_buttons() -> void:
	for child in novel_button_list.get_children():
		child.queue_free()
	var paths: Array[String] = []
	_collect_novel_paths(NOVEL_DIRECTORY, paths)
	paths.sort()
	var debug_paths: Array[String] = []
	for path in paths:
		if _is_debug_only_novel_path(path):
			debug_paths.append(path)
		else:
			_add_novel_button(path)
	if debug_paths.is_empty():
		return
	var separator := Label.new()
	separator.name = "DebugSeparator"
	separator.text = "Debug"
	separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	separator.add_theme_font_size_override("font_size", NOVEL_BUTTON_FONT_SIZE)
	novel_button_list.add_child(separator)
	for path in debug_paths:
		_add_novel_button(path)


# ノベルボタン追加
func _add_novel_button(path: String) -> void:
	var button := Button.new()
	button.text = path.trim_prefix(NOVEL_DIRECTORY + "/").trim_suffix(".txt")
	button.tooltip_text = path
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", NOVEL_BUTTON_FONT_SIZE)
	button.pressed.connect(_on_novel_button_pressed.bind(path))
	novel_button_list.add_child(button)


# Debug専用ノベル判定
func _is_debug_only_novel_path(path: String) -> bool:
	for directory_name in DEBUG_NOVEL_AREA_DIRECTORIES:
		if path.begins_with(NOVEL_DIRECTORY.path_join("area").path_join(directory_name) + "/"):
			return true
	return false


# ノベルパス収集
func _collect_novel_paths(directory_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("Title: ノベル一覧フォルダを開けません: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_novel_paths(child_path, paths)
		elif entry.ends_with(".txt"):
			paths.append(child_path)
		entry = directory.get_next()
	directory.list_dir_end()


# Debug押下
func _on_debug_button_pressed() -> void:
	DebugState.toggle_debug_enabled()


# Debug状態変更
func _on_debug_enabled_changed(is_enabled: bool) -> void:
	_apply_debug_state(is_enabled)


# Debug状態反映
func _apply_debug_state(is_enabled: bool) -> void:
	novel_debug_panel.visible = is_enabled
	debug_button.button_pressed = is_enabled


# ノベル押下
func _on_novel_button_pressed(script_path: String) -> void:
	if not DebugState.debug_enabled:
		return
	var novel_text := NovelTextInfo.new()
	novel_text.script_path = script_path
	debug_novel_requested.emit(novel_text)


# 押下処理
func _on_start_button_pressed() -> void:
	start_game.emit()


# 押下処理
func _on_continue_button_pressed() -> void:
	start_game.emit()


# 押下処理
func _on_settings_button_pressed() -> void:
	settings_requested.emit()


# 押下処理
func _on_quit_button_pressed() -> void:
	quit_requested.emit()
