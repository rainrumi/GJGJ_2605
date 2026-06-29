class_name StageSelectDebugSeedPoolScroll
extends ScrollContainer

# 本文
@onready var seed_pool_text: StageSelectDebugSeedPoolText = $SeedPoolText


# 表示設定
func show_stage(stage_definition: StageInfo) -> void:
	seed_pool_text.show_stage(stage_definition)


# 表示消去
func clear_stage() -> void:
	seed_pool_text.clear_stage()
