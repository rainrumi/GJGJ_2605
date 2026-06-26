class_name HpHealPlanView
extends NinePatchRect


# 初期化
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# 重なり順設定
func set_draw_order(order: int) -> void:
	z_index = order


# 予定非表示
func hide_plan() -> void:
	visible = false


# 予定表示
func show_plan(target_width: float, gauge_position: Vector2, gauge_height: float) -> void:
	visible = true
	position = gauge_position
	size = Vector2(target_width, gauge_height)
	z_index = 0
