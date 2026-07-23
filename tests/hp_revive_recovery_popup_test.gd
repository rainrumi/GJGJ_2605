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

	var enemy_info := EnemyInfo.new()
	enemy_info.acid_block = AcidBlockInfo.new()
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [enemy_info]
	preset.enemies = enemy_infos
	var context := BattleInfo.new()
	context.starting_hp = 100
	context.enemy_preset = preset
	game.call("start_battle", context)
	await process_frame

	game.set("hp", 0)
	game.call("_apply_elapsed_time", 30)
	var hp_view := game.get_node("UI/HpView") as HpView
	var recovery_popup := _find_recovery_popup(hp_view, "+10")
	_expect(game.call("get_current_hp") == 10, "HPが0になった後に最大HPの10%で復活する")
	_expect(recovery_popup != null, "復活時の回復UIをHPバーの上に表示する")
	if recovery_popup != null:
		_expect(
			recovery_popup.position.y + recovery_popup.size.y <= 0.0,
			"復活時の回復UIをHPバーより上に配置する"
		)

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _find_recovery_popup(hp_view: HpView, expected_text: String) -> Label:
	for child in hp_view.get_children():
		if child is Label and (child as Label).text == expected_text:
			return child as Label
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HpReviveRecoveryPopupTest: %s" % message)
