class_name StageClearAbandonButton
extends Button

const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1
const PRESSED_MODULATE := Color.WHITE
const DEFAULT_MODULATE := Color.WHITE

@onready var frame: NinePatchRect = $Frame

var _base_scale := Vector2.ONE
var _hovered := false
var _pressed := false
var _scale_tween: Tween


# 初期化
func _ready() -> void:
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# 回復率設定
func set_recovery_rate(recovery_rate: float) -> void:
	text = "放棄(HP%d%%回復)" % roundi(recovery_rate * 100.0)


# visualstate初期化
func reset_visual_state() -> void:
	_hovered = false
	_pressed = false
	frame.modulate = DEFAULT_MODULATE
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	frame.scale = _base_scale


# イベント処理
func _on_button_down() -> void:
	_pressed = true
	frame.modulate = PRESSED_MODULATE
	_update_scale()


# イベント処理
func _on_button_up() -> void:
	_pressed = false
	_hovered = false
	reset_visual_state()


# ホバー開始
func _on_mouse_entered() -> void:
	_hovered = true
	_update_scale()


# ホバー終了
func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_update_scale()


# scale更新
func _update_scale() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	# 対象scale
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(frame, "scale", target_scale, TWEEN_DURATION)
