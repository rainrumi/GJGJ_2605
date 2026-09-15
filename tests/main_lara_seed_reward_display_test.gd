extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	var main := packed.instantiate()
	get_tree().root.add_child(main)
	await get_tree().process_frame

	var overlay := main.get_node("SeedRewardOverlay") as CanvasLayer
	var choice := main.get_node("SeedRewardOverlay/SeedChoice") as StageClearSeedChoice
	var seed := load("res://data/resources/seeds/skills/seed_100_101.tres") as SeedInfo
	main.call("_show_seed_reward", seed)
	_expect(overlay.visible, "夢の種報酬時に表示用オーバーレイを表示する")
	_expect(choice.current_seed == seed, "報酬対象の夢の種をseed_choiceへ渡す")
	_expect(choice.disabled, "報酬表示中のseed_choiceを無効化する")
	_expect(choice.mouse_filter == Control.MOUSE_FILTER_IGNORE, "報酬表示中のseed_choiceを入力対象外にする")
	_expect(choice.position == Vector2(130, 120), "seed_choiceを画面中央の基準位置へ配置する: position=%s global=%s" % [choice.position, choice.global_position])
	_expect(is_zero_approx(choice.modulate.a), "表示開始時のalphaを0にする")
	await get_tree().create_timer(0.65).timeout
	_expect(is_equal_approx(choice.modulate.a, 1.0), "0.6秒後にalphaを255相当へ到達させる")

	main.call("_hide_seed_reward")
	_expect(not overlay.visible, "報酬文終了後に夢の種表示を隠す")
	_expect(is_zero_approx(choice.modulate.a), "非表示時のalphaを0へ戻す")

	main.queue_free()
	await get_tree().process_frame
	print("MainLaraSeedRewardDisplayTest: %d failures" % _failures)
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
