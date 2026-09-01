extends SceneTree

const LARA_CATALOG_PATH := "res://data/resources/area/lara_location_catalog.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(LARA_CATALOG_PATH) as StageCatalogInfo
	_expect(catalog != null, "ラーラ現在地カタログを読み込める")
	if catalog == null:
		quit(_failures)
		return
	_expect(catalog.stages.size() == 10, "現在地候補を10箇所持つ")
	for stage in catalog.stages:
		_expect(stage != null, "現在地候補にnullを含めない")
		if stage != null:
			_expect(stage.stage_area != StageInfo.StageArea.LUNOVA_OLD_CITY, "現在地候補に旧市街を含めない")

	var run_state := RunState.new()
	run_state.update_lara_location(catalog.stages)
	_expect(run_state.lara_current_location == null, "解放前は現在地を持たない")
	run_state.unlock_lara()
	run_state.update_lara_location(catalog.stages)
	_expect(run_state.lara_current_location in catalog.stages, "解放後は10箇所から現在地を保持する")
	run_state.reset()
	_expect(not run_state.is_lara_unlocked, "リセット時にラーラを未解放へ戻す")
	_expect(run_state.lara_current_location == null, "リセット時にラーラの現在地を消去する")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RunStateLaraTest: %s" % message)
