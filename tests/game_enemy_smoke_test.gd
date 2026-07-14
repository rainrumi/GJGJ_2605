extends SceneTree

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 戦闘起動試験
func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene # 戦闘シーン
	_expect(packed != null, "戦闘シーンを読める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate() # 戦闘画面
	root.add_child(game)
	await process_frame
	game.call("start_battle", BattleInfo.new())
	await process_frame
	var controller := game.get("acid_controller") as EnemyController # 敵調整役
	_expect(controller != null, "EnemyControllerを構成する")
	_expect(controller.digestion_resolver != null, "消化Resolverを注入する")
	_expect(controller.attack_resolver != null, "攻撃Resolverを注入する")
	_expect(controller.turn_processor != null, "TurnProcessorを注入する")
	controller = null
	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	game = null
	packed = null
	await process_frame
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemySmokeTest: %s" % message)
