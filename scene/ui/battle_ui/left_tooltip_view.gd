class_name LeftTooltipView
extends Panel

@export var tooltip_title := ""
@export_multiline var note_text := ""
@export var note_visible := false

const ENTRY_TITLE_HEIGHT := 36.0
const ENTRY_VALUE_HEIGHT := 34.0
const ENTRY_VALUE_LINE_HEIGHT := 30.0
const ENTRY_BLOCK_GAP := 26.0

@onready var title_label: Label = $Content/TitleLabel
@onready var entry_container: Control = $Content/EntryContainer
@onready var note_slice: Label = $Content/NoteSlice
@onready var note_label: Label = $Content/NoteLabel


func _ready() -> void:
	set_title(tooltip_title)
	set_note(note_text, note_visible)


func show_tooltip() -> void:
	visible = true


func hide_tooltip() -> void:
	visible = false


func set_title(text: String) -> void:
	title_label.text = text


func set_entries(entries: Array) -> void:
	for child in entry_container.get_children():
		child.free()
	var y := 0.0
	for entry in entries:
		var explanation := ""
		var value := ""
		if entry is Dictionary:
			explanation = str(entry.get("explanation", ""))
			value = str(entry.get("value", ""))
		_add_entry_label(explanation, y, 26, Color.WHITE)
		y += ENTRY_TITLE_HEIGHT
		var value_height := maxf(ENTRY_VALUE_HEIGHT, float(value.count("\n") + 1) * ENTRY_VALUE_LINE_HEIGHT)
		_add_entry_label(value, y, 20, Color(0.94, 0.88, 1.0, 1.0), value_height)
		y += value_height + ENTRY_BLOCK_GAP


func set_note(text: String, is_visible: bool) -> void:
	if not text.is_empty():
		note_label.text = text
	note_label.visible = is_visible
	note_slice.visible = is_visible


func _add_entry_label(text: String, y: float, font_size: int, font_color: Color, height: float = ENTRY_TITLE_HEIGHT) -> void:
	var label := Label.new()
	label.text = text
	label.layout_mode = 0
	label.offset_top = y
	label.offset_right = entry_container.size.x
	label.offset_bottom = y + height
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_override("font", title_label.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", font_size)
	entry_container.add_child(label)
