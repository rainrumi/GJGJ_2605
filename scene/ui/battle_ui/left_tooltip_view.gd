class_name LeftTooltipView
extends Panel

@export var tooltip_title := ""
@export_multiline var note_text := ""
@export var note_visible := false

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)

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
	TooltipTextLayout.apply_to_panel(self, tooltip_label, _get_tooltip_text())


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
