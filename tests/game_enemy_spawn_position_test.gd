extends SceneTree

var _failures := 0


func _initialize() -> void:
	var original: Array[Vector2i] = [Vector2i(2, 2)]
	var candidates := GameEnemySetupController._get_nearby_spawn_cells(original, 5, 5)
	var expected: Array[Vector2i] = [
		Vector2i(2, 2),
		Vector2i(1, 2),
		Vector2i(2, 1),
		Vector2i(3, 2),
		Vector2i(2, 3),
		Vector2i(0, 2),
		Vector2i(2, 0),
		Vector2i(4, 2),
		Vector2i(2, 4),
	]
	_expect(candidates.slice(0, expected.size()) == expected, "元のマスと各軸の近傍を指定順で探索する")
	_expect(candidates.size() == 25, "軸上に空きがなくても盤面の全マスを探索する")
	_expect(candidates.has(Vector2i(1, 1)), "斜めの近傍も候補に含める")
	_test_spawn_request_keeps_source_cells()
	quit(_failures)


func _test_spawn_request_keeps_source_cells() -> void:
	var source := Enemy.new()
	source.stomach_cell = Vector2i(2, 2)
	var queue := EnemySpawnQueue.new()
	queue.request(source, EnemyEffect.new(), null, null, 1, 0, EnemyEffect.SpawnArea.SAME_CELLS, 1, 1, false)
	source.stomach_cell = Vector2i.ZERO
	var requests := queue.consume()
	_expect(requests.size() == 1, "生成要求を追加する")
	if requests.size() == 1:
		_expect(requests[0].source_cells[0] == Vector2i(2, 2), "元悪夢が再利用されても消化時の位置を保持する")
	source.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemySpawnPositionTest: %s" % message)
