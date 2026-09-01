class_name TodayRestButton
extends Button

const HOVER_SCALE := 1.05
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1
const RECOVERY_START_HOUR := 22
const RECOVERY_END_HOUR := 27
const RECOVERY_BASE_RATE := 0.5
const RECOVERY_HOURLY_LOSS_RATE := 0.1

@onready var frame: NinePatchRect = $Frame
@onready var recovery_label: Label = $RecoveryLabel

var _base_scale := Vector2.ONE
var _hovered := false
var _pressed := false
var _scale_tween: Tween


func _ready() -> void:
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# 現在時刻に応じた休息時のHP回復量を表示
func set_recovery_info(current_minutes: int, max_hp: int, planted_flowers: Array[SeedInfo]) -> void:
	var recovery_rate := StageClearCalculatorRecovery.get_clear_time_recovery_rate(
		planted_flowers,
		current_minutes,
		RECOVERY_START_HOUR,
		RECOVERY_END_HOUR,
		RECOVERY_BASE_RATE,
		RECOVERY_HOURLY_LOSS_RATE
	)
	var recovery_amount := ceili(float(max_hp) * recovery_rate)
	recovery_label.text = "（HP%d回復）" % recovery_amount


func _on_button_down() -> void:
	_pressed = true
	_update_scale()


func _on_button_up() -> void:
	_pressed = false
	_hovered = false
	_update_scale()


func _on_mouse_entered() -> void:
	_hovered = true
	_update_scale()


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_update_scale()


func _update_scale() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(frame, "scale", target_scale, TWEEN_DURATION)
