extends Node2D

signal stage_selected(stage: StageDefinition)

const BEACON_FRAME_DURATION := 0.1
const LOCATION_MARKER_FRAME_DURATION := 0.1

@export var stage_catalog: StageCatalog
@export var stage_definitions: Array[StageDefinition] = []
@export var stage_choice_scene: PackedScene
@export var beacon_outline_frames: Array[Texture2D] = []
@export var beacon_fill_frames: Array[Texture2D] = []
@export var location_outline_frames: Array[Texture2D] = []
@export var location_fill_frames: Array[Texture2D] = []
@export var location_outline_texture: Texture2D
@export var location_fill_texture: Texture2D

@onready var stage_choice_list: VBoxContainer = $UI/StageChoicesScroll/StageChoicesMargin/StageChoices
@onready var beacon: Node2D = $CharacterArea/Map/Beacon
@onready var beacon_outline: Sprite2D = $CharacterArea/Map/Beacon/Outline
@onready var beacon_fill: Sprite2D = $CharacterArea/Map/Beacon/Fill
@onready var location_marker: Node2D = $CharacterArea/Map/LocationMarker
@onready var location_marker_outline: Sprite2D = $CharacterArea/Map/LocationMarker/Outline
@onready var location_marker_fill: Sprite2D = $CharacterArea/Map/LocationMarker/Fill

var stage_choices: Array[BaseButton] = []
var _displayed_stage_definitions: Array[StageDefinition] = []
var _current_stage_definition: StageDefinition
var _current_day := 1
var _unlocked_high_difficulty_stage_ids: Array[int] = []
var _run_state: RunState
var _hovered_stage_definition: StageDefinition
var _beacon_tween: Tween
var _beacon_frame_index := 0
var _beacon_frame_elapsed := 0.0
var _location_marker_frame_index := 0
var _location_marker_frame_elapsed := 0.0
var _location_marker_playing := false
var stage_selection_service := StageSelectionService.new()


func _ready() -> void:
	_setup_map_view()
	_collect_stage_choices()
	setup_stage_choices()


func _process(delta: float) -> void:
	_process_map_view(delta)


func _setup_map_view() -> void:
	_setup_beacon()
	_setup_location_marker()


func _process_map_view(delta: float) -> void:
	_process_beacon_frame(delta)
	_process_location_marker_frame(delta)


func _process_beacon_frame(delta: float) -> void:
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


func _process_location_marker_frame(delta: float) -> void:
	if not location_marker.visible or not _location_marker_playing:
		return
	if location_outline_frames.is_empty() or location_fill_frames.is_empty():
		return
	_location_marker_frame_elapsed += delta
	if _location_marker_frame_elapsed < LOCATION_MARKER_FRAME_DURATION:
		return
	_location_marker_frame_elapsed -= LOCATION_MARKER_FRAME_DURATION
	_location_marker_frame_index = (_location_marker_frame_index + 1) % mini(location_outline_frames.size(), location_fill_frames.size())
	_apply_location_marker_frame()


func setup_stage_choices(
	current_stage_definition: StageDefinition = null,
	current_day: int = 1,
	unlocked_high_difficulty_stage_ids: Array[int] = [],
	run_state: RunState = null
) -> void:
	if stage_choices.is_empty():
		_collect_stage_choices()
	_current_stage_definition = current_stage_definition
	_current_day = current_day
	_unlocked_high_difficulty_stage_ids = unlocked_high_difficulty_stage_ids.duplicate()
	_run_state = run_state
	_displayed_stage_definitions = _get_random_stage_definitions()
	_ensure_stage_choice_count(_displayed_stage_definitions.size())
	_hide_beacon()
	_update_location_marker()
	for i in range(stage_choices.size()):
		if i >= _displayed_stage_definitions.size():
			stage_choices[i].call("setup_choice", null)
			continue
		var stage_definition := _displayed_stage_definitions[i]
		stage_choices[i].call("setup_choice", stage_definition, _get_exploration_percent(stage_definition))


func _on_stage_choice_pressed(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	if stage_definition == null:
		return
	stage_selected.emit(stage_definition)


func _on_stage_choice_hovered(choice_index: int) -> void:
	if choice_index >= _displayed_stage_definitions.size():
		_show_map_hover(null)
		return
	var stage_definition := _displayed_stage_definitions[choice_index]
	_show_map_hover(stage_definition)


func _show_map_hover(stage_definition: StageDefinition) -> void:
	if stage_definition == null:
		_hide_beacon()
		return
	_hovered_stage_definition = stage_definition
	if _is_current_location(stage_definition):
		_hide_beacon()
		_play_location_marker()
		return
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
	return stage_selection_service.get_stage_definition_by_id(_get_stage_definitions(), stage_id)


func get_stage_definitions_for_progress() -> Array[StageDefinition]:
	return _get_stage_definitions()


func _get_random_stage_definitions() -> Array[StageDefinition]:
	var definitions := stage_selection_service.get_candidate_stages(
		_get_stage_definitions(),
		_current_stage_definition,
		_current_day,
		_unlocked_high_difficulty_stage_ids
	)
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
	var was_visible := beacon.visible
	beacon.position = map_position
	beacon.visible = true
	_pause_location_marker()
	if not was_visible:
		_start_beacon_animation()


func _hide_beacon() -> void:
	_hovered_stage_definition = null
	beacon.visible = false
	beacon.scale = Vector2.ONE
	if _beacon_tween != null and _beacon_tween.is_valid():
		_beacon_tween.kill()
	_play_location_marker()


func _start_beacon_animation() -> void:
	if _beacon_tween != null and _beacon_tween.is_valid():
		return
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


func _setup_location_marker() -> void:
	location_marker.visible = false
	location_marker.scale = Vector2.ONE
	location_marker_outline.self_modulate = _get_background_color()
	location_marker_fill.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	if not location_outline_frames.is_empty():
		location_marker_outline.texture = location_outline_frames[0]
	elif location_outline_texture != null:
		location_marker_outline.texture = location_outline_texture
	if not location_fill_frames.is_empty():
		location_marker_fill.texture = location_fill_frames[0]
	elif location_fill_texture != null:
		location_marker_fill.texture = location_fill_texture


func _update_location_marker() -> void:
	if _current_stage_definition == null:
		location_marker.visible = false
		_location_marker_playing = false
		return
	location_marker.position = _current_stage_definition.map_position
	location_marker.visible = true
	_reset_location_marker_frame()
	_play_location_marker()


func _pause_location_marker() -> void:
	_location_marker_playing = false
	_reset_location_marker_frame()


func _play_location_marker() -> void:
	if not location_marker.visible:
		return
	_location_marker_playing = true


func _reset_location_marker_frame() -> void:
	_location_marker_frame_index = 0
	_location_marker_frame_elapsed = 0.0
	_apply_location_marker_frame()


func _apply_location_marker_frame() -> void:
	if not location_outline_frames.is_empty():
		location_marker_outline.texture = location_outline_frames[_location_marker_frame_index % location_outline_frames.size()]
	if not location_fill_frames.is_empty():
		location_marker_fill.texture = location_fill_frames[_location_marker_frame_index % location_fill_frames.size()]


func _is_current_location(stage_definition: StageDefinition) -> bool:
	if _current_stage_definition == null or stage_definition == null:
		return false
	if stage_definition == _current_stage_definition:
		return true
	return stage_definition.map_position.distance_squared_to(_current_stage_definition.map_position) < 0.01


func _get_exploration_percent(stage_definition: StageDefinition) -> int:
	if _run_state == null:
		return 0
	return _run_state.get_stage_exploration_percent(stage_definition)
