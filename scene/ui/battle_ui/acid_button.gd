class_name AcidButton
extends TextureRect

signal digestion_requested

const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1

var _base_scale := Vector2.ONE
var _hover_tween: Tween


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	_base_scale = scale
	pivot_offset = size * 0.5
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# 回数を反映
func set_count(_count: int) -> void:
	pass


# 表示を切替
func set_button_visible(is_visible: bool) -> void:
	visible = is_visible
	if not is_visible:
		scale = _base_scale


# 命中を判定
func is_hit(mouse_position: Vector2) -> bool:
	if not visible:
		return false
	return get_global_rect().has_point(mouse_position)


# 入力設定
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


# 入力を処理
func _on_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton:
		# マウスイベント
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			digestion_requested.emit()


# ホバー開始
func _on_mouse_entered() -> void:
	_set_hovered(true)


# ホバー終了
func _on_mouse_exited() -> void:
	_set_hovered(false)


# ホバー反映
func _set_hovered(is_hovered: bool) -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	# 対象scale
	var target_scale := _base_scale
	if is_hovered:
		target_scale *= HOVER_SCALE
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION)
