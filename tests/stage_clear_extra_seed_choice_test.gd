extends Node

const STAGE_CLEAR_SCENE := preload("res://scene/main/stage_clear/stage_clear.tscn")

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_clear := STAGE_CLEAR_SCENE.instantiate()
	add_child(stage_clear)
	await get_tree().process_frame

	var ui := stage_clear.ui as StageClearUi
	_expect(ui.seed_choice_list.visible, "初回の夢の種候補を表示する")
	_expect(not ui.more_select.visible, "初回は追加選択メッセージを表示しない")

	var area_seeds: Array[SeedInfo] = [SeedInfo.new(), SeedInfo.new(), SeedInfo.new()]
	var area_pool := SeedPoolInfo.new()
	area_pool.common_skills = area_seeds
	var cleared_stage := StageInfo.new()
	cleared_stage.drop_seed_pool = area_pool
	stage_clear.set("_current_clear_stage", cleared_stage)
	stage_clear.seed_options.assign([SeedInfo.new(), SeedInfo.new(), SeedInfo.new()])
	stage_clear.set("_remaining_extra_seed_choices", 1)
	stage_clear.call("_finish_seed_choice", 0.0, "selected")
	_expect(not ui.seed_choice_list.visible, "追加選択演出中は夢の種候補を隠す")
	_expect(ui.more_select.visible, "追加選択メッセージを表示する")
	_expect(is_zero_approx(ui.more_select.modulate.a), "追加選択メッセージは透明から開始する")

	await get_tree().create_timer(
		StageClearUi.MORE_SELECT_FADE_DURATION + StageClearUi.MORE_SELECT_HOLD_DURATION + 0.1
	).timeout
	_expect(ui.seed_choice_list.visible, "演出後に夢の種候補を再表示する")
	_expect(not ui.more_select.visible, "演出後に追加選択メッセージを隠す")
	_expect(bool(stage_clear.get("_seed_choice_active")), "演出後に夢の種を再選択可能にする")
	_expect(
		stage_clear.seed_options.all(func(seed: SeedInfo) -> bool: return area_seeds.has(seed)),
		"演出後の候補を現在地のエリアプールから再読込する"
	)

	remove_child(stage_clear)
	stage_clear.free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
