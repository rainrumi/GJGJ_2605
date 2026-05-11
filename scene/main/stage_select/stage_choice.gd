class_name StageSelectChoice
extends Button

const HOVER_SCALE := 1.1
const PRESSED_SCALE := 0.95
const TWEEN_DURATION := 0.1

@export var tag_frame_scene: PackedScene

@onready var frame: TextureRect = $Frame
@onready var name_label: Label = $NameLabel
@onready var difficulty_label: Label = $DifficultyLabel
@onready var location_label: Label = $LocationLabel
@onready var reward_icon: TextureRect = $RewardIcon
@onready var tags_container: HBoxContainer = $TagsContainer

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


func setup_choice(stage_definition: StageDefinition) -> void:
	if stage_definition == null:
		disabled = true
		return
	difficulty_label.text = stage_definition.get_difficulty_text()
	name_label.text = ""
	name_label.visible = false
	location_label.text = "場所 %s" % stage_definition.location
	reward_icon.texture = stage_definition.reward_icon
	_setup_tag_frames(_get_tag_names(stage_definition))


func _get_tag_names(stage_definition: StageDefinition) -> Array[String]:
	var tag_names: Array[String] = []
	if stage_definition.is_rare:
		tag_names.append("レア")
	for tag in stage_definition.tags:
		var tag_name := String(tag)
		if not tag_name.is_empty():
			tag_names.append(tag_name)
	if tag_names.is_empty():
		tag_names.append("通常")
	return tag_names


func _setup_tag_frames(tag_names: Array[String]) -> void:
	for child in tags_container.get_children():
		child.queue_free()
	if tag_frame_scene == null:
		return
	for tag_name in tag_names:
		var tag_frame := tag_frame_scene.instantiate() as StageSelectTagFrame
		if tag_frame == null:
			continue
		tags_container.add_child(tag_frame)
		tag_frame.setup_tag(tag_name)


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
