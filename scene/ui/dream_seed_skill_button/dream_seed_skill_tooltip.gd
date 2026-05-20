class_name DreamSeedSkillTooltipView
extends Panel

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
	TooltipTextLayout.apply_to_panel(self, tooltip_label, _pending_text)
