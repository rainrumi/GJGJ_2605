class_name DayIntro
extends CanvasLayer

const DISPLAY_DURATION := 2.0
const FADE_IN_DURATION := 0.5

@onready var day_label: Label = $Screen/DayLabel
@onready var screen: Control = $Screen

var _fade_tween: Tween


# 初期化
func _ready() -> void:
	visible = false


# 日数表示
func show_day(day: int) -> void:
	day_label.text = "%d日目" % _get_start_display_day(day)
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	screen.modulate.a = 0.0
	visible = true
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUART)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(screen, "modulate:a", 1.0, FADE_IN_DURATION)
	await get_tree().create_timer(DISPLAY_DURATION * 0.5).timeout
	day_label.text = "%d日目" % day
	await get_tree().create_timer(DISPLAY_DURATION * 0.5).timeout
	visible = false


# startdisplay日数取得
func _get_start_display_day(day: int) -> int:
	if day <= 1:
		return day
	return day - 1
