class_name StageSelectDebugSeedPoolItems
extends VBoxContainer

# 見出し
@onready var title_label: StageSelectDebugSeedPoolTitleLabel = $TitleLabel
# 種一覧
@onready var seed_scroll: StageSelectDebugSeedPoolScroll = $DebugSeedScroll


# 表示設定
func show_stage(stage_definition: StageInfo) -> void:
	title_label.show_stage(stage_definition)
	seed_scroll.show_stage(stage_definition)


# 表示消去
func clear_stage() -> void:
	title_label.clear_stage()
	seed_scroll.clear_stage()
