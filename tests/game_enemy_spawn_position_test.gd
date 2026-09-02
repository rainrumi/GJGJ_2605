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
	_test_spawn_effect_defaults()
	_test_rtg_spawn_areas()
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


func _test_spawn_effect_defaults() -> void:
	var effects: Array[EnemyEffect] = [
		EnemyEffectOnDamageSpawnEnemy.new(),
		EnemyEffectOnAcidDamageSpawnEnemy.new(),
		EnemyEffectOnProgressTimeSpawnEnemy.new(),
	]
	for effect in effects:
		_expect(
			effect.get("spawn_area") == EnemyEffect.SpawnArea.SAME_CELLS,
			"生成効果の通常設定は生成元セルを基準にする: %s" % effect.get_script().resource_path
		)


func _test_rtg_spawn_areas() -> void:
	var paths: Array[String] = [
		"res://data/resources/area/area_riran/enemy/normal/004/area_riran_enemy_normal_004_001.tres",
		"res://data/resources/area/area_riran/enemy/normal/004/area_riran_enemy_normal_004_002.tres",
		"res://data/resources/area/area_riran/enemy/normal/005/area_riran_enemy_normal_005_001.tres",
		"res://data/resources/area/area_riran/enemy/normal/005/area_riran_enemy_normal_005_002.tres",
	]
	for path in paths:
		var info := load(path) as EnemyInfo
		var effect := info.main_skill.effects[0] as EnemyEffectOnDigestedSpawnEnemy
		_expect(
			effect.spawn_area == EnemyEffect.SpawnArea.SAME_CELLS,
			"生成元セルを基準にする: %s" % path
		)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemySpawnPositionTest: %s" % message)
