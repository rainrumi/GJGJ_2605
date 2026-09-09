class_name Character
extends Node2D

const SHAKE_DURATION := 0.2
const SHAKE_DISTANCE := 1.0
const SHAKE_STEP_COUNT := 3
const SPECIAL_FACE_CHANGE_COUNT := 50

@onready var sprite: Sprite2D = $Sprite2D
@onready var face_button: Button = $FaceButton

@export var normal_texture: Texture2D
@export var damage_texture: Texture2D
@export var battle_clear_texture: Texture2D
@export var face_clicked_texture: Texture2D
@export var special_face_clicked_texture: Texture2D

var _shake_tween: Tween
var _sprite_base_position := Vector2.ZERO
var _face_change_count := 0


func _ready() -> void:
	_sprite_base_position = sprite.position
	sprite.texture = normal_texture
	face_button.pressed.connect(_on_face_button_pressed)


# 被ダメージ演出
func shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	sprite.position = _sprite_base_position
	sprite.texture = damage_texture
	_shake_tween = create_tween()
	var step_duration := SHAKE_DURATION / float(SHAKE_STEP_COUNT)
	for step in range(SHAKE_STEP_COUNT - 1):
		var direction := 1.0 if step % 2 == 0 else -1.0
		_shake_tween.tween_property(
			sprite,
			"position:x",
			_sprite_base_position.x + SHAKE_DISTANCE * direction,
			step_duration
		)
	_shake_tween.tween_property(sprite, "position:x", _sprite_base_position.x, step_duration)


func show_normal_texture() -> void:
	sprite.texture = normal_texture


func show_battle_clear_texture() -> void:
	sprite.texture = battle_clear_texture


func set_face_button_enabled(is_enabled: bool) -> void:
	face_button.disabled = not is_enabled


func _on_face_button_pressed() -> void:
	if face_button.disabled:
		return
	var target_texture := (
		special_face_clicked_texture
		if _face_change_count >= SPECIAL_FACE_CHANGE_COUNT
		else face_clicked_texture
	)
	if sprite.texture == target_texture:
		return
	_face_change_count += 1
	sprite.texture = (
		special_face_clicked_texture
		if _face_change_count >= SPECIAL_FACE_CHANGE_COUNT
		else face_clicked_texture
	)
