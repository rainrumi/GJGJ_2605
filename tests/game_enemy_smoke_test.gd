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
	_check_normal_stage_progression("area_iriyu", "イリユ")
	_check_normal_stage_progression("area_elmena", "エルメナ")
	_check_normal_stage_progression("area_lunova", "ルノヴァ")
	_check_normal_stage_progression("area_riran", "リラン")
	controller = null
	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	game = null
	packed = null
	await process_frame
	quit(_failures)


# 通常ステージ進行確認
func _check_normal_stage_progression(area_name: String, display_name: String) -> void:
	var path := "res://data/resources/area/%s/%s_enemy.tres" % [area_name, area_name]
	var enemy_data := load(path) as StageEnemyInfo
	_expect(enemy_data != null, "%sの敵編成を読み込める" % display_name)
	if enemy_data == null:
		return
	_expect(enemy_data.normal_enemy_presets.size() == 9, "%s ST1からST9を順番に登録する" % display_name)
	if enemy_data.normal_enemy_presets.size() < 2:
		return
	var run_state := RunState.new()
	var stage := StageInfo.new()
	stage.enemy_data = enemy_data
	var stage_1_preset := run_state.pick_enemy_preset(stage)
	var stage_2_preset := run_state.pick_enemy_preset(stage)
	_expect(stage_1_preset == enemy_data.normal_enemy_presets[0], "%sの初回はST1を選ぶ" % display_name)
	_expect(stage_2_preset == enemy_data.normal_enemy_presets[1], "%s ST1の次はST2を選ぶ" % display_name)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemySmokeTest: %s" % message)
