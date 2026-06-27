class_name EnemyHpText
extends Label

const COST_PULSE_SCALE := 1.1
const COST_PULSE_DURATION := 0.2

var _cost_pulse_tween: Tween


# HP表示
func show_hp(current_hp: int) -> void:
	text = str(current_hp)


# 色設定
func set_status_color(status_color: Color) -> void:
	add_theme_color_override("font_color", status_color)


# コスト強調
func pulse_cost_label() -> void:
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	scale = Vector2.ONE
	_cost_pulse_tween = create_tween()
	_cost_pulse_tween.set_trans(Tween.TRANS_ELASTIC)
	_cost_pulse_tween.set_ease(Tween.EASE_OUT)
	_cost_pulse_tween.tween_property(self, "scale", Vector2.ONE * COST_PULSE_SCALE, COST_PULSE_DURATION * 0.5)
	_cost_pulse_tween.tween_property(self, "scale", Vector2.ONE, COST_PULSE_DURATION * 0.5)


# 見た目初期化
func reset_visuals() -> void:
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	scale = Vector2.ONE
