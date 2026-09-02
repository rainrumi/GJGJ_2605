extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "戦闘シーンを読める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	var context := BattleInfo.new()
	context.stomach_columns = 4
	context.stomach_rows = 5
	context.flowers = [load("res://data/resources/seeds/skills/seed_100_116.tres") as SeedInfo]
	game.call("start_battle", context)
	await process_frame

	_expect(game.call("get_stomach_rows") == 8, "ID 100116 は戦闘中の胃袋を縦に3マス増やす")
	_expect(game.call("get_base_stomach_rows") == 5, "ID 100116 の補正を基礎胃袋縦サイズへ含めない")
	_expect(game.call("get_base_stomach_columns") == 4, "縦補正は基礎胃袋横サイズへ影響しない")

	var lupinus := load("res://data/resources/seeds/skills/seed_100_116.tres") as SeedInfo
	_expect(
		StageClearCalculatorRecovery.can_receive_seed(lupinus, [lupinus]),
		"ID 100116 は同じ夢の種を植えていても追加取得できる"
	)
	context.flowers = [lupinus, lupinus]
	game.call("start_battle", context)
	await process_frame
	_expect(game.call("get_stomach_rows") == 5, "ID 100116 を複数植えると全ての縦補正が発動しない")

	context.flowers = [load("res://data/resources/seeds/skills/seed_100_115.tres") as SeedInfo]
	game.call("start_battle", context)
	await process_frame
	_expect(game.call("get_stomach_columns") == 5, "ID 100115 は戦闘中の胃袋を横に1マス増やす")
	_expect(game.call("get_base_stomach_columns") == 4, "ID 100115 の補正を基礎胃袋横サイズへ含めない")

	game.queue_free()
	await process_frame
	if _failures == 0:
		print("game_seed_stomach_base_size_test: PASS")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("game_seed_stomach_base_size_test: %s" % message)
