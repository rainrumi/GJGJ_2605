extends SceneTree

const START_CELL := Vector2i(2, 3)
const GENERATION_COUNT := 4
const GENERATED_HP: Array[int] = [48, 32, 16]
const PRESET_PATH := (
	"res://data/resources/area/area_riran/enemy/normal/004/"
	+ "area_riran_enemy_normal_preset_004.tres"
)

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scene/main/game/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var context := BattleInfo.new()
	context.enemy_preset = load(PRESET_PATH) as EnemyPresetInfo
	game.start_battle(context)
	var enemies: Array[Enemy] = game.enemies
	var stomach := game.stomach as StomachBoard
	var source := enemies[0]
	var generation_stopped := false
	source.set_Aciding(true)
	stomach.place_enemy(source, START_CELL)

	for generation in range(GENERATION_COUNT):
		var source_data: Array[EnemyData] = [source.data]
		source.set_Acided(true)
		source.data.stomach_status.publish_digestion(1, 0, 60, 60, source_data)
		game.enemy_effects.execute()
		var requests: Array[BattleSpawnEnemyData] = game.enemy_effects.consume_spawns()
		if generation == GENERATED_HP.size():
			_expect(requests.is_empty(), "生成HPが0のE2は生成要求を作らない")
			_expect(_find_active_e2(enemies) == null, "生成HPが0のE2は生成されない")
			generation_stopped = requests.is_empty()
			break
		_expect(requests.size() == 1, "生成要求が1件ある: 世代%d" % generation)
		if requests.is_empty():
			break
		_expect(requests[0].source_cells.has(START_CELL), "生成要求が生成元セルを保持する: 世代%d" % generation)
		game.call("_apply_acid_spawn_requests", requests)
		requests.clear()
		source = _find_active_e2(enemies)
		_expect(source != null, "E2が生成される: 世代%d" % generation)
		if source == null:
			break
		_expect(source.stomach_cell == START_CELL, "E2が生成元セルへ生成される: 世代%d" % generation)
		_expect(source.get_current_hp() == GENERATED_HP[generation], "E2の生成HPが正しい: 世代%d" % generation)
		await create_timer(Enemy.AcidED_TWEEN_DURATION + 0.05).timeout
	_expect(generation_stopped, "HP0でE2の連鎖生成を停止する")

	game.cancel_battle()
	game.enemy_effects.reset()
	root.remove_child(game)
	game.free()
	enemies.clear()
	source = null
	stomach = null
	context = null
	game = null
	await process_frame
	quit(_failures)


func _find_active_e2(enemies: Array[Enemy]) -> Enemy:
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach() and enemy.get_display_name() == "E2":
			return enemy
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RtgN4SpawnPositionTest: %s" % message)
