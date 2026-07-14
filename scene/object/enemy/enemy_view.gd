class_name EnemyView
extends Node

const DEFAULT_STATUS_COLOR := Color(0.0352941, 0.027451, 0.211765, 1.0)
const MAIN_EFFECT_STATUS_COLOR := Color(0.78, 0.18, 0.08, 1.0)

var _enemy: Enemy # 表示対象
var _sprite: EnemySpriteView # 敵画像
var _hp_label: EnemyHpText # HP表示
var _damage_label: EnemyDamageText # 攻撃表示
var _tooltip: EnemyTooltip # 詳細表示


# 表示初期化
func setup(enemy: Enemy, sprite: EnemySpriteView, hp_label: EnemyHpText, damage_label: EnemyDamageText, tooltip: EnemyTooltip) -> void:
	_enemy = enemy
	_sprite = sprite
	_hp_label = hp_label
	_damage_label = damage_label
	_tooltip = tooltip


# 画像設定
func setup_texture(texture: Texture2D, target_size: Vector2) -> void:
	if _sprite != null:
		_sprite.setup_texture(texture, target_size)


# 表示サイズ更新
func update_display_size(target_size: Vector2) -> void:
	if _sprite != null:
		_sprite.update_display_size(target_size)


# 表示状態設定
func set_presented(value: bool) -> void:
	if _enemy != null:
		_enemy.visible = value
	if _sprite != null:
		_sprite.visible = value
	if _hp_label != null:
		_hp_label.visible = value
	if _damage_label != null:
		_damage_label.visible = value
	if not value and _tooltip != null:
		_tooltip.hide_tooltip()


# 見た目初期化
func reset_visuals() -> void:
	if _sprite != null:
		_sprite.reset_visuals(_enemy)
	if _hp_label != null:
		_hp_label.reset_visuals()
	if _damage_label != null:
		_damage_label.reset_visuals()
	set_presented(true)


# HP表示更新
func show_hp(value: int) -> void:
	if _hp_label != null:
		_hp_label.show_hp(value)


# 攻撃表示更新
func show_damage(value: int) -> void:
	if _damage_label != null:
		_damage_label.show_damage(value)


# 状態色更新
func update_status_colors(has_main_effect: bool) -> void:
	var color := MAIN_EFFECT_STATUS_COLOR if has_main_effect else DEFAULT_STATUS_COLOR # 状態色
	if _hp_label != null:
		_hp_label.set_status_color(color)
	if _damage_label != null:
		_damage_label.set_status_color(color)


# ツール表示
func show_tooltip(debug_text: String, debug_visible: bool) -> void:
	if _tooltip != null:
		_tooltip.show_enemy_at(_enemy, debug_text, debug_visible, _enemy.global_position)


# ツール非表示
func hide_tooltip() -> void:
	if _tooltip != null:
		_tooltip.hide_tooltip()


# HP強調
func pulse_hp() -> void:
	if _hp_label != null:
		_hp_label.pulse_cost_label()


# 被弾強調
func pulse_damage() -> void:
	if _sprite != null:
		_sprite.pulse_damage()


# ホバー設定
func set_hovered(value: bool) -> void:
	if _sprite != null:
		_sprite.set_hovered(value)


# 表示矩形取得
func get_global_rect() -> Rect2:
	if _enemy == null:
		return Rect2()
	if _sprite == null or _sprite.texture == null:
		return Rect2(_enemy.global_position - Vector2(25.0, 25.0), Vector2(50.0, 50.0))
	var size := _sprite.texture.get_size() * _sprite.scale.abs() # 表示寸法
	return Rect2(_sprite.global_position - size * 0.5, size)


# 被弾値表示
func show_damage_popup(amount: int) -> void:
	EnemyDamagePopup.show_damage(_enemy, _hp_label, amount, MAIN_EFFECT_STATUS_COLOR)


# 被弾一覧表示
func show_damage_values(values: Array) -> void:
	EnemyDamagePopup.show_damage_values(_enemy, _hp_label, values, MAIN_EFFECT_STATUS_COLOR)


# 消化演出
func play_digested() -> void:
	if _sprite != null:
		_sprite.play_Acided_tween(_enemy)


# 復活表示
func show_revived() -> void:
	if _sprite != null:
		_sprite.stop_Acided_tween()
	_enemy.visible = true
	_enemy.scale = Vector2.ONE
	_enemy.modulate.a = 1.0
	set_presented(true)
