class_name EnemySpriteView
extends Sprite2D

const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const DAMAGE_PULSE_SCALE := 1.12
const DAMAGE_PULSE_DURATION := 0.18
const ACIDED_SCALE := 1.2
const ACIDED_TWEEN_DURATION := 0.5

var base_scale := Vector2.ONE
var _hover_tween: Tween
var _damage_pulse_tween: Tween
var _Acided_tween: Tween
var _hovered := false


# 画像設定
func setup_texture(next_texture: Texture2D, target_size: Vector2) -> void:
	texture = next_texture
	if texture == null:
		return
	scale = target_size / texture.get_size()
	base_scale = scale


# 表示サイズ更新
func update_display_size(target_size: Vector2) -> void:
	if texture == null:
		return
	scale = target_size / texture.get_size()
	base_scale = scale


# ホバー設定
func set_hovered(value: bool) -> void:
	if _hovered == value:
		return
	_hovered = value
	_kill_hover_tween()
	var target_scale := base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(self, "scale", target_scale, HOVER_TWEEN_DURATION)


# 被弾強調
func pulse_damage() -> void:
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	_damage_pulse_tween = create_tween()
	_damage_pulse_tween.set_trans(Tween.TRANS_QUAD)
	_damage_pulse_tween.set_ease(Tween.EASE_OUT)
	_damage_pulse_tween.tween_property(self, "scale", base_scale * DAMAGE_PULSE_SCALE, DAMAGE_PULSE_DURATION * 0.5)
	_damage_pulse_tween.tween_property(self, "scale", base_scale, DAMAGE_PULSE_DURATION * 0.5)


# 消化演出
func play_Acided_tween(enemy_root: Node2D) -> void:
	stop_Acided_tween()
	_kill_hover_tween()
	_hovered = false
	enemy_root.visible = true
	enemy_root.scale = Vector2.ONE
	enemy_root.modulate.a = 1.0
	_Acided_tween = create_tween()
	_Acided_tween.set_parallel(true)
	_Acided_tween.set_trans(Tween.TRANS_QUART)
	_Acided_tween.set_ease(Tween.EASE_OUT)
	_Acided_tween.tween_property(enemy_root, "scale", Vector2.ONE * ACIDED_SCALE, ACIDED_TWEEN_DURATION)
	_Acided_tween.tween_property(enemy_root, "modulate:a", 0.0, ACIDED_TWEEN_DURATION)
	_Acided_tween.chain().tween_callback(func() -> void: enemy_root.visible = false)


# 消化演出停止
func stop_Acided_tween() -> void:
	if _Acided_tween != null and _Acided_tween.is_valid():
		_Acided_tween.kill()


# 見た目初期化
func reset_visuals(enemy_root: Node2D) -> void:
	_kill_hover_tween()
	if _damage_pulse_tween != null and _damage_pulse_tween.is_valid():
		_damage_pulse_tween.kill()
	stop_Acided_tween()
	_hovered = false
	enemy_root.scale = Vector2.ONE
	enemy_root.modulate.a = 1.0
	scale = base_scale


# ホバー停止
func _kill_hover_tween() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
