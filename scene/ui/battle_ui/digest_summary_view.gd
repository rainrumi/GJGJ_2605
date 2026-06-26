class_name DigestSummaryView
extends TextureRect

signal detail_requested
signal detail_closed
signal efficiency_detail_requested
signal efficiency_detail_closed

@onready var title_icon: Control = $PassiveGuideText
@onready var damage_value_label: Label = $DigestDamageValue
@onready var efficiency_value_label: Label = $DigestEfficiencyValue
@onready var efficiency_title_icon: Control = $DigestEfficiencyTitle


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	title_icon.mouse_entered.connect(_on_damage_mouse_entered)
	damage_value_label.mouse_entered.connect(_on_damage_mouse_entered)
	title_icon.mouse_exited.connect(_on_damage_mouse_exited)
	damage_value_label.mouse_exited.connect(_on_damage_mouse_exited)
	efficiency_title_icon.mouse_entered.connect(_on_efficiency_mouse_entered)
	efficiency_value_label.mouse_entered.connect(_on_efficiency_mouse_entered)
	efficiency_title_icon.mouse_exited.connect(_on_efficiency_mouse_exited)
	efficiency_value_label.mouse_exited.connect(_on_efficiency_mouse_exited)


# summary初期化
func reset_summary() -> void:
	set_digest_damage(0)
	set_digest_efficiency_minutes(30.0)


# 消化ダメージ設定
func set_digest_damage(total_damage: int) -> void:
	damage_value_label.text = "%d" % total_damage


# 消化efficiency分数設定
func set_digest_efficiency_minutes(amount_minutes: float) -> void:
	efficiency_value_label.text = _format_digest_efficiency(amount_minutes)


# マウスfilters準備
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_icon.mouse_filter = Control.MOUSE_FILTER_STOP
	damage_value_label.mouse_filter = Control.MOUSE_FILTER_STOP
	efficiency_value_label.mouse_filter = Control.MOUSE_FILTER_STOP
	efficiency_title_icon.mouse_filter = Control.MOUSE_FILTER_STOP


# 消化efficiency整形
func _format_digest_efficiency(amount_minutes: float) -> String:
	# 合計seconds
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%dsec" % total_seconds
	# 合計分数
	var total_minutes := int(total_seconds / 60)
	# hours
	var hours := int(total_minutes / 60)
	# 分数only
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%dmin" % total_minutes
	if minutes_only == 0:
		return "%dh" % hours
	return "%dh%dm" % [hours, minutes_only]


# ホバー開始
func _on_damage_mouse_entered() -> void:
	detail_requested.emit()


# ホバー終了
func _on_damage_mouse_exited() -> void:
	detail_closed.emit()


# ホバー開始
func _on_efficiency_mouse_entered() -> void:
	efficiency_detail_requested.emit()


# ホバー終了
func _on_efficiency_mouse_exited() -> void:
	efficiency_detail_closed.emit()
