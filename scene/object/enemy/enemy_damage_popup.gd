class_name EnemyDamagePopup
extends RefCounted

const FLOAT_DISTANCE := 8.0
const DURATION := 0.35
const HIDE_DELAY := 0.15
const POPUP_META := &"enemy_damage_popup"
const POPUP_FRAME_META := &"enemy_damage_popup_frame"


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
	var popup_frame := Engine.get_process_frames()
	_clear_previous_popups(owner, popup_frame)
	# ラベル
	var label := Label.new()
	label.text = "\n".join(damage_texts)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(hp_label.size.x, maxf(hp_label.size.y, float(damage_texts.size()) * hp_label.size.y))
	label.position = _get_popup_position(owner, hp_label, label.size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	_copy_font(hp_label, label)
	label.set_meta(POPUP_META, true)
	label.set_meta(POPUP_FRAME_META, popup_frame)
	owner.add_child(label)
	# トゥイーン
	var tween := label.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - FLOAT_DISTANCE, DURATION)
	tween.tween_property(label, "modulate:a", 1.0, DURATION)
	tween.chain().tween_interval(HIDE_DELAY)
	tween.chain().tween_property(label, "modulate:a", 0.0, DURATION)
	tween.chain().tween_callback(label.queue_free)


# 前回の被弾表示を終了し、同一フレームの表示だけを残す
static func _clear_previous_popups(owner: Node, popup_frame: int) -> void:
	for child in owner.get_children():
		if not child is Label or not child.get_meta(POPUP_META, false):
			continue
		if int(child.get_meta(POPUP_FRAME_META, -1)) == popup_frame:
			continue
		child.visible = false
		child.queue_free()


# 表示中の被弾値と重ならない位置を取得
static func _get_popup_position(owner: Node, hp_label: Label, popup_size: Vector2) -> Vector2:
	var position := hp_label.position + Vector2(0.0, -popup_size.y + hp_label.size.y * 0.3)
	for child in owner.get_children():
		if not child is Label or not child.get_meta(POPUP_META, false):
			continue
		var active_popup := child as Label
		if active_popup.is_queued_for_deletion():
			continue
		position.y = minf(position.y, active_popup.position.y - popup_size.y)
	return position


# copyフォント処理
static func _copy_font(source: Label, target: Label) -> void:
	# フォント
	var font := source.get_theme_font("font")
	if font != null:
		target.add_theme_font_override("font", font)
	target.add_theme_font_size_override("font_size", source.get_theme_font_size("font_size"))
