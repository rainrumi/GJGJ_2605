class_name HpView
extends NinePatchRect

const HP_GAUGE_TWEEN_DURATION := 0.2
const HP_DAMAGE_FLOAT_DISTANCE := 16.0
const HP_DAMAGE_TWEEN_DURATION := 0.35
const HP_DAMAGE_HIDE_DELAY := 0.15

@onready var hp_gauge: NinePatchRect = $HpGauge
@onready var hp_heal_plan: NinePatchRect = $HpHealPlan
@onready var hp_text: Label = $HpText

var _current_hp := 0
var _max_hp := 1
var _planned_recovery_rate := 0.0
var _hp_gauge_full_width := 0.0
var _hp_gauge_tween: Tween
var _hp_damage_preview_label: Label


func _ready() -> void:
	_prepare_mouse_filters()
	_capture_sizes()
	_create_hp_damage_preview()
	_update_hp_heal_plan()


func set_hp(current_hp: int, max_hp: int, animated: bool = true) -> void:
	_max_hp = maxi(1, max_hp)
	_current_hp = clampi(current_hp, 0, _max_hp)
	hp_text.text = "%d/%d" % [_current_hp, _max_hp]
	var hp_ratio := clampf(float(_current_hp) / float(_max_hp), 0.0, 1.0)
	var target_size := Vector2(_hp_gauge_full_width * hp_ratio, hp_gauge.size.y)
	if _hp_gauge_tween != null and _hp_gauge_tween.is_valid():
		_hp_gauge_tween.kill()
	if _current_hp > 0:
		hp_gauge.visible = true
	if not animated:
		hp_gauge.size = target_size
		if _current_hp == 0:
			hp_gauge.visible = false
		_update_hp_heal_plan()
		return
	_hp_gauge_tween = create_tween()
	_hp_gauge_tween.set_trans(Tween.TRANS_QUAD)
	_hp_gauge_tween.set_ease(Tween.EASE_OUT)
	_hp_gauge_tween.tween_property(hp_gauge, "size", target_size, HP_GAUGE_TWEEN_DURATION)
	_hp_gauge_tween.tween_callback(Callable(self, "_update_hp_heal_plan"))
	if _current_hp == 0:
		_hp_gauge_tween.tween_callback(func() -> void: hp_gauge.visible = false)


func set_planned_recovery_rate(recovery_rate: float) -> void:
	_planned_recovery_rate = maxf(0.0, recovery_rate)
	_update_hp_heal_plan()


func show_damage_preview(amount: int) -> void:
	_hp_damage_preview_label.text = "-%d" % amount
	_hp_damage_preview_label.position = position + Vector2(size.x - 42.0, -16.0)
	_hp_damage_preview_label.visible = true


func hide_damage_preview() -> void:
	_hp_damage_preview_label.visible = false


func show_damage_values(damage_values: Array[int]) -> void:
	var damage_texts: Array[String] = []
	for damage in damage_values:
		if damage > 0:
			damage_texts.append("-%d" % damage)
	if damage_texts.is_empty():
		return
	var label := _create_damage_value_label(damage_texts)
	get_parent().add_child(label)
	_play_damage_value_tween(label)


func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_heal_plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _capture_sizes() -> void:
	_hp_gauge_full_width = hp_gauge.size.x


func _create_hp_damage_preview() -> void:
	_hp_damage_preview_label = Label.new()
	_hp_damage_preview_label.name = "RemoveNightmareDamagePreview"
	_hp_damage_preview_label.visible = false
	_hp_damage_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_damage_label_style(_hp_damage_preview_label, 28, Color.BLACK)
	get_parent().add_child(_hp_damage_preview_label)


func _create_damage_value_label(damage_texts: Array[String]) -> Label:
	var label := Label.new()
	label.text = "\n".join(damage_texts)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(92.0, maxf(36.0, float(damage_texts.size()) * 30.0))
	label.position = position + hp_text.position + Vector2((hp_text.size.x - label.size.x) * 0.5, -label.size.y + 4.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	_apply_damage_label_style(label, 28, Color.WHITE)
	return label


func _apply_damage_label_style(label: Label, font_size: int, outline_color: Color) -> void:
	label.add_theme_color_override("font_color", Color.html("#ff0736"))
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 3)
	var damage_font := hp_text.get_theme_font("font")
	if damage_font != null:
		label.add_theme_font_override("font", damage_font)
	label.add_theme_font_size_override("font_size", font_size)


func _play_damage_value_tween(label: Label) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - HP_DAMAGE_FLOAT_DISTANCE, HP_DAMAGE_TWEEN_DURATION)
	tween.tween_property(label, "modulate:a", 1.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_interval(HP_DAMAGE_HIDE_DELAY)
	tween.chain().tween_property(label, "modulate:a", 0.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_callback(label.queue_free)


func _update_hp_heal_plan() -> void:
	var current_ratio := clampf(float(_current_hp) / float(_max_hp), 0.0, 1.0)
	var target_hp := mini(_max_hp, _current_hp + ceili(float(_max_hp) * _planned_recovery_rate))
	var target_ratio := clampf(float(target_hp) / float(_max_hp), 0.0, 1.0)
	var current_width := _hp_gauge_full_width * current_ratio
	var target_width := _hp_gauge_full_width * target_ratio
	var plan_width := maxf(0.0, target_width - current_width)
	hp_heal_plan.visible = plan_width > 0.0
	hp_heal_plan.position = hp_gauge.position + Vector2(current_width, 0.0)
	hp_heal_plan.size = Vector2(plan_width, hp_gauge.size.y)
	hp_heal_plan.z_index = hp_gauge.z_index + 1
	hp_text.z_index = hp_heal_plan.z_index + 1
