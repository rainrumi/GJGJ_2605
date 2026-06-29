class_name StageSelectDebugPanel
extends PanelContainer

# 内容領域
@onready var content_margin: StageSelectDebugMargin = $Margin

var _hovered_stage_definition: StageInfo


# 初期化
func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not DebugState.debug_enabled_changed.is_connected(_on_debug_enabled_changed):
		DebugState.debug_enabled_changed.connect(_on_debug_enabled_changed)


# 対象設定
func set_stage(stage_definition: StageInfo) -> void:
	_hovered_stage_definition = stage_definition
	_update_panel()


# 変更処理
func _on_debug_enabled_changed(_is_enabled: bool) -> void:
	_update_panel()


# 表示更新
func _update_panel() -> void:
	if not DebugState.debug_enabled or _hovered_stage_definition == null:
		content_margin.clear_stage()
		visible = false
		return
	content_margin.show_stage(_hovered_stage_definition)
	visible = true
