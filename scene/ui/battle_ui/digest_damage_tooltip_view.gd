class_name DigestDamageTooltipView
extends LeftTooltipView


func _ready() -> void:
	super()
	set_title("消化ダメージ")
	set_note("消化が進むごとに最終消化ダメージを与えます。", true)


func set_damage_info(
	total_damage: int,
	base_damage: int,
	seed_buff: int,
	seed_rate: float,
	nightmare_buff: int,
	nightmare_rate: float
) -> void:
	var total_buff_rate := _get_total_buff_rate(seed_rate, nightmare_rate)
	set_entries([
		{
			"explanation": "最終消化ダメージ",
			"value": "%d（総合バフ %s）" % [total_damage, _format_buff_rate(total_buff_rate)],
		},
		{
			"explanation": "基礎ダメージ",
			"value": "%d" % base_damage,
		},
		{
			"explanation": "夢の種バフ",
			"value": "%s（%s）" % [_format_buff_amount(seed_buff), _format_buff_rate(seed_rate)],
			"enabled": not is_zero_approx(seed_rate),
		},
		{
			"explanation": "悪夢バフ",
			"value": "%s（%s）" % [_format_buff_amount(nightmare_buff), _format_buff_rate(nightmare_rate)],
			"enabled": not is_zero_approx(nightmare_rate),
		},
	])


func _format_buff_amount(amount: int) -> String:
	if amount >= 0:
		return "+%d" % amount
	return "-%d" % absi(amount)


func _format_buff_rate(rate: float) -> String:
	var percent := roundi(rate * 100.0)
	if percent >= 0:
		return "+%d%%" % percent
	return "-%d%%" % absi(percent)


func _get_total_buff_rate(seed_rate: float, nightmare_rate: float) -> float:
	return (1.0 + seed_rate) * (1.0 + nightmare_rate) - 1.0
