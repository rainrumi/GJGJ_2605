class_name StageSelectDebugMargin
extends MarginContainer

# 子要素
@onready var items: StageSelectDebugItems = $Items


# 表示設定
func show_stage(stage_definition: StageInfo) -> void:
	items.show_stage(stage_definition)


# 表示消去
func clear_stage() -> void:
	items.clear_stage()
