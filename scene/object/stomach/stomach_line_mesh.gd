@tool
class_name StomachLineMesh
extends MeshInstance2D

@export var size := Vector2(153.0, 10.0)
@export var texture_size := Vector2(156.0, 44.0)
@export var line_texture_size := Vector2(6.0, 6.0)
@export var patch_margin_left := 8.0
@export var patch_margin_top := 2.0
@export var patch_margin_right := 8.0
@export var patch_margin_bottom := 8.0
@export_range(1, 64, 1) var horizontal_segments := 32

var _last_build_signature := ""


func _ready() -> void:
	_rebuild_mesh()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_rebuild_mesh_if_needed()


func _rebuild_mesh_if_needed() -> void:
	var signature := "%s|%s|%s|%s|%s|%s|%s|%s" % [
		size,
		texture_size,
		line_texture_size,
		patch_margin_left,
		patch_margin_top,
		patch_margin_right,
		patch_margin_bottom,
		horizontal_segments,
	]
	if signature == _last_build_signature:
		return
	_last_build_signature = signature
	_rebuild_mesh()


func _rebuild_mesh() -> void:
	if not is_inside_tree():
		return
	_update_shader_parameters()
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var x_positions := _get_x_positions()
	var y_positions := _get_y_positions()
	for y in y_positions:
		for x in x_positions:
			vertices.append(Vector2(x, y))
			uvs.append(Vector2(_get_source_x(x), _get_source_y(y)) / texture_size)
	var column_count := x_positions.size()
	for row in range(y_positions.size() - 1):
		for column in range(column_count - 1):
			var top_left := row * column_count + column
			var top_right := top_left + 1
			var bottom_left := top_left + column_count
			var bottom_right := bottom_left + 1
			indices.append(top_left)
			indices.append(bottom_left)
			indices.append(top_right)
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(bottom_right)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh


func set_line_rect(line_position: Vector2, line_size: Vector2) -> void:
	position = line_position.round()
	size = line_size.round()
	scale = Vector2.ONE
	_rebuild_mesh()


func _update_shader_parameters() -> void:
	if material is ShaderMaterial:
		var shader_material := material as ShaderMaterial
		shader_material.set_shader_parameter("mesh_size", size)
		shader_material.set_shader_parameter("line_texture_size", line_texture_size)


func _get_x_positions() -> PackedFloat32Array:
	var positions := PackedFloat32Array()
	positions.append(0.0)
	var left_width := minf(patch_margin_left, size.x * 0.5)
	var right_width := minf(patch_margin_right, size.x - left_width)
	positions.append(left_width)
	var center_start := left_width
	var center_end := maxf(center_start, size.x - right_width)
	for i in range(1, horizontal_segments):
		positions.append(lerpf(center_start, center_end, float(i) / float(horizontal_segments)))
	positions.append(center_end)
	positions.append(size.x)
	return _get_unique_sorted_positions(positions)


func _get_y_positions() -> PackedFloat32Array:
	var positions := PackedFloat32Array()
	positions.append(0.0)
	var top_height := minf(patch_margin_top, size.y * 0.5)
	var bottom_height := minf(patch_margin_bottom, size.y - top_height)
	positions.append(top_height)
	positions.append(maxf(top_height, size.y - bottom_height))
	positions.append(size.y)
	return _get_unique_sorted_positions(positions)


func _get_unique_sorted_positions(values: PackedFloat32Array) -> PackedFloat32Array:
	var sorted: Array[float] = []
	for value in values:
		sorted.append(value)
	sorted.sort()
	var result := PackedFloat32Array()
	for value in sorted:
		if result.is_empty() or not is_equal_approx(result[result.size() - 1], value):
			result.append(value)
	return result


func _get_source_x(local_x: float) -> float:
	var left_width := minf(patch_margin_left, size.x * 0.5)
	var right_width := minf(patch_margin_right, size.x - left_width)
	var center_start := left_width
	var center_end := maxf(center_start, size.x - right_width)
	if local_x <= left_width:
		return local_x
	if local_x >= center_end:
		return texture_size.x - (size.x - local_x)
	return lerpf(patch_margin_left, texture_size.x - patch_margin_right, _get_center_ratio(local_x, center_start, center_end))


func _get_source_y(local_y: float) -> float:
	var top_height := minf(patch_margin_top, size.y * 0.5)
	var bottom_height := minf(patch_margin_bottom, size.y - top_height)
	var center_start := top_height
	var center_end := maxf(center_start, size.y - bottom_height)
	if local_y <= top_height:
		return local_y
	if local_y >= center_end:
		return texture_size.y - (size.y - local_y)
	return lerpf(patch_margin_top, texture_size.y - patch_margin_bottom, _get_center_ratio(local_y, center_start, center_end))


func _get_center_ratio(value: float, start: float, end: float) -> float:
	if is_equal_approx(start, end):
		return 0.0
	return clampf((value - start) / (end - start), 0.0, 1.0)
