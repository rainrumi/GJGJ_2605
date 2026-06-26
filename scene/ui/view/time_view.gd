class_name TimeView
extends TextureRect

const TIME_PULSE_SCALE := 1.1
const TIME_PULSE_DURATION := 0.2
const TIME_ELAPSED_FLOAT_DISTANCE := 5.0
const TIME_ELAPSED_TWEEN_DURATION := 0.3
const TIME_ELAPSED_HIDE_DELAY := 0.2

signal tooltip_requested(view: TimeView)
signal tooltip_hide_requested(view: TimeView)

@onready var time_text: Label = $TimeText
@onready var time_tooltip: TimeTooltip = $TimeView_tooltip

var _time_text_base_scale := Vector2.ONE
var _time_text_pulse_tween: Tween
var _time_elapsed_label: Label
var _time_elapsed_label_base_position := Vector2.ZERO
var _time_elapsed_tween: Tween


# Ready
func _ready() -> void:
	_prepare_mouse_filters()
	_capture_sizes()
	_create_time_elapsed_label()
	time_tooltip.set_time_info()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# Set time
func set_time(minutes: int) -> void:
	# Hour
	var hour := int(minutes / 60) % 24
	# Minute
	var minute := minutes % 60
	time_text.text = "%02d:%02d" % [hour, minute]


# Show elapsed
func show_elapsed(amount_minutes: int) -> void:
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
	_time_elapsed_tween.chain().tween_callback(hide_elapsed)
	_pulse_time_text()


# Hide elapsed
func hide_elapsed() -> void:
	if _time_elapsed_tween != null and _time_elapsed_tween.is_valid():
		_time_elapsed_tween.kill()
	if _time_elapsed_label == null:
		return
	_time_elapsed_label.visible = false
	_time_elapsed_label.position = _time_elapsed_label_base_position
	_time_elapsed_label.modulate.a = 0.0


# ツール情報設定
func set_tooltip_info() -> void:
	time_tooltip.set_time_info()


# ツール表示
func show_tooltip() -> void:
	time_tooltip.show_tooltip_at(global_position)


# ツール非表示
func hide_tooltip() -> void:
	time_tooltip.hide_tooltip()


# Mouse setup
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	time_text.mouse_filter = Control.MOUSE_FILTER_IGNORE


# Capture size
func _capture_sizes() -> void:
	_time_text_base_scale = time_text.scale
	time_text.pivot_offset = time_text.size * 0.5


# Create label
func _create_time_elapsed_label() -> void:
	_time_elapsed_label = Label.new()
	_time_elapsed_label.name = "TimeElapsedLabel"
	_time_elapsed_label.visible = false
	_time_elapsed_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_time_elapsed_label.size = Vector2(52.0, 18.0)
	_time_elapsed_label_base_position = Vector2(-55.0, 21.0)
	_time_elapsed_label.position = _time_elapsed_label_base_position
	_time_elapsed_label.modulate.a = 0.0
	_time_elapsed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_time_elapsed_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_time_elapsed_label.add_theme_color_override("font_color", Color(0.94, 0.88, 1.0, 1.0))
	_time_elapsed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_time_elapsed_label.add_theme_constant_override("outline_size", 2)
	# Elapsed font
	var elapsed_font := time_text.get_theme_font("font")
	if elapsed_font != null:
		_time_elapsed_label.add_theme_font_override("font", elapsed_font)
	_time_elapsed_label.add_theme_font_size_override("font_size", 14)
	add_child(_time_elapsed_label)


# Pulse time
func _pulse_time_text() -> void:
	if _time_text_pulse_tween != null and _time_text_pulse_tween.is_valid():
		_time_text_pulse_tween.kill()
	time_text.scale = _time_text_base_scale
	_time_text_pulse_tween = create_tween()
	_time_text_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_time_text_pulse_tween.set_ease(Tween.EASE_OUT)
	_time_text_pulse_tween.tween_property(time_text, "scale", _time_text_base_scale * TIME_PULSE_SCALE, TIME_PULSE_DURATION * 0.5)
	_time_text_pulse_tween.tween_property(time_text, "scale", _time_text_base_scale, TIME_PULSE_DURATION * 0.5)


# Format elapsed
func _format_elapsed_time(amount_minutes: int) -> String:
	# Hours
	var hours := int(amount_minutes / 60)
	# Minutes
	var minutes_only := amount_minutes % 60
	if hours == 0:
		return "+%02dm" % minutes_only
	if minutes_only == 0:
		return "+%dh" % hours
	return "+%dh%02dm" % [hours, minutes_only]


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
