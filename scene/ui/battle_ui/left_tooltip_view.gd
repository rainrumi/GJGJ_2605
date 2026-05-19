class_name LeftTooltipView
extends Panel

@export var tooltip_title := ""
@export_multiline var note_text := ""
@export var note_visible := false

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)
const MAX_LINE_CHARACTERS := 35
const MIN_TOOLTIP_WIDTH := 80.0
const TOOLTIP_PADDING := 8.0
const MIN_TOOLTIP_HEIGHT := 24.0

@onready var tooltip_label: Label = $TooltipLabel

var _entries: Array = []
var _note_text := ""
var _note_visible := false


func _ready() -> void:
	_note_text = note_text
	_note_visible = note_visible
	_apply_text()


func show_tooltip() -> void:
	visible = true


func show_tooltip_at(anchor_global_position: Vector2) -> void:
	_apply_text()
	global_position = TooltipPositioner.get_tooltip_position(
		anchor_global_position,
		size,
		get_viewport().get_visible_rect(),
		TOOLTIP_OFFSET
	)
	visible = true


func hide_tooltip() -> void:
	visible = false


func set_title(text: String) -> void:
	tooltip_title = text
	_apply_text()


func set_entries(entries: Array) -> void:
	_entries = entries.duplicate()
	_apply_text()


func set_note(text: String, is_visible: bool) -> void:
	if not text.is_empty():
		_note_text = text
	_note_visible = is_visible
	_apply_text()


func _apply_text() -> void:
	if not is_node_ready():
		return
	var tooltip_text := _get_wrapped_text(_get_tooltip_text())
	tooltip_label.text = tooltip_text
	var label_width := _get_label_width(tooltip_text)
	tooltip_label.position = Vector2(TOOLTIP_PADDING, TOOLTIP_PADDING)
	var label_height := _get_label_height(tooltip_text)
	tooltip_label.size = Vector2(label_width, label_height)
	size = Vector2(label_width + TOOLTIP_PADDING * 2.0, maxf(MIN_TOOLTIP_HEIGHT, label_height + TOOLTIP_PADDING * 2.0))


func _get_tooltip_text() -> String:
	var lines: Array[String] = []
	if not tooltip_title.is_empty():
		lines.append(tooltip_title)
	for entry in _entries:
		if not (entry is Dictionary):
			continue
		var explanation := str(entry.get("explanation", ""))
		var value := str(entry.get("value", ""))
		if explanation.is_empty():
			lines.append(value)
		elif value.is_empty():
			lines.append(explanation)
		else:
			lines.append("%s: %s" % [explanation, value])
	if _note_visible and not _note_text.is_empty():
		if not lines.is_empty():
			lines.append("")
		lines.append(_note_text)
	return "\n".join(lines)


func _get_label_width(text: String) -> float:
	var font := tooltip_label.get_theme_font("font")
	var font_size := tooltip_label.get_theme_font_size("font_size")
	var max_width := 0.0
	for line in text.split("\n"):
		max_width = maxf(max_width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	return maxf(MIN_TOOLTIP_WIDTH - TOOLTIP_PADDING * 2.0, ceilf(max_width))


func _get_label_height(text: String) -> float:
	var font := tooltip_label.get_theme_font("font")
	var font_size := tooltip_label.get_theme_font_size("font_size")
	var line_spacing := tooltip_label.get_theme_constant("line_spacing")
	var line_count := maxi(1, text.split("\n").size())
	return ceilf(float(line_count) * font.get_height(font_size) + float(line_count - 1) * line_spacing)


func _get_wrapped_text(text: String) -> String:
	var wrapped_lines: Array[String] = []
	for line in text.split("\n"):
		if line.is_empty():
			wrapped_lines.append("")
			continue
		var start := 0
		while start < line.length():
			wrapped_lines.append(line.substr(start, MAX_LINE_CHARACTERS))
			start += MAX_LINE_CHARACTERS
	return "\n".join(wrapped_lines)
