class_name DreamSeedSkillTooltipView
extends Panel

const MAX_LINE_CHARACTERS := 35
const MIN_TOOLTIP_WIDTH := 80.0
const TOOLTIP_PADDING := 8.0
const MIN_TOOLTIP_HEIGHT := 24.0

@onready var tooltip_label: Label = $TooltipLabel

var _pending_text := ""


func _ready() -> void:
	_apply_text()


func set_text(text: String) -> void:
	_pending_text = text
	if not is_node_ready():
		return
	_apply_text()


func _apply_text() -> void:
	tooltip_label.text = _pending_text
	var label_width := _get_label_width(_pending_text)
	tooltip_label.position = Vector2(TOOLTIP_PADDING, TOOLTIP_PADDING)
	tooltip_label.size = Vector2(label_width, 0.0)
	var label_height := tooltip_label.get_combined_minimum_size().y
	tooltip_label.size = Vector2(label_width, label_height)
	size = Vector2(label_width + TOOLTIP_PADDING * 2.0, maxf(MIN_TOOLTIP_HEIGHT, label_height + TOOLTIP_PADDING * 2.0))


func _get_label_width(text: String) -> float:
	var font := tooltip_label.get_theme_font("font")
	var font_size := tooltip_label.get_theme_font_size("font_size")
	var max_width := 0.0
	for line in text.split("\n"):
		var measured_text := line.substr(0, mini(line.length(), MAX_LINE_CHARACTERS))
		max_width = maxf(max_width, font.get_string_size(measured_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x)
	return maxf(MIN_TOOLTIP_WIDTH - TOOLTIP_PADDING * 2.0, ceilf(max_width))
