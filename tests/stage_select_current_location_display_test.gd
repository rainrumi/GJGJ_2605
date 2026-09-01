extends SceneTree

const CURRENT_LOCATION_SUFFIX := "（現在地）"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	var current_stage := load("res://data/resources/area/area_iriyu/area_iriyu.tres") as StageInfo
	_expect(packed != null, "ステージ選択Sceneを読み込める")
	_expect(current_stage != null, "現在地用StageInfoを読み込める")
	if packed == null or current_stage == null:
		quit(_failures)
		return

	var stage_select := packed.instantiate()
	root.add_child(stage_select)
	await process_frame
	var run_state := RunState.new()
	run_state.unlock_lara()
	run_state.lara_current_location = current_stage
	var unlocked_stage_ids: Array[int] = []
	stage_select.call("setup_stage_choices", current_stage, 5, unlocked_stage_ids, run_state)
	await process_frame

	var choice_list := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/StageChoices")
	var map_view := stage_select.get_node("CharacterArea/Map") as StageSelectMapView
	var beacon := map_view.get_node("Beacon") as StageSelectBeacon
	var location_marker := map_view.get_node("LocationMarker") as StageSelectLocationMarker
	var current_choice: StageSelectChoice
	var other_choice: StageSelectChoice
	for child in choice_list.get_children():
		if not child is StageSelectChoice or not child.visible:
			continue
		var choice := child as StageSelectChoice
		if choice.location_label.text.ends_with(CURRENT_LOCATION_SUFFIX):
			current_choice = choice
		else:
			other_choice = choice

	_expect(location_marker.visible, "ラーラ解放後はlocationアイコンを表示する")
	_expect(location_marker.position.is_equal_approx(current_stage.map_position), "locationアイコンをラーラの現在地へ配置する")
	var initial_texture := location_marker.outline.texture
	location_marker.call("_process_frame", 0.11)
	_expect(location_marker.outline.texture != initial_texture, "locationアイコンを常時フレームアニメーションする")
	_expect(current_choice != null, "現在地の選択肢に現在地表記を付ける")
	if current_choice != null:
		_expect(
			current_choice.location_label.text == "%s%s" % [current_stage.location, CURRENT_LOCATION_SUFFIX],
			"LocationLabelの末尾だけに現在地表記を付ける"
		)
		current_choice.mouse_entered.emit()
		_expect(beacon.visible, "現在地の選択肢でもホバー時にビーコンを表示する")
		_expect(location_marker.get("_playing"), "ホバー中もlocationアイコンのアニメーションを止めない")
		_expect(beacon.position.is_equal_approx(current_stage.map_position), "現在地の座標にビーコンを表示する")
		current_choice.mouse_exited.emit()

	_expect(other_choice != null, "現在地以外の選択肢を表示する")
	if other_choice != null:
		_expect(not other_choice.location_label.text.ends_with(CURRENT_LOCATION_SUFFIX), "現在地以外には現在地表記を付けない")
		other_choice.mouse_entered.emit()
		_expect(beacon.visible, "現在地以外もホバー時にビーコンを表示する")
		other_choice.mouse_exited.emit()
	_expect(not beacon.visible, "ホバー解除時にビーコンを隠す")

	root.remove_child(stage_select)
	stage_select.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageSelectCurrentLocationDisplayTest: %s" % message)
