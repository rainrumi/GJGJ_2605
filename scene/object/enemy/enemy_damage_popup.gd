class_name EnemyDamagePopup
extends RefCounted

const FLOAT_DISTANCE := 8.0
const DURATION := 0.35
const HIDE_DELAY := 0.15


# ダメージ表示
static func show_damage(owner: Node, hp_label: Label, amount: int, color: Color) -> void:
	show_damage_values(owner, hp_label, [amount], color)


# ダメージvalues表示
static func show_damage_values(owner: Node, hp_label: Label, damage_values: Array, color: Color) -> void:
	if owner == null or hp_label == null:
		return
	# ダメージtexts
	var damage_texts: Array[String] = []
	for damage in damage_values:
		if damage > 0:
			damage_texts.append("-%d" % damage)
	if damage_texts.is_empty():
		return
	# ラベル
	var label := Label.new()
	label.text = "\n".join(damage_texts)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(hp_label.size.x, maxf(hp_label.size.y, float(damage_texts.size()) * hp_label.size.y))
	label.position = hp_label.position + Vector2(0.0, -label.size.y + hp_label.size.y * 0.3)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	_copy_font(hp_label, label)
	owner.add_child(label)
	# トゥイーン
	var tween := owner.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_DISTANCE, DURATION)
	tween.tween_property(label, "modulate:a", 1.0, DURATION)
	tween.chain().tween_interval(HIDE_DELAY)
	tween.chain().tween_property(label, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(label.queue_free)


# copyフォント処理
static func _copy_font(source: Label, target: Label) -> void:
	# フォント
	var font := source.get_theme_font("font")
	if font != null:
		target.add_theme_font_override("font", font)
	target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
