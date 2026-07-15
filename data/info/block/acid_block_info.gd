class_name AcidBlockInfo
extends Resource

@export var max_hp := 1
@export var damage := 0
@export var texture: Texture2D
@export var stomach_shape: Array[Vector2i] = [Vector2i.ZERO]


# 最大HP取得
func get_max_hp() -> int:
	return maxi(1, max_hp)


# ダメージ取得
func get_damage() -> int:
	return maxi(0, damage)


# 胃袋形状取得
func get_stomach_shape() -> Array[Vector2i]:
	# 形状
	var shape: Array[Vector2i] = []
	for cell in stomach_shape:
		if cell is Vector2i:
			shape.append(cell)
	if shape.is_empty():
		shape.append(Vector2i.ZERO)
	return shape


# セル数取得
func get_cell_count() -> int:
	return get_stomach_shape().size()
