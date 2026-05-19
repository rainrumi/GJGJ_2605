class_name DreamSeedSkillTooltipView
extends Panel

const TOOLTIP_WIDTH := 220.0
const TOOLTIP_PADDING := 8.0
const MIN_TOOLTIP_HEIGHT := 24.0

@onready var tooltip_label: Label = $TooltipLabel

var _pending_text := ""


func _ready() -> void:
	_apply_text()


func set_text(text: String) -> void:
	_pending_text = text
	if not is_node_ready():
		return
	_apply_text()


func _apply_text() -> void:
	var label_width := TOOLTIP_WIDTH - TOOLTIP_PADDING * 2.0
	tooltip_label.text = _pending_text
	tooltip_label.position = Vector2(TOOLTIP_PADDING, TOOLTIP_PADDING)
	tooltip_label.size = Vector2(label_width, 0.0)
	var label_height := tooltip_label.get_combined_minimum_size().y
	tooltip_label.size = Vector2(label_width, label_height)
	size = Vector2(TOOLTIP_WIDTH, maxf(MIN_TOOLTIP_HEIGHT, label_height + TOOLTIP_PADDING * 2.0))
