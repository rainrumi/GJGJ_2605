class_name StageSelectTagFrame
extends Label

@export var min_width := 23.0
@export var text_padding_x := 2.0
@export var font_size := 7


# setuptag処理
func setup_tag(tag_name: String) -> void:
	text = "#%s" % tag_name
	# tag幅
	var tag_width := _get_tag_width(text)
	custom_minimum_size = Vector2(tag_width, custom_minimum_size.y)
	size = Vector2(tag_width, size.y)


# tag幅取得
func _get_tag_width(value: String) -> float:
	# ラベルフォント
	var label_font := get_theme_font("font")
	# ラベルフォントサイズ
	var label_font_size := get_theme_font_size("font_size")
	if label_font != null:
		return maxf(min_width, label_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label_font_size).x + text_padding_x)
	return maxf(min_width, float(value.length()) * font_size + text_padding_x)
