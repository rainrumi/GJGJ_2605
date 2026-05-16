class_name TimeTooltipView
extends LeftTooltipView


func _ready() -> void:
	super()
	set_title("時刻")


func set_time_info(rest_minutes: int, rest_hp_rate: float) -> void:
	var rest_hp_percent := roundi(rest_hp_rate * 100.0)
	set_note(
		"6:00に到達すると戦闘が自動終了します。プレイヤーのHPが0になるとペナルティとして%d分経過し、HPを%d%%回復します。消化を始めると消化が進むごとに消化間隔分の時間が経過します。" % [rest_minutes, rest_hp_percent],
		true
	)
