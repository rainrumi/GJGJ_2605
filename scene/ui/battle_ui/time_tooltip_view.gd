class_name TimeTooltipView
extends LeftTooltipView


func _ready() -> void:
	super()
	set_title("時刻")


func set_time_info() -> void:
	set_note(
		"6:00に到達すると戦闘が自動終了します。消化を始めると消化が進むごとに消化間隔分の時間が経過します。",
		true
	)
