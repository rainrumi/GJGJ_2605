class_name HpTextView
extends Label


# 初期化
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# 重なり順設定
func set_draw_order(order: int) -> void:
	z_index = order


# HP文字設定
func set_hp_values(current_hp: int, max_hp: int, planned_recovery: int = 0) -> void:
	if planned_recovery > 0:
		text = "%d(+%d)/%d" % [current_hp, planned_recovery, max_hp]
		return
	text = "%d/%d" % [current_hp, max_hp]


# ダメージラベル作成
func create_damage_value_label(damage_texts: Array[String]) -> Label:
	# 表示ラベル
	var label := Label.new()
	label.text = "\n".join(damage_texts)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(46.0, maxf(18.0, float(damage_texts.size()) * 15.0))
	label.position = position + Vector2((size.x - label.size.x) * 0.5, -label.size.y + 2.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	apply_damage_label_style(label, 14, Color.WHITE)
	return label


# 回復ラベル作成
func create_heal_value_label(amount: int) -> Label:
	# 表示ラベル
	var label := Label.new()
	label.text = "+%d" % amount
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(46.0, 18.0)
	label.position = position + Vector2((size.x - label.size.x) * 0.5, -label.size.y + 2.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	apply_heal_label_style(label)
	return label


# ダメージ装飾
func apply_damage_label_style(label: Label, font_size: int, outline_color: Color) -> void:
	label.add_theme_color_override("font_color", Color.html("#ff0736"))
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 2)
	# 使用フォント
	var damage_font := get_theme_font("font")
	if damage_font != null:
		label.add_theme_font_override("font", damage_font)
	label.add_theme_font_size_override("font_size", font_size)


# 回復装飾
func apply_heal_label_style(label: Label) -> void:
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 2)
	# 使用フォント
	var heal_font := get_theme_font("font")
	if heal_font != null:
		label.add_theme_font_override("font", heal_font)
	label.add_theme_font_size_override("font_size", 14)
