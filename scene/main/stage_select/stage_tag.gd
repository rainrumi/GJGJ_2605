class_name StageSelectTagFrame
extends NinePatchRect

@export var min_width := 58.0
@export var text_padding_x := 20.0
@export var font_size := 18

@onready var name_label: Label = $Name


func setup_tag(tag_name: String) -> void:
	name_label.text = tag_name
	custom_minimum_size = Vector2(
		maxf(min_width, float(tag_name.length()) * font_size + text_padding_x),
		custom_minimum_size.y
	)
