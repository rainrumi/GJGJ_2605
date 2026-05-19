class_name DreamSeedSkillTooltipView
extends Panel

@onready var tooltip_label: Label = $TooltipLabel

var _pending_text := ""


func _ready() -> void:
	tooltip_label.text = _pending_text


func set_text(text: String) -> void:
	_pending_text = text
	if not is_node_ready():
		return
	tooltip_label.text = text
