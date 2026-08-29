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
	game.call("_play_attack_se_for_digested_enemies", [enemy])
	_expect(attack_se.playing, "悪夢が消化されたときAttackSeを再生する")

	attack_se.stop()
	var seed_block := Enemy.new()
	seed_block.seed_info = SeedInfo.new()
	game.call("_play_attack_se_for_digested_enemies", [seed_block])
	_expect(not attack_se.playing, "夢種ブロックの消化ではAttackSeを再生しない")

	game.queue_free()
	quit(1 if _failed else 0)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error("GameEnemyDigestedSeTest: %s" % message)
