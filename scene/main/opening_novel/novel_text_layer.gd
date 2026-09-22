class_name NovelTextLayer
extends Control

var _characters: Array[String] = []
var _character_bounds: Array[Rect2] = []
var _font: Font
var _font_size := 16
var _font_color := Color.WHITE
var _font_outline_color := Color.BLACK
var _outline_size := 0
var _visible_character_count := 0


func rebuild_from_label(reference_label: Label, text: String) -> void:
	_font = reference_label.get_theme_font("font")
	_font_size = reference_label.get_theme_font_size("font_size")
	_font_color = reference_label.get_theme_color("font_color")
	_font_outline_color = reference_label.get_theme_color("font_outline_color")
	_outline_size = reference_label.get_theme_constant("outline_size")
	_characters.clear()
	_character_bounds.clear()
	for index in text.length():
		_characters.append(text[index])
		_character_bounds.append(reference_label.get_character_bounds(index))
	_visible_character_count = 0
	queue_redraw()


func clear_text() -> void:
	_characters.clear()
	_character_bounds.clear()
	_visible_character_count = 0
	queue_redraw()


func set_visible_characters(value: int) -> void:
	_visible_character_count = clampi(value, 0, _characters.size()) if value >= 0 else _characters.size()
	queue_redraw()


func get_visible_characters() -> int:
	return -1 if _visible_character_count >= _characters.size() else _visible_character_count


func _draw() -> void:
	if _font == null:
		return
	var baseline_offset := _font.get_ascent(_font_size)
	for index in _visible_character_count:
		var character := _characters[index]
		if character == "\n" or character == "\r":
			continue
		var bounds := _character_bounds[index]
		var baseline := Vector2(bounds.position.x, bounds.position.y + baseline_offset)
		if _outline_size > 0 and _font_outline_color.a > 0.0:
			draw_string_outline(
				_font,
				baseline,
				character,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1.0,
				_font_size,
				_outline_size,
				_font_outline_color,
			)
		draw_string(
			_font,
			baseline,
			character,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1.0,
			_font_size,
			_font_color,
		)
