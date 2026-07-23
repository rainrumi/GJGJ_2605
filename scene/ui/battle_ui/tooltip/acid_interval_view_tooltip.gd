class_name AcidIntervalViewTooltip
extends LeftTooltip


# 初期化
func _ready() -> void:
	super()
	set_title("消化間隔")
	set_note("最終消化間隔分の時間が経過すると消化ダメージを与えます。", true)


# interval情報設定
func set_interval_info(
	amount_minutes: float,
	base_minutes: float = 30.0,
	seed_buff: int = 0,
	seed_rate: float = 0.0,
	enemy_buff: int = 0,
	enemy_rate: float = 0.0
) -> void:
	set_entries([
		{
			"explanation": "最終消化間隔",
			"value": _format_minutes(amount_minutes),
		},
		{
			"explanation": "基礎消化間隔",
			"value": _format_minutes(base_minutes),
		},
		{
			"explanation": "夢の種バフ",
			"value": "%s（%s）" % [_format_buff_minutes(seed_buff), _format_buff_rate(seed_rate)],
			"enabled": not is_zero_approx(seed_rate),
		},
		{
			"explanation": "悪夢バフ",
			"value": "%s（%s）" % [_format_buff_minutes(enemy_buff), _format_buff_rate(enemy_rate)],
			"enabled": not is_zero_approx(enemy_rate),
		},
	])


# 分数整形
func _format_minutes(amount_minutes: float) -> String:
	# 合計seconds
	var total_seconds := maxi(1, roundi(amount_minutes * 60.0))
	if total_seconds < 60:
		return "%d秒" % total_seconds
	# 合計分数
	var total_minutes := int(total_seconds / 60)
	# hours
	var hours := int(total_minutes / 60)
	# 分数only
	var minutes_only := total_minutes % 60
	if hours <= 0:
		return "%d分" % total_minutes
	if minutes_only == 0:
		return "%d時間" % hours
	return "%d時間%d分" % [hours, minutes_only]


# buff分数整形
func _format_buff_minutes(amount_minutes: int) -> String:
	if amount_minutes == 0:
		return "+0分"
	# sign
	var sign := "+" if amount_minutes >= 0 else "-"
	return "%s%s" % [sign, _format_minutes(absi(amount_minutes))]


# buff率整形
func _format_buff_rate(rate: float) -> String:
	# 割合
	var percent := roundi(rate * 100.0)
	if percent >= 0:
		return "+%d%%" % percent
	return "-%d%%" % absi(percent)
