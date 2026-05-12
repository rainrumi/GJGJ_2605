class_name BattleUI
extends CanvasLayer
signal digestion_requested
signal debug_message_requested(is_active: bool)
signal debug_reroll_requested
const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const TIME_PULSE_SCALE := 1.1
const TIME_PULSE_DURATION := 0.2
const HP_GAUGE_TWEEN_DURATION := 0.2
const HP_DAMAGE_FLOAT_DISTANCE := 16.0
const HP_DAMAGE_TWEEN_DURATION := 0.35
const HP_DAMAGE_HIDE_DELAY := 0.15
const TIME_ELAPSED_FLOAT_DISTANCE := 10.0
const TIME_ELAPSED_TWEEN_DURATION := 0.3
const TIME_ELAPSED_HIDE_DELAY := 0.2
const DEBUG_BUTTON_NORMAL_FONT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_FONT_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const DEBUG_BUTTON_ACTIVE_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const DEBUG_BUTTON_ACTIVE_HOVER_COLOR := Color(0.88, 0.88, 0.88, 1.0)
const DEBUG_BUTTON_ACTIVE_PRESSED_COLOR := Color(0.76, 0.76, 0.76, 1.0)
const TOOLTIP_TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const TOOLTIP_SUB_TEXT_COLOR := Color(0.94, 0.88, 1.0, 1.0)
@onready var passive_guide_text: Label = $PassiveGuideFrame/PassiveGuideText
@onready var passive_guide_frame: TextureRect = $PassiveGuideFrame
@onready var hp_frame: NinePatchRect = $HpFrame
@onready var hp_gauge: NinePatchRect = $HpFrame/HpGauge
@onready var hp_text: Label = $HpFrame/HpText
@onready var time_bar: TextureRect = $TimeBar
@onready var time_text: Label = $TimeBar/TimeText
@onready var digestion_frame: TextureRect = $DigestionFrame
@onready var digestion_label: Label = $DigestionFrame/DigestionLabel
@onready var digest_damage_value: Label = $PassiveGuideFrame/DigestDamageValue
@onready var digest_damage_detail: Label = $PassiveGuideFrame/DigestDamageDetail
@onready var status_panel: Control = $StatusPanel
@onready var message_text: Label = $StatusPanel/MessageText
@onready var debug_reroll_button: Button = $StatusPanel/DebugRerollButton
@onready var debug_message_button: Button = $StatusPanel/DebugMessageButton
@onready var nightmare_tooltip: NightmareTooltipView = $NightmareTooltipPanel
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
var _digest_damage_tooltip: Panel
var _digest_tooltip_base_value_label: Label
var _digest_tooltip_seed_value_label: Label
var _digest_tooltip_nightmare_value_label: Label
var _digest_tooltip_total_value_label: Label
var _debug_message := ""
var _debug_button_active := false
func _ready() -> void:
	_prepare_mouse_filters()
	_prepare_debug_message_button()
	_prepare_digestion_button()
	_configure_digest_damage_labels()
	_capture_sizes()
	_create_hp_damage_preview()
	_create_time_elapsed_label()
	_create_digest_damage_tooltip()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if not key_event.pressed or key_event.echo:
			return
		if key_event.keycode == KEY_D:
			_on_debug_message_button_pressed()
		if key_event.keycode == KEY_R and _debug_button_active:
			debug_reroll_requested.emit()
func reset_for_battle(max_hp: int, minutes: int, message: String) -> void:
	set_hp(max_hp, max_hp)
	set_time(minutes)
	set_digest_damage_info(0, 0, 0, 0.0, 0, 0.0)
	set_message(message)
	set_debug_message("")
	set_debug_button_active(false)
	set_digestion_count(0)
	set_digestion_button_visible(true)
	hide_hp_damage_preview()
	hide_time_elapsed()
	hide_nightmare_tooltip()
	hide_digest_damage_tooltip()
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
func show_nightmare_tooltip(enemy: Enemy, debug_number_text: String, debug_numbers_visible: bool) -> void:
	hide_digest_damage_tooltip()
	nightmare_tooltip.show_enemy(enemy, debug_number_text, debug_numbers_visible)
func hide_nightmare_tooltip() -> void:
	nightmare_tooltip.hide_tooltip()
func show_digest_damage_tooltip() -> void:
	if _digest_damage_tooltip == null:
		return
	hide_nightmare_tooltip()
	_digest_damage_tooltip.visible = true
func hide_digest_damage_tooltip() -> void:
	if _digest_damage_tooltip != null:
		_digest_damage_tooltip.visible = false
func set_digest_damage_info(total_damage: int, base_damage: int, seed_buff: int, seed_rate: float, nightmare_buff: int, nightmare_rate: float) -> void:
	passive_guide_text.text = "消化ダメージ"
	digest_damage_value.text = "%d" % total_damage
	digest_damage_detail.visible = false
	if _digest_damage_tooltip == null:
		return
	var total_buff_rate := _get_total_buff_rate(seed_rate, nightmare_rate)
	_digest_tooltip_total_value_label.text = "%d（総合バフ %s）" % [total_damage, _format_buff_rate(total_buff_rate)]
	_digest_tooltip_base_value_label.text = "%d" % base_damage
	_digest_tooltip_seed_value_label.text = "%s（%s）" % [_format_buff_amount(seed_buff), _format_buff_rate(seed_rate)]
	_digest_tooltip_nightmare_value_label.text = "%s（%s）" % [_format_buff_amount(nightmare_buff), _format_buff_rate(nightmare_rate)]
func _configure_digest_damage_labels() -> void:
	passive_guide_text.position = Vector2(26.0, 10.0)
	passive_guide_text.size = Vector2(158.0, 30.0)
	passive_guide_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	passive_guide_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	passive_guide_text.add_theme_font_size_override("font_size", 24)
	digest_damage_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	digest_damage_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	digest_damage_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	digest_damage_detail.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	digest_damage_detail.visible = false
func set_debug_button_active(is_active: bool) -> void:
	_debug_button_active = is_active
	if is_active:
		debug_reroll_button.visible = true
		debug_message_button.add_theme_color_override("font_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_message_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_message_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_ACTIVE_FONT_COLOR)
		debug_message_button.add_theme_stylebox_override("normal", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		debug_message_button.add_theme_stylebox_override("hover", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_HOVER_COLOR))
		debug_message_button.add_theme_stylebox_override("pressed", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_PRESSED_COLOR))
		debug_message_button.add_theme_stylebox_override("focus", _create_debug_button_style(DEBUG_BUTTON_ACTIVE_COLOR))
		return
	debug_reroll_button.visible = false
	debug_message_button.add_theme_color_override("font_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_hover_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.add_theme_color_override("font_pressed_color", DEBUG_BUTTON_NORMAL_FONT_COLOR)
	debug_message_button.remove_theme_stylebox_override("normal")
	debug_message_button.remove_theme_stylebox_override("hover")
	debug_message_button.remove_theme_stylebox_override("pressed")
	debug_message_button.remove_theme_stylebox_override("focus")
func _create_debug_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.0, 0.0, 0.0, 1.0)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_border_width(side, 2)
	for corner in [CORNER_TOP_LEFT, CORNER_TOP_RIGHT, CORNER_BOTTOM_RIGHT, CORNER_BOTTOM_LEFT]:
		style.set_corner_radius(corner, 2)
	return style
func _format_buff_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return "-%d" % absi(amount)
func _format_buff_rate(rate: float) -> String:
	var percent := roundi(rate * 100.0)
	if percent >= 0:
		return "+%d%%" % percent
	return "-%d%%" % absi(percent)
func _get_total_buff_rate(seed_rate: float, nightmare_rate: float) -> float:
	return (1.0 + seed_rate) * (1.0 + nightmare_rate) - 1.0
func set_digestion_count(count: int) -> void:
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
	_time_elapsed_tween.tween_property(_time_elapsed_label, "position:y", _time_elapsed_label_base_position.y - TIME_ELAPSED_FLOAT_DISTANCE, TIME_ELAPSED_TWEEN_DURATION)
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
func show_hp_damage_values(damage_values: Array[int]) -> void:
	var damage_texts: Array[String] = []
	for damage in damage_values:
		if damage > 0:
			damage_texts.append("-%d" % damage)
	if damage_texts.is_empty():
		return
	var label := Label.new()
	label.text = "\n".join(damage_texts)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.size = Vector2(92.0, maxf(36.0, float(damage_texts.size()) * 30.0))
	label.position = hp_frame.position + hp_text.position + Vector2((hp_text.size.x - label.size.x) * 0.5, -label.size.y + 4.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.add_theme_color_override("font_color", Color.html("#ff0736"))
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 3)
	var damage_font := hp_text.get_theme_font("font")
	if damage_font != null:
		label.add_theme_font_override("font", damage_font)
	label.add_theme_font_size_override("font_size", 28)
	add_child(label)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUART)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - HP_DAMAGE_FLOAT_DISTANCE, HP_DAMAGE_TWEEN_DURATION)
	tween.tween_property(label, "modulate:a", 1.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_interval(HP_DAMAGE_HIDE_DELAY)
	tween.chain().tween_property(label, "modulate:a", 0.0, HP_DAMAGE_TWEEN_DURATION)
	tween.chain().tween_callback(label.queue_free)
func hide_hp_damage_preview() -> void:
	_hp_damage_preview_label.visible = false
func _prepare_mouse_filters() -> void:
	passive_guide_frame.mouse_filter = Control.MOUSE_FILTER_STOP
	passive_guide_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digest_damage_value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digest_damage_detail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_gauge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	message_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	debug_reroll_button.mouse_filter = Control.MOUSE_FILTER_STOP
	debug_message_button.mouse_filter = Control.MOUSE_FILTER_STOP
	digestion_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	digestion_frame.mouse_filter = Control.MOUSE_FILTER_STOP
func _prepare_debug_message_button() -> void:
	debug_reroll_button.visible = false
	debug_reroll_button.pressed.connect(_on_debug_reroll_button_pressed)
	debug_message_button.pressed.connect(_on_debug_message_button_pressed)
func _prepare_digestion_button() -> void:
	_digestion_button_base_scale = digestion_frame.scale
	digestion_frame.pivot_offset = digestion_frame.size * 0.5
	digestion_frame.gui_input.connect(_on_digestion_frame_gui_input)
	digestion_frame.mouse_entered.connect(_on_digestion_frame_mouse_entered)
	digestion_frame.mouse_exited.connect(_on_digestion_frame_mouse_exited)
	passive_guide_frame.mouse_entered.connect(show_digest_damage_tooltip)
	passive_guide_frame.mouse_exited.connect(hide_digest_damage_tooltip)
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
func _create_digest_damage_tooltip() -> void:
	_digest_damage_tooltip = Panel.new()
	_digest_damage_tooltip.name = "DigestDamageTooltipPanel"
	_digest_damage_tooltip.visible = false
	_digest_damage_tooltip.z_index = 49
	_digest_damage_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_digest_damage_tooltip.position = Vector2.ZERO
	_digest_damage_tooltip.size = Vector2(384.0, 720.0)
	_digest_damage_tooltip.add_theme_stylebox_override("panel", _create_tooltip_style())
	add_child(_digest_damage_tooltip)

	var content := Control.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.position = Vector2(24.0, 24.0)
	content.size = Vector2(336.0, 672.0)
	_digest_damage_tooltip.add_child(content)

	_add_tooltip_label(content, "消化ダメージ詳細", Vector2(0.0, 0.0), Vector2(336.0, 52.0), 36)
	_add_tooltip_label(content, "最終消化ダメージ", Vector2(0.0, 76.0), Vector2(336.0, 38.0), 28)
	_digest_tooltip_total_value_label = _add_tooltip_label(content, "", Vector2(0.0, 118.0), Vector2(336.0, 34.0), 22)
	_add_tooltip_label(content, "基礎ダメージ", Vector2(0.0, 202.0), Vector2(336.0, 36.0), 26)
	_digest_tooltip_base_value_label = _add_tooltip_label(content, "", Vector2(0.0, 240.0), Vector2(336.0, 32.0), 20)
	_add_tooltip_label(content, "夢の種バフ", Vector2(0.0, 282.0), Vector2(336.0, 36.0), 26)
	_digest_tooltip_seed_value_label = _add_tooltip_label(content, "", Vector2(0.0, 320.0), Vector2(336.0, 32.0), 20)
	_add_tooltip_label(content, "悪夢バフ", Vector2(0.0, 362.0), Vector2(336.0, 36.0), 26)
	_digest_tooltip_nightmare_value_label = _add_tooltip_label(content, "", Vector2(0.0, 400.0), Vector2(336.0, 32.0), 20)
func _add_tooltip_label(parent: Control, text: String, position: Vector2, size: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = position
	label.size = size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TOOLTIP_TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	var font := digest_damage_detail.get_theme_font("font")
	if font != null:
		label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	if font_size <= 22:
		label.add_theme_color_override("font_color", TOOLTIP_SUB_TEXT_COLOR)
	parent.add_child(label)
	return label
func _create_tooltip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_content_margin(SIDE_LEFT, 24.0)
	style.set_content_margin(SIDE_TOP, 24.0)
	style.set_content_margin(SIDE_RIGHT, 24.0)
	style.set_content_margin(SIDE_BOTTOM, 24.0)
	style.bg_color = Color(0.0, 0.0, 0.0, 0.68)
	return style
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
	set_debug_button_active(not _debug_button_active)
	debug_message_requested.emit(_debug_button_active)
func _on_debug_reroll_button_pressed() -> void:
	if not _debug_button_active:
		return
	debug_reroll_requested.emit()
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
