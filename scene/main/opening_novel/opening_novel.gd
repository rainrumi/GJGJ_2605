extends CanvasLayer

signal finished

@export var novel_text: NovelTextResource

@onready var screen: Control = $Screen
@onready var text_label: Label = $Screen/TextBox/TextLabel
@onready var next_label: Label = $Screen/TextBox/NextLabel

var _pages: Array[String] = []
var _page_index := 0
var _is_showing := false


func _ready() -> void:
	visible = false
	screen.gui_input.connect(_on_screen_gui_input)


func start() -> void:
	_pages = novel_text.get_pages() if novel_text != null else []
	_page_index = 0
	_is_showing = true
	visible = true
	layer = 100
	_show_current_page()


func _show_current_page() -> void:
	if _page_index >= _pages.size():
		_finish()
		return
	text_label.text = _pages[_page_index]
	next_label.visible = true


func _advance_page() -> void:
	if not _is_showing:
		return
	_page_index += 1
	_show_current_page()


func _finish() -> void:
	_is_showing = false
	visible = false
	finished.emit()


func _on_screen_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			_advance_page()
