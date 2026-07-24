extends SceneTree

const HP_VALUE_POPUP_WAIT_SECONDS := 0.9

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
	context.starting_hp = 20
	context.enemy_preset = preset
	game.call("start_battle", context)
	await process_frame
	await create_timer(HP_VALUE_POPUP_WAIT_SECONDS).timeout
	await process_frame

	var battle_ui := game.get_node("UI")
	var hp_view := game.get_node("UI/HpView") as HpView
	var damage_values: Array[int] = [20]
	battle_ui.call("show_hp_damage_values", damage_values)
	game.set("hp", 0)
	game.call("_apply_elapsed_time", 30)
	var damage_popup := _find_hp_value_popup(hp_view, "-20")
	var recovery_popup := _find_recovery_popup(hp_view, "+10")
	_expect(game.call("get_current_hp") == 10, "HPが0になった後に最大HPの10%で復活する")
	_expect(damage_popup != null and damage_popup.visible, "悪夢のダメージUIを表示する")
	_expect(recovery_popup != null, "復活時の回復UIを生成する")
	if damage_popup != null and recovery_popup != null:
		_expect(recovery_popup.visible, "ダメージUIと復活時の回復UIを同時に表示する")
		_expect(
			damage_popup.global_position.y + damage_popup.size.y
			<= recovery_popup.global_position.y,
			"ダメージUIの下に復活時の回復UIを並べる"
		)
		_expect(
			recovery_popup.global_position.y + recovery_popup.size.y
			<= hp_view.global_position.y,
			"復活時の回復UIをHPバーより上に配置する"
		)
	await create_timer(HP_VALUE_POPUP_WAIT_SECONDS).timeout
	await process_frame
	_expect(not is_instance_valid(damage_popup), "既存テンポでダメージUIを解放する")
	_expect(not is_instance_valid(recovery_popup), "既存テンポで復活時の回復UIを解放する")

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _find_recovery_popup(hp_view: HpView, expected_text: String) -> Label:
	return _find_hp_value_popup(hp_view, expected_text)


func _find_hp_value_popup(hp_view: HpView, expected_text: String) -> Label:
	for child in hp_view.find_children("*", "Label", true, false):
		if (child as Label).text == expected_text:
			return child as Label
	return null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HpReviveRecoveryPopupTest: %s" % message)
