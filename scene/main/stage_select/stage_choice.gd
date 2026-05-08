class_name StageSelectChoice
extends Button

const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1

@onready var frame: TextureRect = $Frame
@onready var name_label: Label = $NameLabel
@onready var detail_label: Label = $DetailLabel

var _base_scale := Vector2.ONE
var _hovered := false
var _pressed := false
var _scale_tween: Tween


func _ready() -> void:
	frame.pivot_offset = frame.size * 0.5
	_base_scale = frame.scale
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup_choice(title: String, detail: String) -> void:
	name_label.text = title
	detail_label.text = detail


func _on_button_down() -> void:
	_pressed = true
	_update_scale()


func _on_button_up() -> void:
	_pressed = false
	_hovered = false
	_update_scale()


func _on_mouse_entered() -> void:
	_hovered = true
	_update_scale()


func _on_mouse_exited() -> void:
	_hovered = false
	_pressed = false
	_update_scale()


func _update_scale() -> void:
	if _scale_tween != null and _scale_tween.is_valid():
		_scale_tween.kill()
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	if _pressed:
		target_scale = _base_scale * PRESSED_SCALE
	_scale_tween = create_tween()
	_scale_tween.set_trans(Tween.TRANS_QUAD)
	_scale_tween.set_ease(Tween.EASE_OUT)
	_scale_tween.tween_property(frame, "scale", target_scale, TWEEN_DURATION)
