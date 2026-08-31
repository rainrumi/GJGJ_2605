class_name Character
extends Node2D

const SHAKE_DURATION := 0.2
const SHAKE_DISTANCE := 1.0
const SHAKE_STEP_COUNT := 3

@onready var sprite: Sprite2D = $Sprite2D

var _shake_tween: Tween
var _sprite_base_position := Vector2.ZERO


func _ready() -> void:
	_sprite_base_position = sprite.position


# 被ダメージ演出
func shake() -> void:
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	sprite.position = _sprite_base_position
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
