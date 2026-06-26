class_name HpGaugeView
extends NinePatchRect

signal width_tween_finished

var _full_width := 0.0
var _width_tween: Tween


# 初期化
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	capture_full_width()


# 幅記録
func capture_full_width() -> void:
	_full_width = size.x


# 幅取得
func get_full_width() -> float:
	return _full_width


# 重なり順設定
func set_draw_order(order: int) -> void:
	z_index = order


# ゲージ表示
func show_gauge() -> void:
	visible = true


# 即時幅設定
func set_width_immediate(target_width: float, hide_when_empty: bool) -> void:
	size = Vector2(target_width, size.y)
	if hide_when_empty:
		visible = false


# 幅アニメ開始
func animate_width(target_width: float, duration: float, hide_when_empty: bool) -> void:
	kill_width_tween()
	_width_tween = create_tween()
	_width_tween.set_trans(Tween.TRANS_QUAD)
	_width_tween.set_ease(Tween.EASE_OUT)
	_width_tween.tween_property(self, "size", Vector2(target_width, size.y), duration)
	_width_tween.tween_callback(Callable(self, "_emit_width_tween_finished"))
	if hide_when_empty:
		_width_tween.tween_callback(func() -> void: visible = false)


# 幅アニメ停止
func kill_width_tween() -> void:
	if _width_tween != null and _width_tween.is_valid():
		_width_tween.kill()


# 完了通知
func _emit_width_tween_finished() -> void:
	width_tween_finished.emit()
