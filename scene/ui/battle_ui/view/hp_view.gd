class_name StageClearHpView
extends TextureRect

signal tooltip_requested(view: StageClearHpView)
signal tooltip_hide_requested(view: StageClearHpView)

@onready var hp_icon: TextureRect = $Icon
@onready var hp_value_label: Label = $Value


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# HP値設定
func set_hp_value(hp: int) -> void:
	hp_value_label.text = "%d" % hp


# 入力準備
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
