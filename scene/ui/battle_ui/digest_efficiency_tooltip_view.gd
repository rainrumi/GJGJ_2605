class_name DigestEfficiencyTooltipView
extends Panel

@onready var current_value_label: Label = $Content/CurrentValueLabel
@onready var base_value_label: Label = $Content/BaseValueLabel


func show_tooltip() -> void:
	visible = true


func hide_tooltip() -> void:
	visible = false


func set_efficiency_info(amount_minutes: float) -> void:
	current_value_label.text = _format_minutes(amount_minutes)
	base_value_label.text = _format_minutes(30.0)


func _format_minutes(amount_minutes: float) -> String:
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%d秒" % total_seconds
	var total_minutes := int(total_seconds / 60)
	var hours := int(total_minutes / 60)
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%d分" % total_minutes
	if minutes_only == 0:
		return "%d時間" % hours
	return "%d時間%d分" % [hours, minutes_only]
