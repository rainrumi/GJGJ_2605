class_name StageSelectTagFrame
extends NinePatchRect

@export var min_width := 58.0
@export var text_padding_x := 20.0
@export var font_size := 18

@onready var name_label: Label = $Name


func setup_tag(tag_name: String) -> void:
	name_label.text = tag_name
	var tag_width := _get_tag_width(tag_name)
	custom_minimum_size = Vector2(tag_width, custom_minimum_size.y)
	size = Vector2(tag_width, size.y)


func _get_tag_width(tag_name: String) -> float:
	var label_font := name_label.get_theme_font("font")
	var label_font_size := name_label.get_theme_font_size("font_size")
	if label_font != null:
		return maxf(min_width, label_font.get_string_size(tag_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size).x + text_padding_x)
	return maxf(min_width, float(tag_name.length()) * font_size + text_padding_x)
