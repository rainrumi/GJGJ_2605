class_name LeftTooltipView
extends Panel

@export var tooltip_title := ""
@export_multiline var note_text := ""
@export var note_visible := false

@onready var title_label: Label = $Content/TitleLabel
@onready var entry_container: VBoxContainer = $Content/EntryContainer
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
	for entry in entries:
		var explanation := ""
		var value := ""
		if entry is Dictionary:
			explanation = str(entry.get("explanation", ""))
			value = str(entry.get("value", ""))
		_add_entry_block(explanation, value)


func set_note(text: String, is_visible: bool) -> void:
	if not text.is_empty():
		note_label.text = text
	note_label.visible = is_visible
	note_slice.visible = is_visible


func _add_entry_block(explanation: String, value: String) -> void:
	var block := VBoxContainer.new()
	block.mouse_filter = Control.MOUSE_FILTER_IGNORE
	block.add_theme_constant_override("separation", 5)
	entry_container.add_child(block)
	block.add_child(_create_entry_label(explanation, 26, Color.WHITE))
	block.add_child(_create_entry_label(value, 20, Color(0.94, 0.88, 1.0, 1.0)))


func _create_entry_label(text: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.add_theme_font_override("font", title_label.get_theme_font("font"))
	label.add_theme_font_size_override("font_size", font_size)
	return label
