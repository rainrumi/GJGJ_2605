class_name DigestDamageTooltipView
extends Panel

@onready var total_value_label: Label = $Content/TotalValueLabel
@onready var base_value_label: Label = $Content/BaseValueLabel
@onready var seed_value_label: Label = $Content/SeedValueLabel
@onready var nightmare_value_label: Label = $Content/NightmareValueLabel


# 詳細を表示
func show_tooltip() -> void:
	visible = true


# 詳細を隠す
func hide_tooltip() -> void:
	visible = false


# 詳細を更新
func set_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	nightmare_buff: int,
	nightmare_rate: float
) -> void:
	var total_buff_rate := _get_total_buff_rate(seed_rate, nightmare_rate)
	total_value_label.text = "%d（総合バフ %s）" % [total_damage, _format_buff_rate(total_buff_rate)]
	base_value_label.text = "%d" % base_damage
	seed_value_label.text = "%s（%s）" % [_format_buff_amount(seed_buff), _format_buff_rate(seed_rate)]
	nightmare_value_label.text = "%s（%s）" % [_format_buff_amount(nightmare_buff), _format_buff_rate(nightmare_rate)]


# 増減値を整形
func _format_buff_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return "-%d" % absi(amount)


# バフ率を整形
func _format_buff_rate(rate: float) -> String:
	var percent := roundi(rate * 100.0)
	if percent >= 0:
		return "+%d%%" % percent
	return "-%d%%" % absi(percent)


# 総合率を計算
func _get_total_buff_rate(seed_rate: float, nightmare_rate: float) -> float:
	return (1.0 + seed_rate) * (1.0 + nightmare_rate) - 1.0
