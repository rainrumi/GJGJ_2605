class_name DigestSummaryView
extends TextureRect

signal detail_requested
signal detail_closed
signal efficiency_detail_requested
signal efficiency_detail_closed

@onready var title_label: Label = $PassiveGuideText
@onready var damage_value_label: Label = $DigestDamageValue
@onready var efficiency_value_label: Label = $DigestEfficiencyValue
@onready var efficiency_title_label: Label = $DigestEfficiencyTitle


func _ready() -> void:
	_prepare_mouse_filters()
	title_label.mouse_entered.connect(_on_damage_mouse_entered)
	damage_value_label.mouse_entered.connect(_on_damage_mouse_entered)
	title_label.mouse_exited.connect(_on_damage_mouse_exited)
	damage_value_label.mouse_exited.connect(_on_damage_mouse_exited)
	efficiency_title_label.mouse_entered.connect(_on_efficiency_mouse_entered)
	efficiency_value_label.mouse_entered.connect(_on_efficiency_mouse_entered)
	efficiency_title_label.mouse_exited.connect(_on_efficiency_mouse_exited)
	efficiency_value_label.mouse_exited.connect(_on_efficiency_mouse_exited)


func reset_summary() -> void:
	set_digest_damage(0)
	set_digest_efficiency_minutes(30.0)
	title_label.text = "消化ダメージ"


func set_digest_damage(total_damage: int) -> void:
	title_label.text = "消化ダメージ"
	damage_value_label.text = "%d" % total_damage


func set_digest_efficiency_minutes(amount_minutes: float) -> void:
	efficiency_value_label.text = _format_digest_efficiency(amount_minutes)


func _prepare_mouse_filters() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.mouse_filter = Control.MOUSE_FILTER_STOP
	damage_value_label.mouse_filter = Control.MOUSE_FILTER_STOP
	efficiency_value_label.mouse_filter = Control.MOUSE_FILTER_STOP
	efficiency_title_label.mouse_filter = Control.MOUSE_FILTER_STOP


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


func _on_damage_mouse_entered() -> void:
	detail_requested.emit()


func _on_damage_mouse_exited() -> void:
	detail_closed.emit()


func _on_efficiency_mouse_entered() -> void:
	efficiency_detail_requested.emit()


func _on_efficiency_mouse_exited() -> void:
	efficiency_detail_closed.emit()
