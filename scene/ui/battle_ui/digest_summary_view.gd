class_name DigestSummaryView
extends TextureRect

signal detail_requested
signal detail_closed

@onready var title_label: Label = $PassiveGuideText
@onready var damage_value_label: Label = $DigestDamageValue
@onready var efficiency_value_label: Label = $DigestEfficiencyValue
@onready var efficiency_title_label: Label = $DigestEfficiencyTitle
@onready var detail_label: Label = $DigestDamageDetail


# 初期化
func _ready() -> void:
	_prepare_mouse_filters()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


# 表示を初期化
func reset_summary() -> void:
	set_digest_damage(0)
	set_digest_efficiency_minutes(30.0)
	title_label.text = "消化ダメージ"
	detail_label.visible = false


# ダメージ表示
func set_digest_damage(total_damage: int) -> void:
	title_label.text = "消化ダメージ"
	damage_value_label.text = "%d" % total_damage
	detail_label.visible = false


# 効率表示
func set_digest_efficiency_minutes(amount_minutes: float) -> void:
	efficiency_value_label.text = _format_digest_efficiency(amount_minutes)


# マウス設定
func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	damage_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	efficiency_value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	efficiency_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	detail_label.mouse_filter = Control.MOUSE_FILTER_IGNORE


# 効率を整形
func _format_digest_efficiency(amount_minutes: float) -> String:
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%dsec" % total_seconds
	var total_minutes := int(total_seconds / 60)
	var hours := int(total_minutes / 60)
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%dmin" % total_minutes
	if minutes_only == 0:
		return "%dh" % hours
	return "%dh%dm" % [hours, minutes_only]


# 詳細を要求
func _on_mouse_entered() -> void:
	detail_requested.emit()


# 詳細を閉じる
func _on_mouse_exited() -> void:
	detail_closed.emit()
