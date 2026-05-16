class_name PassiveFlowerSpawner
extends Node2D

const ROW_CAPACITY := 10
const FLOWER_SPACING := 10.0
const ROW_SPACING := 10.0
const FIRST_ROW_ORIGIN := Vector2(320.0, 44.0)


func setup_flowers(flowers: Array) -> void:
	_clear_flowers()
	var flower_definitions := _get_valid_flowers(flowers)
	var display_flowers := _create_display_flowers(flower_definitions)
	for i in range(display_flowers.size()):
		var flower := display_flowers[i]
		flower.position = _get_flower_position(i, display_flowers.size())
		flower.z_index = i
		add_child(flower)


func _clear_flowers() -> void:
	for child in get_children():
		child.queue_free()


func _get_valid_flowers(flowers: Array) -> Array[FlowerDefinition]:
	var valid_flowers: Array[FlowerDefinition] = []
	for flower in flowers:
		if flower is FlowerDefinition:
			valid_flowers.append(flower as FlowerDefinition)
	return valid_flowers


func _create_display_flowers(flower_definitions: Array[FlowerDefinition]) -> Array[Node2D]:
	var display_flowers: Array[Node2D] = []
	for flower_definition in flower_definitions:
		var texture := _get_flower_texture(flower_definition)
		if texture == null:
			continue
		display_flowers.append(_create_flower(texture))
	return display_flowers


func _create_flower(texture: Texture2D) -> Node2D:
	var flower := Node2D.new()
	flower.name = "PassiveFlowerItem"
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = Color.WHITE
	sprite.self_modulate = Color(0.9411765, 0.8784314, 1.0, 1.0)
	flower.add_child(sprite)
	return flower


func _get_flower_texture(flower_definition: FlowerDefinition) -> Texture2D:
	if flower_definition.dream_seed_skill == null:
		return null
	return flower_definition.dream_seed_skill.texture


func _get_flower_position(index: int, total_count: int) -> Vector2:
	var row := int(index / ROW_CAPACITY)
	var column := index % ROW_CAPACITY
	var row_start := row * ROW_CAPACITY
	var row_count := mini(ROW_CAPACITY, total_count - row_start)
	var row_origin := FIRST_ROW_ORIGIN + Vector2(0.0, -ROW_SPACING * row)
	var row_width := float(row_count - 1) * FLOWER_SPACING
	var x_offset := float(column) * FLOWER_SPACING - row_width * 0.5
	return row_origin + Vector2(x_offset, 0.0)
