class_name TooltipTextLayout
extends RefCounted

const MAX_LINE_CHARACTERS := 60
const MIN_TOOLTIP_WIDTH := 80.0
const TOOLTIP_PADDING := 8.0
const MIN_TOOLTIP_HEIGHT := 24.0


static func apply_to_panel(panel: Control, label: Label, text: String) -> void:
	var tooltip_text := get_wrapped_text(text)
	label.text = tooltip_text
	var label_width := get_label_width(label, tooltip_text)
	label.position = Vector2(TOOLTIP_PADDING, TOOLTIP_PADDING)
	var label_height := get_label_height(label, tooltip_text)
	label.size = Vector2(label_width, label_height)
	panel.size = Vector2(
		label_width + TOOLTIP_PADDING * 2.0,
		maxf(MIN_TOOLTIP_HEIGHT, label_height + TOOLTIP_PADDING * 2.0)
	)


static func get_wrapped_text(text: String) -> String:
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


static func get_label_width(label: Label, text: String) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var max_width := 0.0
	for line in text.split("\n"):
		var line_width := font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x
		max_width = maxf(max_width, line_width)
	return maxf(MIN_TOOLTIP_WIDTH - TOOLTIP_PADDING * 2.0, ceilf(max_width))


static func get_label_height(label: Label, text: String) -> float:
	var font := label.get_theme_font("font")
	var font_size := label.get_theme_font_size("font_size")
	var line_spacing := label.get_theme_constant("line_spacing")
	var line_count := maxi(1, text.split("\n").size())
	return ceilf(float(line_count) * font.get_height(font_size) + float(line_count - 1) * line_spacing)
