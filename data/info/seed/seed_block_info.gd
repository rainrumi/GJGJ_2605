class_name SeedBlockInfo
extends Resource

@export var max_hp := 1
@export var damage := 0
@export var texture: Texture2D
@export var stomach_size := Vector2i.ONE
@export var stomach_shape: Array[Vector2i] = [Vector2i.ZERO]


func get_max_hp() -> int:
	return maxi(1, max_hp)


func get_damage() -> int:
	return maxi(0, damage)


func get_stomach_size() -> Vector2i:
	return Vector2i(maxi(1, stomach_size.x), maxi(1, stomach_size.y))


func get_stomach_shape() -> Array[Vector2i]:
	var shape: Array[Vector2i] = []
	for cell in stomach_shape:
		if cell is Vector2i:
			shape.append(cell)
	if shape.is_empty():
		shape.append(Vector2i.ZERO)
	return shape


func get_cell_count() -> int:
	return get_stomach_shape().size()
