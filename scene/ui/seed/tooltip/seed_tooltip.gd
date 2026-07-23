class_name SeedTooltip
extends CanvasLayer

const TOOLTIP_OFFSET := Vector2(18.0, -8.0)

@onready var tooltip_panel: Panel = $Panel
@onready var tooltip_label: Label = $Panel/TooltipLabel
@onready var _mouse_drag_state: MouseDragTracker = get_node("/root/MouseDragState")

var _pending_text := ""


# 初期化
func _ready() -> void:
	_apply_text()
	if not _mouse_drag_state.dragging_started.is_connected(hide_tooltip):
		_mouse_drag_state.dragging_started.connect(hide_tooltip)


# 文言設定
func set_text(text: String) -> void:
	_pending_text = text
	if not is_node_ready():
		return
	_apply_text()


# ツール表示
func show_tooltip_at(anchor_global_position: Vector2) -> void:
	if _mouse_drag_state.is_dragging():
		hide_tooltip()
		return
	tooltip_panel.global_position = TooltipPositioner.get_tooltip_position(
		anchor_global_position,
		tooltip_panel.size,
		get_viewport().get_visible_rect(),
		TOOLTIP_OFFSET
	)
	visible = true


# ツール非表示
func hide_tooltip() -> void:
	visible = false


# 文言適用
func _apply_text() -> void:
	TooltipTextLayout.apply_to_panel(tooltip_panel, tooltip_label, _pending_text)
