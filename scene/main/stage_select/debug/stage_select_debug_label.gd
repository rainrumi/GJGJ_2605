class_name StageSelectDebugLabel
extends Label


# 表示設定
func show_stage(stage_definition: StageInfo) -> void:
	if stage_definition == null:
		clear_stage()
		return
	text = "%s" % stage_definition.location


# 表示消去
func clear_stage() -> void:
	text = ""
