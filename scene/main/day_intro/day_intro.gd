class_name DayIntro
extends CanvasLayer

const DISPLAY_DURATION := 2.0

@onready var day_label: Label = $Screen/DayLabel


func _ready() -> void:
	visible = false


func show_day(day: int) -> void:
	day_label.text = "%d日目" % day
	visible = true
	await get_tree().create_timer(DISPLAY_DURATION).timeout
	visible = false
