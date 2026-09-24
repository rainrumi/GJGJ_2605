extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/object/stomach/stomach.tscn") as PackedScene
	_expect(packed != null, "胃袋Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var board := packed.instantiate() as StomachBoard
	root.add_child(board)
	await process_frame

	for row_count in range(1, 6):
		board.set_grid_size(4, row_count)
		for acid_rows in range(1, row_count + 1):
			board.set_acid_line_rows(acid_rows)
			var expected_wave_local_y := (
				board._get_row_top_y(maxi(0, row_count - acid_rows))
				- board.frame.position.y
				+ 5.0
			)
			var material := board.line_mesh.material as ShaderMaterial
			_expect(
				board.line_mesh.position == board.frame.position,
				"胃袋%d行、消化%d行: ラインメッシュ位置がframeに一致" % [row_count, acid_rows]
			)
			_expect(
				board.line_mesh.size == board.frame.size,
				"胃袋%d行、消化%d行: ラインメッシュサイズがframeに一致" % [row_count, acid_rows]
			)
			_expect(
				is_equal_approx(
					_find_local_y_for_shader_y(
						board.line_mesh,
						material.get_shader_parameter("wave_base_y")
					),
					expected_wave_local_y
				),
				"胃袋%d行、消化%d行: shaderの波線位置が消化行上端と一致" % [row_count, acid_rows]
			)

	if _failures == 0:
		print("stomach_line_mesh_resize_test: PASS")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("stomach_line_mesh_resize_test: %s" % message)


func _find_local_y_for_shader_y(line_mesh: StomachLineMesh, shader_y: float) -> float:
	var low := 0.0
	var high := line_mesh.size.y
	for iteration in range(40):
		var mid := (low + high) * 0.5
		if line_mesh.get_shader_y_for_local_y(mid) < shader_y:
			low = mid
		else:
			high = mid
	return (low + high) * 0.5
