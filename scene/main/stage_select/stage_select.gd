extends Node2D

signal stage_selected(stage: StageDefinition)

const BEACON_FRAME_DURATION := 0.1

@export var stage_catalog: StageCatalog
@export var stage_definitions: Array[StageDefinition] = []
@export var stage_choice_scene: PackedScene
@export var beacon_outline_frames: Array[Texture2D] = []
@export var beacon_fill_frames: Array[Texture2D] = []

@onready var stage_choice_list: VBoxContainer = $UI/StageChoicesScroll/StageChoicesMargin/StageChoices
@onready var beacon: Node2D = $CharacterArea/Map/Beacon
@onready var beacon_outline: Sprite2D = $CharacterArea/Map/Beacon/Outline
@onready var beacon_fill: Sprite2D = $CharacterArea/Map/Beacon/Fill

var stage_choices: Array[BaseButton] = []
var _displayed_stage_definitions: Array[StageDefinition] = []
var _current_stage_definition: StageDefinition
var _current_day := 1
var _hovered_stage_definition: StageDefinition
var _beacon_tween: Tween
var _beacon_frame_index := 0
var _beacon_frame_elapsed := 0.0


func _ready() -> void:
	_setup_beacon()
	_collect_stage_choices()
	setup_stage_choices()


func _process(delta: float) -> void:
	if not beacon.visible:
		return
	if beacon_outline_frames.is_empty() or beacon_fill_frames.is_empty():
		return
	_beacon_frame_elapsed += delta
	if _beacon_frame_elapsed < BEACON_FRAME_DURATION:
		return
	_beacon_frame_elapsed -= BEACON_FRAME_DURATION
	_beacon_frame_index = (_beacon_frame_index + 1) % mini(beacon_outline_frames.size(), beacon_fill_frames.size())
	_apply_beacon_frame()


func setup_stage_choices(current_stage_definition: StageDefinition = null, current_day: int = 1) -> void:
	if stage_choices.is_empty():
		_collect_stage_choices()
	_current_stage_definition = current_stage_definition
	_current_day = current_day
	_displayed_stage_definitions = _get_random_stage_definitions()
	_ensure_stage_choice_count(_displayed_stage_definitions.size())
	_hide_beacon()
	for i in range(stage_choices.size()):
		if i >= _displayed_stage_definitions.size():
			stage_choices[i].call("setup_choice", null)
			continue
		stage_choices[i].call("setup_choice", _displayed_stage_definitions[i])


func _on_stage_choice_pressed(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		return
	stage_selected.emit(stage_definition)


func _on_stage_choice_hovered(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		_hide_beacon()
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		_hide_beacon()
		return
	_hovered_stage_definition = stage_definition
	_show_beacon(stage_definition.map_position)


func _on_stage_choice_unhovered(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	if _hovered_stage_definition != _displayed_stage_definitions[choice_index]:
		return
	_hide_beacon()


func _get_stage_definitions() -> Array[StageDefinition]:
	if stage_catalog != null:
		return stage_catalog.stages
	return stage_definitions


func get_stage_definition_by_id(stage_id: int) -> StageDefinition:
	for stage_definition in _get_stage_definitions():
		var found_stage := _find_stage_definition_by_id(stage_definition, stage_id)
		if found_stage != null:
			return found_stage
	return null


func _get_random_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	if _is_high_difficulty_day():
		definitions = _get_high_difficulty_stage_definitions()
		definitions.shuffle()
		return definitions
	for stage_definition in _get_stage_definitions():
		if _can_reach_stage(stage_definition):
			definitions.append(stage_definition)
	definitions.shuffle()
	return definitions


func _collect_stage_choices() -> void:
	stage_choices.clear()
	for child in stage_choice_list.get_children():
		if child is BaseButton and child.has_method("setup_choice"):
			_add_stage_choice(child as BaseButton)


func _ensure_stage_choice_count(count: int) -> void:
	while stage_choices.size() < count:
		if stage_choice_scene == null:
			return
		var stage_choice := stage_choice_scene.instantiate()
		if not stage_choice is BaseButton or not stage_choice.has_method("setup_choice"):
			stage_choice.queue_free()
			return
		stage_choice_list.add_child(stage_choice)
		_add_stage_choice(stage_choice as BaseButton)


func _add_stage_choice(stage_choice: BaseButton) -> void:
	var choice_index := stage_choices.size()
	stage_choices.append(stage_choice)
	stage_choice.pressed.connect(_on_stage_choice_pressed.bind(choice_index))
	stage_choice.mouse_entered.connect(_on_stage_choice_hovered.bind(choice_index))
	stage_choice.mouse_exited.connect(_on_stage_choice_unhovered.bind(choice_index))
	stage_choice.focus_entered.connect(_on_stage_choice_hovered.bind(choice_index))
	stage_choice.focus_exited.connect(_on_stage_choice_unhovered.bind(choice_index))


func _setup_beacon() -> void:
	beacon.visible = false
	beacon.scale = Vector2.ONE
	beacon_outline.self_modulate = _get_background_color()
	beacon_fill.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	_reset_beacon_frame()


func _show_beacon(map_position: Vector2) -> void:
	beacon.position = map_position
	if not beacon.visible:
		_reset_beacon_frame()
	beacon.visible = true
	_start_beacon_animation()


func _hide_beacon() -> void:
	_hovered_stage_definition = null
	beacon.visible = false
	beacon.scale = Vector2.ONE
	if _beacon_tween != null and _beacon_tween.is_valid():
		_beacon_tween.kill()


func _start_beacon_animation() -> void:
	if _beacon_tween != null and _beacon_tween.is_valid():
		_beacon_tween.kill()
	beacon.scale = Vector2.ONE
	_beacon_tween = create_tween()
	_beacon_tween.set_loops()
	_beacon_tween.set_trans(Tween.TRANS_SINE)
	_beacon_tween.set_ease(Tween.EASE_IN_OUT)
	_beacon_tween.tween_property(beacon, "scale", Vector2(1.12, 1.12), 0.45)
	_beacon_tween.tween_property(beacon, "scale", Vector2.ONE, 0.45)


func _get_background_color() -> Color:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return Color(0.1254902, 0.1254902, 0.1254902, 1.0)
	var background_color := current_scene.get_node_or_null("BackgroundColor") as ColorRect
	if background_color == null:
		return Color(0.1254902, 0.1254902, 0.1254902, 1.0)
	return background_color.color


func _reset_beacon_frame() -> void:
	_beacon_frame_index = 0
	_beacon_frame_elapsed = 0.0
	_apply_beacon_frame()


func _apply_beacon_frame() -> void:
	if not beacon_outline_frames.is_empty():
		beacon_outline.texture = beacon_outline_frames[_beacon_frame_index % beacon_outline_frames.size()]
	if not beacon_fill_frames.is_empty():
		beacon_fill.texture = beacon_fill_frames[_beacon_frame_index % beacon_fill_frames.size()]


func _can_reach_stage(stage_definition: StageDefinition) -> bool:
	if stage_definition == null:
		return false
	if stage_definition.is_high_difficulty:
		return false
	if _current_stage_definition == null:
		return true
	return _current_stage_definition.reachable_stage_areas.has(stage_definition.stage_area)


func _is_high_difficulty_day() -> bool:
	return _current_day > 0 and _current_day % 4 == 0


func _get_high_difficulty_stage_definitions() -> Array[StageDefinition]:
	var definitions: Array[StageDefinition] = []
	var source_stages := _get_high_difficulty_source_stages()
	for source_stage in source_stages:
		if source_stage == null:
			continue
		if source_stage.high_difficulty_stages.is_empty():
			definitions.append(source_stage.create_high_difficulty_fallback())
			continue
		for high_stage in source_stage.high_difficulty_stages:
			if high_stage != null:
				definitions.append(high_stage)
	return definitions


func _get_high_difficulty_source_stages() -> Array[StageDefinition]:
	var source_stages: Array[StageDefinition] = []
	if _current_stage_definition == null:
		for stage_definition in _get_stage_definitions():
			if stage_definition != null and not stage_definition.is_high_difficulty:
				source_stages.append(stage_definition)
		return source_stages
	source_stages.append(_current_stage_definition)
	return source_stages


func _find_stage_definition_by_id(stage_definition: StageDefinition, stage_id: int) -> StageDefinition:
	if stage_definition == null:
		return null
	if stage_definition.stage_id == stage_id:
		return stage_definition
	for high_stage in stage_definition.high_difficulty_stages:
		var found_stage := _find_stage_definition_by_id(high_stage, stage_id)
		if found_stage != null:
			return found_stage
	return null
