class_name Enemy
extends Node2D

const HOVER_SCALE := 1.1
const HOVER_TWEEN_DURATION := 0.1
const COST_PULSE_SCALE := 1.1
const COST_PULSE_DURATION := 0.2
const DIGESTED_SCALE := 1.2
const DIGESTED_TWEEN_DURATION := 0.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label = get_node_or_null("HPText") as Label

var definition: EnemyDefinition
var current_hp := 0
var digesting := false
var digested := false
var stomach_cell := Vector2i.ZERO
var origin_position := Vector2.ZERO

var _base_scale := Vector2.ONE
var _hover_tween: Tween
var _cost_pulse_tween: Tween
var _digested_tween: Tween
var _hovered := false


func setup(enemy_definition: EnemyDefinition, target_size: Vector2) -> void:
	definition = enemy_definition
	origin_position = enemy_definition.start_position
	position = origin_position
	if sprite != null:
		sprite.texture = enemy_definition.texture
		if enemy_definition.texture != null:
			sprite.scale = target_size / enemy_definition.texture.get_size()
			_base_scale = sprite.scale
	reset_for_battle()
	if hp_label != null:
		hp_label.pivot_offset = hp_label.size * 0.5


func reset_for_battle() -> void:
	current_hp = definition.max_hp
	digesting = false
	digested = false
	stomach_cell = Vector2i.ZERO
	visible = true
	_reset_visuals()
	return_to_origin()
	set_hovered(false)
	_update_hp_label()


func get_display_name() -> String:
	return definition.display_name


func get_damage() -> int:
	return definition.damage


func get_size() -> int:
	return definition.size


func get_stomach_size() -> Vector2i:
	return definition.stomach_size


func get_stomach_shape() -> Array[Vector2i]:
	return definition.stomach_shape


func can_drag() -> bool:
	return not digested


func is_active_in_stomach() -> bool:
	return digesting and not digested


func set_digesting(value: bool) -> void:
	digesting = value


func set_digested(value: bool) -> void:
	digested = value
	if digested:
		digesting = false
		_play_digested_tween()


func set_stomach_cell(cell: Vector2i) -> void:
	stomach_cell = cell


func return_to_origin() -> void:
	position = origin_position


func set_hovered(value: bool) -> void:
	if _hovered == value or sprite == null:
		return
	_hovered = value
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	var target_scale := _base_scale
	if _hovered:
		target_scale *= HOVER_SCALE
	_hover_tween = create_tween()
	_hover_tween.set_trans(Tween.TRANS_QUAD)
	_hover_tween.set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(sprite, "scale", target_scale, HOVER_TWEEN_DURATION)


func pulse_cost_label() -> void:
	if hp_label == null:
		return
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	hp_label.scale = Vector2.ONE
	_cost_pulse_tween = create_tween()
	_cost_pulse_tween.set_trans(Tween.TRANS_ELASTIC)
	_cost_pulse_tween.set_ease(Tween.EASE_OUT)
	_cost_pulse_tween.tween_property(hp_label, "scale", Vector2.ONE * COST_PULSE_SCALE, COST_PULSE_DURATION * 0.5)
	_cost_pulse_tween.tween_property(hp_label, "scale", Vector2.ONE, COST_PULSE_DURATION * 0.5)


func take_digest_damage(amount: int) -> bool:
	current_hp = maxi(0, current_hp - amount)
	_update_hp_label()
	if current_hp == 0:
		set_digested(true)
		return true
	return false


func get_global_rect() -> Rect2:
	if sprite == null or sprite.texture == null:
		return Rect2(global_position - Vector2(50.0, 50.0), Vector2(100.0, 100.0))
	var size := sprite.texture.get_size() * sprite.scale.abs()
	return Rect2(sprite.global_position - size * 0.5, size)


func get_grab_cell(mouse_position: Vector2) -> Vector2i:
	var enemy_rect := get_global_rect()
	var enemy_size := get_stomach_size()
	var relative_position := mouse_position - enemy_rect.position
	var guessed_cell := Vector2i(
		clampi(int(relative_position.x / enemy_rect.size.x * float(enemy_size.x)), 0, enemy_size.x - 1),
		clampi(int(relative_position.y / enemy_rect.size.y * float(enemy_size.y)), 0, enemy_size.y - 1)
	)
	if get_stomach_shape().has(guessed_cell):
		return guessed_cell
	return _get_nearest_shape_cell(guessed_cell)


func get_occupied_cells(top_left: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in get_stomach_shape():
		cells.append(top_left + offset)
	return cells


func get_bottom_row(top_left: Vector2i) -> int:
	var bottom_row := 0
	for cell in get_occupied_cells(top_left):
		bottom_row = maxi(bottom_row, cell.y)
	return bottom_row


func _get_nearest_shape_cell(target_cell: Vector2i) -> Vector2i:
	var nearest_cell := Vector2i.ZERO
	var nearest_distance := INF
	for offset in get_stomach_shape():
		var diff := target_cell - offset
		var distance := float(diff.x * diff.x + diff.y * diff.y)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_cell = offset
	return nearest_cell


func _play_digested_tween() -> void:
	if _digested_tween != null and _digested_tween.is_valid():
		_digested_tween.kill()
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	_hovered = false
	visible = true
	scale = Vector2.ONE
	modulate.a = 1.0
	_digested_tween = create_tween()
	_digested_tween.set_parallel(true)
	_digested_tween.set_trans(Tween.TRANS_QUART)
	_digested_tween.set_ease(Tween.EASE_OUT)
	_digested_tween.tween_property(self, "scale", Vector2.ONE * DIGESTED_SCALE, DIGESTED_TWEEN_DURATION)
	_digested_tween.tween_property(self, "modulate:a", 0.0, DIGESTED_TWEEN_DURATION)
	_digested_tween.chain().tween_callback(func() -> void: visible = false)


func _reset_visuals() -> void:
	if _hover_tween != null and _hover_tween.is_valid():
		_hover_tween.kill()
	if _cost_pulse_tween != null and _cost_pulse_tween.is_valid():
		_cost_pulse_tween.kill()
	if _digested_tween != null and _digested_tween.is_valid():
		_digested_tween.kill()
	_hovered = false
	scale = Vector2.ONE
	modulate.a = 1.0
	if sprite != null:
		sprite.scale = _base_scale
	if hp_label != null:
		hp_label.scale = Vector2.ONE


func _update_hp_label() -> void:
	if hp_label != null:
		hp_label.text = str(current_hp)
