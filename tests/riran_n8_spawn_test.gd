extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var info := load("res://data/resources/area/area_riran/enemy/normal/008/area_riran_enemy_normal_008_001.tres") as EnemyInfo
	_expect(info != null, "リランN-8のE1を読み込める")
	if info == null:
		quit(_failures)
		return
	var source := Enemy.new()
	source.data.setup(info, 480, 16, true, true)
	source.set_stomach_cell(Vector2i(1, 1))
	source.set_Aciding(true)
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnDamageSpawnEnemy
	_expect(effect != null, "E1は被弾時に寄生型悪夢を生成する")
	if effect == null:
		source.free()
		quit(_failures)
		return
	_expect(effect.spawn_count == 1 and effect.max_spawn_count == 4, "被弾ごとに1体、累計4体を生成する")
	_expect(effect.spawn_area == EnemyEffect.SpawnArea.EMPTY_ADJACENT, "上下左右の空き隣接マスへ生成する")
	var queue := EnemySpawnQueue.new()
	effect.bind_source(source)
	effect.setup_spawn_queue(queue)
	var board := StomachBoard.new()
	board.columns = 5
	board.rows = 5
	var controller := GameEnemySetupController.new()
	controller.setup(null, null, board)
	var enemies: Array[Enemy] = [source]
	var spawned_enemies: Array[Enemy] = []
	for hit in range(5):
		effect.apply()
		var requests := queue.consume()
		_expect(requests.size() == (1 if hit < 4 else 0), "被弾%d回目の生成要求" % (hit + 1))
		if requests.is_empty():
			continue
		var request := requests[0]
		_expect(request.max_hp == 160 and request.damage == 6, "寄生型悪夢のHPと攻撃力を保持する")
		var cell := controller._find_spawn_cell(source, request, enemies, [Vector2i.ZERO])
		_expect(not request.source_cells.has(cell), "生成位置は元の悪夢と重ならない")
		var adjacent := false
		for source_cell in request.source_cells:
			if absi(source_cell.x - cell.x) + absi(source_cell.y - cell.y) == 1:
				adjacent = true
		_expect(adjacent, "生成位置は元の悪夢に上下左右で隣接する")
		source.set_Acided(true)
		_expect(not request.source_cells.has(controller._find_spawn_cell(source, request, enemies, [Vector2i.ZERO])), "元の悪夢が消化済みでも占有マスへ生成しない")
		source.set_Acided(false)
		source.set_Aciding(true)
		var spawned := Enemy.new()
		spawned.data.setup(effect.enemy_info, 160, 6, true, true)
		spawned.set_stomach_cell(cell)
		spawned.set_Aciding(true)
		spawned_enemies.append(spawned)
		enemies.append(spawned)
	_expect(spawned_enemies.size() == 4, "4回の被弾で重ならない4マスへ生成できる")
	for spawned in spawned_enemies:
		spawned.free()
	board.free()
	source.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranN8SpawnTest: %s" % message)
