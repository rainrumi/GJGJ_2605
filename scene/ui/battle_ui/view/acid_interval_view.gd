class_name AcidIntervalView
extends TextureRect

signal tooltip_requested(view: AcidIntervalView)

@onready var acid_interval_icon: Control = $AcidIntervalView_icon
@onready var acid_interval_value_label: Label = $AcidIntervalView_value
@onready var acid_interval_view_tooltip: AcidIntervalViewTooltip = $AcidIntervalView_tooltip


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# interval情報設定
func set_interval_info(
	amount_minutes: float,
	base_minutes: float = 30.0,
	seed_buff: int = 0,
	seed_rate: float = 0.0,
	nightmare_buff: int = 0,
	nightmare_rate: float = 0.0
) -> void:
	set_interval_value(amount_minutes)
	acid_interval_view_tooltip.set_interval_info(amount_minutes, base_minutes, seed_buff, seed_rate, nightmare_buff, nightmare_rate)


# interval値設定
func set_interval_value(amount_minutes: float) -> void:
	acid_interval_value_label.text = _format_interval(amount_minutes)


# ツール表示
func show_tooltip() -> void:
	acid_interval_view_tooltip.show_tooltip_at(global_position)


# ツール非表示
func hide_tooltip() -> void:
	acid_interval_view_tooltip.hide_tooltip()


# 入力準備
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	acid_interval_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	acid_interval_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# interval整形
func _format_interval(amount_minutes: float) -> String:
	# 合計秒
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%dsec" % total_seconds
	# 合計分
	var total_minutes := int(total_seconds / 60)
	# 時間
	var hours := int(total_minutes / 60)
	# 分のみ
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%dmin" % total_minutes
	if minutes_only == 0:
		return "%dh" % hours
	return "%dh%dm" % [hours, minutes_only]


# hover開始
func _on_mouse_entered() -> void:
	tooltip_requested.emit(self)


# hover終了
func _on_mouse_exited() -> void:
	hide_tooltip()
