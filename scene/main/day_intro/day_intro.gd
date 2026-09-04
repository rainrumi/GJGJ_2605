class_name DayIntro
extends CanvasLayer

const DISPLAY_DURATION := 2.0
const FADE_IN_DURATION := 0.5
# ゲーム画面の Character.position (95, 210) と SeedButtonList.position (40, 54) の差分
const HEAD_SEED_OFFSET_FROM_CHARACTER := Vector2(-55.0, -156.0)

@onready var day_label: Label = $Screen/DayLabel
@onready var screen: Control = $Screen
@onready var character: Sprite2D = $Screen/Character
@onready var head_seed_list: PassiveSeedTextureList = $Screen/HeadSeedList

var _fade_tween: Tween


# 初期化
func _ready() -> void:
	visible = false
	head_seed_list.position = character.position + HEAD_SEED_OFFSET_FROM_CHARACTER


# 日数表示
func show_day(day: int, equipped_seeds: Array = []) -> void:
	set_equipped_seeds(equipped_seeds)
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


# 頭上に表示する装備中の夢の種を設定
func set_equipped_seeds(equipped_seeds: Array) -> void:
	head_seed_list.set_seed_sources(equipped_seeds)


# startdisplay日数取得
func _get_start_display_day(day: int) -> int:
	if day <= 1:
		return day
	return day - 1
