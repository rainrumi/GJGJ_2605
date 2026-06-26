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


# 初期化
func _ready() -> void:
	_rebuild_mesh()


# 毎フレーム処理
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_rebuild_mesh_if_needed()


# rebuildmeshifneede処理
func _rebuild_mesh_if_needed() -> void:
	# signature
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


# rebuildmesh処理
func _rebuild_mesh() -> void:
	if not is_inside_tree():
		return
	_update_shader_parameters()
	# vertices
	var vertices := PackedVector2Array()
	# uvs
	var uvs := PackedVector2Array()
	# 番号
	var indices := PackedInt32Array()
	# xpositions
	var x_positions := _get_x_positions()
	# ypositions
	var y_positions := _get_y_positions()
	for y in y_positions:
		for x in x_positions:
			vertices.append(Vector2(x, y))
			uvs.append(Vector2(_get_source_x(x), _get_source_y(y)) / texture_size)
	# 列数
	var column_count := x_positions.size()
	for row in range(y_positions.size() - 1):
		for column in range(column_count - 1):
			# topleft
			var top_left := row * column_count + column
			# topright
			var top_right := top_left + 1
			# bottomleft
			var bottom_left := top_left + column_count
			# bottomright
			var bottom_right := bottom_left + 1
			indices.append(top_left)
			indices.append(bottom_left)
			indices.append(top_right)
			indices.append(top_right)
			indices.append(bottom_left)
			indices.append(bottom_right)
	# arrays
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	# arraymesh
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh = array_mesh


# 列rect設定
func set_line_rect(line_position: Vector2, line_size: Vector2) -> void:
	position = line_position.round()
	size = line_size.round()
	scale = Vector2.ONE
	_rebuild_mesh()


# shaderparameters更新
func _update_shader_parameters() -> void:
	if material is ShaderMaterial:
		# shadermaterial
		var shader_material := material as ShaderMaterial
		shader_material.set_shader_parameter("mesh_size", size)
		shader_material.set_shader_parameter("line_texture_size", line_texture_size)


# xpositions取得
func _get_x_positions() -> PackedFloat32Array:
	# positions
	var positions := PackedFloat32Array()
	positions.append(0.0)
	# left幅
	var left_width := minf(patch_margin_left, size.x * 0.5)
	# right幅
	var right_width := minf(patch_margin_right, size.x - left_width)
	positions.append(left_width)
	# centerstart
	var center_start := left_width
	# centerend
	var center_end := maxf(center_start, size.x - right_width)
	for i in range(1, horizontal_segments):
		positions.append(lerpf(center_start, center_end, float(i) / float(horizontal_segments)))
	positions.append(center_end)
	positions.append(size.x)
	return _get_unique_sorted_positions(positions)


# ypositions取得
func _get_y_positions() -> PackedFloat32Array:
	# positions
	var positions := PackedFloat32Array()
	positions.append(0.0)
	# top高さ
	var top_height := minf(patch_margin_top, size.y * 0.5)
	# bottom高さ
	var bottom_height := minf(patch_margin_bottom, size.y - top_height)
	positions.append(top_height)
	positions.append(maxf(top_height, size.y - bottom_height))
	positions.append(size.y)
	return _get_unique_sorted_positions(positions)


# sortedpositions取得
func _get_unique_sorted_positions(values: PackedFloat32Array) -> PackedFloat32Array:
	# sorted
	var sorted: Array[float] = []
	for value in values:
		sorted.append(value)
	sorted.sort()
	# 結果
	var result := PackedFloat32Array()
	for value in sorted:
		if result.is_empty() or not is_equal_approx(result[result.size() - 1], value):
			result.append(value)
	return result


# 元データx取得
func _get_source_x(local_x: float) -> float:
	# left幅
	var left_width := minf(patch_margin_left, size.x * 0.5)
	# right幅
	var right_width := minf(patch_margin_right, size.x - left_width)
	# centerstart
	var center_start := left_width
	# centerend
	var center_end := maxf(center_start, size.x - right_width)
	if local_x <= left_width:
		return local_x
	if local_x >= center_end:
		return texture_size.x - (size.x - local_x)
	return lerpf(patch_margin_left, texture_size.x - patch_margin_right, _get_center_ratio(local_x, center_start, center_end))


# 元データy取得
func _get_source_y(local_y: float) -> float:
	# top高さ
	var top_height := minf(patch_margin_top, size.y * 0.5)
	# bottom高さ
	var bottom_height := minf(patch_margin_bottom, size.y - top_height)
	# centerstart
	var center_start := top_height
	# centerend
	var center_end := maxf(center_start, size.y - bottom_height)
	if local_y <= top_height:
		return local_y
	if local_y >= center_end:
		return texture_size.y - (size.y - local_y)
	return lerpf(patch_margin_top, texture_size.y - patch_margin_bottom, _get_center_ratio(local_y, center_start, center_end))


# center比率取得
func _get_center_ratio(value: float, start: float, end: float) -> float:
	if is_equal_approx(start, end):
		return 0.0
	return clampf((value - start) / (end - start), 0.0, 1.0)
