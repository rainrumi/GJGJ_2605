extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "ゲームSceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null

	var block := AcidBlockInfo.new()
	block.max_hp = 1000
	var enemy_info := EnemyInfo.new()
	enemy_info.acid_block = block
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [enemy_info, enemy_info]
	preset.enemies = enemy_infos
	var context := BattleInfo.new()
	context.enemy_preset = preset
	game.call("start_battle", context)
	await process_frame

	var stomach := game.get_node("Stomach") as StomachBoard
	var enemies: Array[Enemy] = game.get("enemies")
	var bottom_enemy := enemies[0]
	var falling_enemy := enemies[1]
	bottom_enemy.set_Aciding(true)
	stomach.place_enemy(bottom_enemy, Vector2i(0, stomach.rows - 1))
	falling_enemy.set_Aciding(true)
	stomach.place_enemy(falling_enemy, Vector2i(1, 0))
	var hp_before := falling_enemy.current_hp

	game.call("_on_Acidion_requested")
	await process_frame
	await process_frame
	_expect(falling_enemy.stomach_cell == Vector2i(1, stomach.rows - 1), "別列の下端にブロックがあっても初回消化前に落下する")
	_expect(falling_enemy.current_hp < hp_before, "落下後の位置で初回の消化ダメージを受ける")

	stomach.place_enemy(falling_enemy, Vector2i(1, 0))
	var hp_after_first_turn := falling_enemy.current_hp
	game.call("_advance_acid_turn")
	await process_frame
	await process_frame
	_expect(falling_enemy.stomach_cell == Vector2i(1, stomach.rows - 1), "次の消化前にも空きを走査して落下する")
	_expect(falling_enemy.current_hp < hp_after_first_turn, "次の消化も落下後の位置で判定する")

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	falling_enemy = null
	bottom_enemy = null
	enemies.clear()
	stomach = null
	context = null
	preset = null
	enemy_infos.clear()
	enemy_info = null
	block = null
	game = null
	packed = null
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameAcidGravityBeforeDigestionTest: %s" % message)
