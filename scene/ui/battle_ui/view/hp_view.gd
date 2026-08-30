class_name StageClearHpView
extends TextureRect

signal tooltip_requested(view: StageClearHpView)
signal tooltip_hide_requested(view: StageClearHpView)

@onready var hp_icon: TextureRect = $Icon
@onready var hp_value_label: Label = $Value
@onready var hp_tooltip: HpTooltip = $HpView_tooltip

var _editor_hp_value_font_color := Color.WHITE


# 初期化
func _ready() -> void:
	_editor_hp_value_font_color = hp_value_label.get_theme_color("font_color")
	_prepare_mouse_filters()
	hp_value_label.minimum_size_changed.connect(_update_minimum_width)
	_update_minimum_width()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# HP値設定
func set_hp_value(current_hp: int, max_hp: int) -> void:
	hp_value_label.text = "%d/%d" % [current_hp, max_hp]
	_update_minimum_width()


# HP情報設定
func set_hp_info(
	current_hp: int,
	max_hp: int,
	rest_minutes: int,
	rest_hp_rate: float,
	rest_recovery_bonus_rate: float
) -> void:
	set_hp_value(current_hp, max_hp)
	hp_tooltip.set_hp_info(
		current_hp,
		max_hp,
		rest_minutes,
		rest_hp_rate,
		rest_recovery_bonus_rate
	)


# ツールチップ表示
func show_tooltip() -> void:
	hp_tooltip.show_tooltip_at(global_position)


# ツールチップ非表示
func hide_tooltip() -> void:
	hp_tooltip.hide_tooltip()


# エディター設定の文字色へ戻す
func restore_value_font_color() -> void:
	hp_value_label.add_theme_color_override("font_color", _editor_hp_value_font_color)


# 入力準備
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hp_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _update_minimum_width() -> void:
	custom_minimum_size.x = hp_value_label.position.x + hp_value_label.get_combined_minimum_size().x
	if get_parent() is Container:
		(get_parent() as Container).queue_sort()


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	tooltip_hide_requested.emit(self)
