class_name SeedTooltip
extends Panel

@onready var tooltip_label: Label = $TooltipLabel

var _pending_text := ""


# 初期化
func _ready() -> void:
	_apply_text()


# 文言設定
func set_text(text: String) -> void:
	_pending_text = text
	if not is_node_ready():
		return
	_apply_text()


# 文言適用
func _apply_text() -> void:
	TooltipTextLayout.apply_to_panel(self, tooltip_label, _pending_text)
