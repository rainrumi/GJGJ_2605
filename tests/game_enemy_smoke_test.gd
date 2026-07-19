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
	_check_strengthened_stage_progression()
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
	var retry_stage_1_preset := run_state.pick_enemy_preset(stage)
	run_state.record_stage_clear(stage)
	var stage_2_preset := run_state.pick_enemy_preset(stage)
	_expect(stage_1_preset == enemy_data.normal_enemy_presets[0], "%sの初回はST1を選ぶ" % display_name)
	_expect(retry_stage_1_preset == enemy_data.normal_enemy_presets[0], "%s ST1未クリアの再挑戦はST1を選ぶ" % display_name)
	_expect(stage_2_preset == enemy_data.normal_enemy_presets[1], "%s ST1クリア後はST2を選ぶ" % display_name)


# 強化ステージ進行確認
func _check_strengthened_stage_progression() -> void:
	var enemy_data := load("res://data/resources/area/area_elmena/area_elmena_enemy.tres") as StageEnemyInfo
	_expect(enemy_data != null, "強化敵編成を読み込める")
	if enemy_data == null or enemy_data.strengthened_enemy_presets.size() < 2:
		return
	var run_state := RunState.new()
	run_state.current_day = 8
	var stage := StageInfo.new()
	stage.is_high_difficulty = true
	stage.enemy_data = enemy_data
	var strengthened_1_preset := run_state.pick_enemy_preset(stage)
	var retry_strengthened_1_preset := run_state.pick_enemy_preset(stage)
	run_state.record_stage_clear(stage)
	var strengthened_2_preset := run_state.pick_enemy_preset(stage)
	_expect(strengthened_1_preset == enemy_data.strengthened_enemy_presets[0], "強化ステージの初回は強化ST1を選ぶ")
	_expect(retry_strengthened_1_preset == enemy_data.strengthened_enemy_presets[0], "強化ST1未クリアの再挑戦は強化ST1を選ぶ")
	_expect(strengthened_2_preset == enemy_data.strengthened_enemy_presets[1], "強化ST1クリア後は強化ST2を選ぶ")


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemySmokeTest: %s" % message)
