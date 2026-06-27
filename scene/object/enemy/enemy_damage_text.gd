class_name EnemyDamageText
extends Label


# 攻撃表示
func show_damage(display_damage: int) -> void:
	text = "攻 %d" % display_damage


# 色設定
func set_status_color(status_color: Color) -> void:
	add_theme_color_override("font_color", status_color)


# 見た目初期化
func reset_visuals() -> void:
	scale = Vector2.ONE
