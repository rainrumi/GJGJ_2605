class_name BattleUI
extends CanvasLayer

signal digestion_requested

const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const TIME_PULSE_SCALE := 1.1
const TIME_PULSE_DURATION := 0.2
const HP_GAUGE_TWEEN_DURATION := 0.2
const TIME_ELAPSED_FLOAT_DISTANCE := 10.0
const TIME_ELAPSED_TWEEN_DURATION := 0.3
const TIME_ELAPSED_HIDE_DELAY := 0.2

@onready var passive_guide_text: Label = $PassiveGuideFrame/PassiveGuideText
@onready var hp_frame: NinePatchRect = $HpFrame
@onready var hp_gauge: NinePatchRect = $HpFrame/HpGauge
@onready var hp_text: Label = $HpFrame/HpText
@onready var time_bar: TextureRect = $TimeBar
@onready var time_text: Label = $TimeBar/TimeText
@onready var digestion_frame: TextureRect = $DigestionFrame
@onready var digestion_label: Label = $DigestionFrame/DigestionLabel
@onready var message_text: Label = $StatusPanel/MessageText
@onready var debug_message_button: Button = $StatusPanel/DebugMessageButton

var _hp_gauge_full_width := 0.0
var _hp_gauge_tween: Tween
var _digestion_button_base_scale := Vector2.ONE
var _digestion_button_tween: Tween
var _time_text_base_scale := Vector2.ONE
var _time_text_pulse_tween: Tween
var _time_elapsed_label: Label
var _time_elapsed_label_base_position := Vector2.ZERO
var _time_elapsed_tween: Tween
var _hp_damage_preview_label: Label
var _debug_message := ""


func _ready() -> void:
	_prepare_mouse_filters()
	_prepare_debug_message_button()
	_prepare_digestion_button()
	_capture_sizes()
	_create_hp_damage_preview()
	_create_time_elapsed_label()


func reset_for_battle(max_hp: int, minutes: int, message: String) -> void:
	set_hp(max_hp, max_hp)
	set_time(minutes)
	set_message(message)
	set_debug_message("")
	set_digestion_count(0)
	set_digestion_button_visible(true)
	hide_hp_damage_preview()
	hide_time_elapsed()


func set_hp(current_hp: int, max_hp: int) -> void:
	hp_text.text = "%d/%d" % [maxi(0, current_hp), max_hp]
	var hp_ratio := clampf(float(maxi(0, current_hp)) / float(max_hp), 0.0, 1.0)
	var target_size := Vector2(_hp_gauge_full_width * hp_ratio, hp_gauge.size.y)
	if _hp_gauge_tween != null and _hp_gauge_tween.is_valid():
		_hp_gauge_tween.kill()
	if hp_ratio > 0.0:
		hp_gauge.visible = true
	_hp_gauge_tween = create_tween()
	_hp_gauge_tween.set_trans(Tween.TRANS_QUAD)
	_hp_gauge_tween.set_ease(Tween.EASE_OUT)
	_hp_gauge_tween.tween_property(hp_gauge, "size", target_size, HP_GAUGE_TWEEN_DURATION)
	if hp_ratio == 0.0:
		_hp_gauge_tween.tween_callback(func() -> void: hp_gauge.visible = false)


func set_time(minutes: int) -> void:
	var hour := int(minutes / 60) % 24
	var minute := minutes % 60
	time_text.text = "%02d:%02d" % [hour, minute]


func set_message(message: String) -> void:
	message_text.text = message


func set_debug_message(message: String) -> void:
	_debug_message = message


func set_digestion_count(count: int) -> void:
	if count > 0:
		digestion_label.text = "消化開始！ x%d" % count
		return
	digestion_label.text = "消化開始！"


func set_digestion_button_visible(is_visible: bool) -> void:
	digestion_frame.visible = is_visible
	if not is_visible:
		digestion_frame.scale = _digestion_button_base_scale


func is_digestion_button_hit(mouse_position: Vector2) -> bool:
	if not digestion_frame.visible:
		return false
	return digestion_frame.get_global_rect().has_point(mouse_position)


func show_time_elapsed(amount_minutes: int) -> void:
	if _time_elapsed_tween != null and _time_elapsed_tween.is_valid():
		_time_elapsed_tween.kill()
	_time_elapsed_label.text = _format_elapsed_time(amount_minutes)
	_time_elapsed_label.position = _time_elapsed_label_base_position
	_time_elapsed_label.modulate.a = 0.0
	_time_elapsed_label.visible = true
	_time_elapsed_tween = create_tween()
	_time_elapsed_tween.set_parallel(true)
	_time_elapsed_tween.set_trans(Tween.TRANS_QUART)
	_time_elapsed_tween.set_ease(Tween.EASE_OUT)
	_time_elapsed_tween.tween_property(_time_elapsed_label, "modulate:a", 1.0, TIME_ELAPSED_TWEEN_DURATION)
	_time_elapsed_tween.tween_property(
		_time_elapsed_label,
		"position:y",
		_time_elapsed_label_base_position.y - TIME_ELAPSED_FLOAT_DISTANCE,
		TIME_ELAPSED_TWEEN_DURATION
	)
	_time_elapsed_tween.chain().tween_interval(TIME_ELAPSED_HIDE_DELAY)
	_time_elapsed_tween.chain().tween_callback(hide_time_elapsed)
	_pulse_time_text()


func hide_time_elapsed() -> void:
	if _time_elapsed_tween != null and _time_elapsed_tween.is_valid():
		_time_elapsed_tween.kill()
	_time_elapsed_label.visible = false
	_time_elapsed_label.position = _time_elapsed_label_base_position
	_time_elapsed_label.modulate.a = 0.0


func show_hp_damage_preview(amount: int) -> void:
	_hp_damage_preview_label.text = "-%d" % amount
	_hp_damage_preview_label.position = hp_frame.position + Vector2(hp_frame.size.x - 42.0, -16.0)
	_hp_damage_preview_label.visible = true


func hide_hp_damage_preview() -> void:
	_hp_damage_preview_label.visible = false


func _prepare_mouse_filters() -> void:
	passive_guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_message_button.mouse_filter = Control.MOUSE_FILTER_STOP
	digestion_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digestion_frame.mouse_filter = Control.MOUSE_FILTER_STOP


func _prepare_debug_message_button() -> void:
	debug_message_button.pressed.connect(_on_debug_message_button_pressed)


func _prepare_digestion_button() -> void:
	_digestion_button_base_scale = digestion_frame.scale
	digestion_frame.pivot_offset = digestion_frame.size * 0.5
	digestion_frame.gui_input.connect(_on_digestion_frame_gui_input)
	digestion_frame.mouse_entered.connect(_on_digestion_frame_mouse_entered)
	digestion_frame.mouse_exited.connect(_on_digestion_frame_mouse_exited)


func _capture_sizes() -> void:
	_hp_gauge_full_width = hp_gauge.size.x
	_time_text_base_scale = time_text.scale
	time_text.pivot_offset = time_text.size * 0.5


func _create_hp_damage_preview() -> void:
	_hp_damage_preview_label = Label.new()
	_hp_damage_preview_label.name = "RemoveNightmareDamagePreview"
	_hp_damage_preview_label.visible = false
	_hp_damage_preview_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hp_damage_preview_label.add_theme_color_override("font_color", Color.html("#ff0736"))
	_hp_damage_preview_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_hp_damage_preview_label.add_theme_constant_override("outline_size", 3)
	var preview_font := hp_text.get_theme_font("font")
	if preview_font != null:
		_hp_damage_preview_label.add_theme_font_override("font", preview_font)
	_hp_damage_preview_label.add_theme_font_size_override("font_size", 28)
	add_child(_hp_damage_preview_label)


func _create_time_elapsed_label() -> void:
	_time_elapsed_label = Label.new()
	_time_elapsed_label.name = "TimeElapsedLabel"
	_time_elapsed_label.visible = false
	_time_elapsed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_elapsed_label.size = Vector2(104.0, 36.0)
	_time_elapsed_label_base_position = time_bar.position + Vector2(-110.0, 42.0)
	_time_elapsed_label.position = _time_elapsed_label_base_position
	_time_elapsed_label.modulate.a = 0.0
	_time_elapsed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_elapsed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_elapsed_label.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0, 1.0))
	_time_elapsed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_time_elapsed_label.add_theme_constant_override("outline_size", 4)
	var elapsed_font := time_text.get_theme_font("font")
	if elapsed_font != null:
		_time_elapsed_label.add_theme_font_override("font", elapsed_font)
	_time_elapsed_label.add_theme_font_size_override("font_size", 28)
	add_child(_time_elapsed_label)


func _pulse_time_text() -> void:
	if _time_text_pulse_tween != null and _time_text_pulse_tween.is_valid():
		_time_text_pulse_tween.kill()
	time_text.scale = _time_text_base_scale
	_time_text_pulse_tween = create_tween()
	_time_text_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_time_text_pulse_tween.set_ease(Tween.EASE_OUT)
	_time_text_pulse_tween.tween_property(time_text, "scale", _time_text_base_scale * TIME_PULSE_SCALE, TIME_PULSE_DURATION * 0.5)
	_time_text_pulse_tween.tween_property(time_text, "scale", _time_text_base_scale, TIME_PULSE_DURATION * 0.5)


func _format_elapsed_time(amount_minutes: int) -> String:
	var hours := int(amount_minutes / 60)
	var minutes_only := amount_minutes % 60
	if hours == 0:
		return "+%02dm" % minutes_only
	if minutes_only == 0:
		return "+%dh" % hours
	return "+%dh%02dm" % [hours, minutes_only]


func _on_debug_message_button_pressed() -> void:
	if _debug_message == "":
		return
	message_text.text = _debug_message


func _on_digestion_frame_gui_input(event: InputEvent) -> void:
	if not digestion_frame.visible:
		return
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			digestion_requested.emit()


func _on_digestion_frame_mouse_entered() -> void:
	_set_digestion_button_hovered(true)


func _on_digestion_frame_mouse_exited() -> void:
	_set_digestion_button_hovered(false)


func _set_digestion_button_hovered(is_hovered: bool) -> void:
	if _digestion_button_tween != null and _digestion_button_tween.is_valid():
		_digestion_button_tween.kill()
	var target_scale := _digestion_button_base_scale
	if is_hovered:
		target_scale *= HOVER_SCALE
	_digestion_button_tween = create_tween()
	_digestion_button_tween.set_trans(Tween.TRANS_QUAD)
	_digestion_button_tween.set_ease(Tween.EASE_OUT)
	_digestion_button_tween.tween_property(digestion_frame, "scale", target_scale, HOVER_TWEEN_DURATION)
