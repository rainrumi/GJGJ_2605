extends SceneTree

var _failed := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	var attack_se := game.get_node("AttackSe") as AudioStreamPlayer
	var enemies: Array[Enemy] = game.get("enemies")
	var enemy := enemies[0]
	enemy.take_acid_damage(1)
	_expect(attack_se.playing, "悪夢がダメージを受けたときAttackSeを再生する")

	attack_se.stop()
	var seed_block_packed := load("res://scene/object/enemy/enemy.tscn") as PackedScene
	var seed_block := seed_block_packed.instantiate() as Enemy
	game.add_child(seed_block)
	var seed_info := SeedInfo.new()
	seed_info.acid_block = AcidBlockInfo.new()
	seed_info.acid_block.max_hp = 2
	seed_block.setup_seed(seed_info, Vector2.ONE)
	seed_block.take_acid_damage(1)
	_expect(not attack_se.playing, "同一タイミングで複数対象が被弾してもAttackSeを重複再生しない")

	await process_frame
	seed_block.take_acid_damage(1)
	_expect(attack_se.playing, "夢の種ブロックがダメージを受けたときAttackSeを再生する")

	await process_frame
	attack_se.stop()
	var player_damage_values: Array[int] = [1]
	game.call("_apply_player_damage", player_damage_values)
	_expect(attack_se.playing, "プレイヤーがダメージを受けたときAttackSeを再生する")

	game.queue_free()
	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("GameEnemyDigestedSeTest: %s" % message)
