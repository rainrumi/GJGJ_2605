extends Node

const LUNOVA_N6_PRESET := "res://data/resources/area/area_lunova/enemy/normal/006/area_lunova_enemy_normal_preset_006.tres"
const YUGAO_PATH := "res://data/resources/seeds/skills/seed_100_115.tres"
const LUPINUS_PATH := "res://data/resources/seeds/skills/seed_100_116.tres"

var _checks := 0
var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scene/main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game._initial_tutorial_played = true
	game._owned_seed_tutorial_played = true
	await _test_yugao_drag(game, true)
	await _test_yugao_drag(game, false)
	await _test_lupinus_drag(game)
	_test_placement_revalidates_every_object(game)
	game.enemy_effects.reset()
	game.attack_se.stop()
	game.queue_free()
	await get_tree().process_frame
	print("GameStomachBoundsTest: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)


func _test_yugao_drag(game: Node, cancel: bool) -> void:
	var seed := load(YUGAO_PATH) as SeedInfo
	var context := BattleInfo.new()
	context.flowers = [seed]
	context.enemy_preset = load(LUNOVA_N6_PRESET) as EnemyPresetInfo
	game.start_battle(context)
	await get_tree().process_frame
	var wide: Enemy = game.enemies[0]
	_expect(wide.get_stomach_size().x == 5 and game.stomach.columns == 5, "LOC-N-6の横5マスのE1とユウガオを使用する")
	wide.set_Aciding(true)
	game.stomach.place_enemy(wide, Vector2i(0, 2))
	var kept := _add_object(game, Vector2i.ONE, Vector2i(0, 4))
	var returned: Array[Enemy] = []
	wide.forcibly_returned.connect(_record_return.bind(wide, returned))
	kept.forcibly_returned.connect(_record_return.bind(kept, returned))
	var button := game.get_node("UI/SeedButtonList").get_child(0) as SeedButton
	game._on_seed_drag_started(button, seed, button.global_position)
	_expect(game.stomach.columns == 4, "ドラッグ中の配置予測は縮小後の横4マスを使う")
	_expect(wide.is_active_in_stomach() and returned.is_empty() and game.hp == 100, "配置確定前には嘔吐やHP消費を行わない")
	var block: Enemy = game.seed_controller._dragging_seed_block
	if cancel:
		game._on_seed_drag_released(button, seed, Vector2.ZERO)
		_expect(game.stomach.columns == 5, "ドラッグ取消後は横5マスに戻る")
		_expect(wide.is_active_in_stomach() and returned.is_empty() and game.hp == 100, "取消後もE1とHPを維持する")
	else:
		_drop_seed(game, button, seed, block, Vector2i(1, 1))
		_expect(game.stomach.columns == 4, "ユウガオの設置後は横4マスになる")
		_expect(not wide.is_active_in_stomach(), "横幅5のE1を横幅4の胃袋から強制嘔吐する")
		_expect(wide.position.is_equal_approx(wide.origin_position), "E1を胃袋外の元の位置へ戻す")
		_expect(returned == [wide], "はみ出したE1だけに強制嘔吐を1回通知する")
		_expect(kept.is_active_in_stomach() and block.is_active_in_stomach(), "収まるモノと設置したユウガオは胃袋に残す")
		_expect(game.hp == 95, "既存の嘔吐HP消費5を1回だけ適用する")
		game._refresh_after_battle_event()
		_expect(returned == [wide] and game.hp == 95, "再評価で嘔吐やHP消費を重複させない")
		_expect_contained(game)
	wide.forcibly_returned.disconnect(_record_return.bind(wide, returned))
	kept.forcibly_returned.disconnect(_record_return.bind(kept, returned))


func _test_lupinus_drag(game: Node) -> void:
	var seed := load(LUPINUS_PATH) as SeedInfo
	var context := _empty_battle_context()
	context.flowers = [seed]
	game.start_battle(context)
	await get_tree().process_frame
	_expect(game.stomach.rows == 6, "ルピナス装備時は縦6マス")
	var tall := _add_object(game, Vector2i(1, 6), Vector2i.ZERO)
	var kept := _add_object(game, Vector2i.ONE, Vector2i(1, 5))
	var returned: Array[Enemy] = []
	tall.forcibly_returned.connect(_record_return.bind(tall, returned))
	kept.forcibly_returned.connect(_record_return.bind(kept, returned))
	var button := game.get_node("UI/SeedButtonList").get_child(0) as SeedButton
	game._on_seed_drag_started(button, seed, button.global_position)
	var block: Enemy = game.seed_controller._dragging_seed_block
	_drop_seed(game, button, seed, block, Vector2i(2, 4))
	_expect(game.stomach.rows == 5, "ルピナス設置後は縦5マスになる")
	_expect(not tall.is_active_in_stomach() and returned == [tall], "上端からはみ出した縦6マスのモノだけを嘔吐する")
	_expect(kept.is_active_in_stomach() and kept.stomach_cell.y == 4, "下端基準の位置補正で収まるモノは残す")
	_expect(block.is_active_in_stomach() and block.stomach_cell.y == 4, "設置したルピナスを最下段に残す")
	_expect(game.hp == 95, "縦縮小の嘔吐にも既存HP消費5を1回適用する")
	_expect_contained(game)


func _test_placement_revalidates_every_object(game: Node) -> void:
	game.start_battle(_empty_battle_context())
	var left := _add_object(game, Vector2i.ONE, Vector2i(-1, 2))
	var bottom := _add_object(game, Vector2i.ONE, Vector2i(1, 5))
	bottom.activation_deferred = true
	var seed := load("res://data/resources/seeds/skills/seed_100_101.tres") as SeedInfo
	var flower: Enemy = game.seed_controller._create_seed_block(seed)
	game.enemies.append(flower)
	flower.set_Aciding(true)
	game.stomach.place_enemy(flower, Vector2i(4, 3))
	var kept := _add_object(game, Vector2i.ONE, Vector2i(2, 3))
	var outside := _add_object(game, Vector2i.ONE, Vector2i(-1, -1))
	outside.set_Aciding(false)
	var digested := _add_object(game, Vector2i.ONE, Vector2i(4, 5))
	digested.set_Acided(true)
	var returned: Array[Enemy] = []
	for object in [left, bottom, flower, kept, outside, digested]:
		object.forcibly_returned.connect(_record_return.bind(object, returned))
	var placed := _add_object(game, Vector2i.ONE, Vector2i(3, 4))
	placed.set_Aciding(false)
	game.hp = 5
	game.dragged_enemy_was_Aciding = false
	game._try_start_Aciding(placed, placed.global_position)
	_expect(returned.size() == 3 and returned.has(left) and returned.has(bottom) and returned.has(flower), "設置時に全モノを個別判定し、左端・下端・右端を越えた3体だけを嘔吐する")
	_expect(not left.is_active_in_stomach() and not bottom.is_active_in_stomach() and not flower.is_active_in_stomach(), "種ブロックと起動保留中のモノも範囲外なら除去する")
	_expect(kept.is_active_in_stomach() and placed.is_active_in_stomach(), "範囲内のモノと新しく設置したモノを残す")
	_expect(not returned.has(outside) and not returned.has(digested), "胃袋外・消化済みのモノは嘔吐対象にしない")
	_expect(game.hp == 10 and not game._player_revive_in_progress, "複数嘔吐中にHPが0になっても復活と処理を完了する")
	var hp_after: int = game.hp
	game._refresh_after_battle_event()
	_expect(returned.size() == 3 and game.hp == hp_after, "複数嘔吐後の再評価も重複処理しない")
	_expect_contained(game)


func _drop_seed(game: Node, button: SeedButton, seed: SeedInfo, block: Enemy, cell: Vector2i) -> void:
	game.seed_controller._drag_offset = Vector2.ZERO
	var position: Vector2 = game.stomach.get_global_position_for_cell(cell, block.get_stomach_size())
	game._on_seed_drag_moved(button, seed, position)
	var drop_cell: Vector2i = game.stomach.get_drop_cell(block, block.global_position, game.enemies)
	_expect(game.stomach.can_place(block, drop_cell, game.enemies), "種の通常ドラッグ経路で設置可能なセルを使う")
	game._on_seed_drag_released(button, seed, position)


func _empty_battle_context() -> BattleInfo:
	var info := EnemyInfo.new()
	info.acid_block = AcidBlockInfo.new()
	info.acid_block.max_hp = 10000
	var preset := EnemyPresetInfo.new()
	preset.enemies = [info]
	var context := BattleInfo.new()
	context.enemy_preset = preset
	return context


func _add_object(game: Node, size: Vector2i, cell: Vector2i) -> Enemy:
	var info := EnemyInfo.new()
	info.acid_block = AcidBlockInfo.new()
	info.acid_block.max_hp = 10000
	var object := load("res://scene/object/enemy/enemy.tscn").instantiate() as Enemy
	game.add_child(object)
	object.setup(info, Vector2.ONE, false, Vector2(500, 200))
	var shape: Array[Vector2i] = []
	for y in range(size.y):
		for x in range(size.x):
			shape.append(Vector2i(x, y))
	object.set_stomach_footprint_override(size, shape, size.x * size.y)
	game.enemies.append(object)
	object.set_Aciding(true)
	game.stomach.place_enemy(object, cell)
	return object


func _expect_contained(game: Node) -> void:
	for object: Enemy in game.enemies:
		if not object.is_active_in_stomach():
			continue
		for cell in object.get_occupied_cells(object.stomach_cell):
			_expect(cell.x >= 0 and cell.x < game.stomach.columns and cell.y >= 0 and cell.y < game.stomach.rows, "胃袋内に残る全モノの占有マスが現在の胃袋内に収まる")


func _record_return(object: Enemy, returned: Array[Enemy]) -> void:
	returned.append(object)


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("GameStomachBoundsTest: %s" % message)
