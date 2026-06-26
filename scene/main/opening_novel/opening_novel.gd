class_name OpeningNovel
extends CanvasLayer

signal finished

@export var novel_text: NovelTextInfo

@onready var screen: Control = $Screen
@onready var opening_still: TextureRect = $Screen/OpeningStill
@onready var text_label: Label = $Screen/TextBox/TextLabel
@onready var next_label: Label = $Screen/TextBox/NextLabel

var _pages: Array[String] = []
var _page_index := 0
var _is_showing := false
var _is_typing := false
var _current_page_text := ""
var _typing_request_id := 0


# 初期化
func _ready() -> void:
	visible = false
	screen.gui_input.connect(_on_screen_gui_input)


# 対象開始
func start() -> void:
	_pages = novel_text.get_pages() if novel_text != null else []
	_page_index = 0
	_is_showing = true
	visible = true
	opening_still.visible = true
	layer = 100
	_show_current_page()


# with文言開始
func start_with_text(next_novel_text: NovelTextInfo) -> void:
	_pages = next_novel_text.get_pages() if next_novel_text != null else []
	_page_index = 0
	_is_showing = true
	visible = true
	opening_still.visible = false
	layer = 100
	_show_current_page()


# ページ表示
func _show_current_page() -> void:
	if _page_index >= _pages.size():
		_finish()
		return
	_start_typing(_pages[_page_index])


# typing開始
func _start_typing(page_text: String) -> void:
	_typing_request_id += 1
	# 要求ID
	var request_id := _typing_request_id
	_current_page_text = page_text
	text_label.text = ""
	next_label.visible = false
	_is_typing = true
	# type間隔
	var type_interval := GameSettings.get_text_interval()
	if type_interval <= 0.0:
		_complete_typing()
		return
	for i in range(page_text.length()):
		if request_id != _typing_request_id:
			return
		text_label.text += page_text[i]
		await get_tree().create_timer(type_interval).timeout
	if request_id != _typing_request_id:
		return
	_complete_typing()


# completetyping処理
func _complete_typing() -> void:
	_typing_request_id += 1
	text_label.text = _current_page_text
	next_label.visible = true
	_is_typing = false


# advanceページ処理
func _advance_page() -> void:
	if not _is_showing:
		return
	if _is_typing:
		_complete_typing()
		return
	_page_index += 1
	_show_current_page()


# 対象終了
func _finish() -> void:
	_is_showing = false
	visible = false
	opening_still.visible = false
	finished.emit()


# イベント処理
func _on_screen_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		# マウスイベント
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_advance_page()
