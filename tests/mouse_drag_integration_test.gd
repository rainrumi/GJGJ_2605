extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	await _check_enemy_drag(mouse_drag_state)
	await _check_seed_drag(mouse_drag_state)
	quit(_failures)


func _check_enemy_drag(mouse_drag_state: MouseDragTracker) -> void:
	var input_controller := GameInputController.new()
	var enemy := Enemy.new()
	root.add_child(input_controller)
	await process_frame

	input_controller.set("_pressed_enemy", enemy)
	input_controller.call("_start_drag", Vector2.ZERO)
	_expect(mouse_drag_state.is_dragging(), "敵ドラッグ開始を共通状態へ通知する")
	input_controller.clear_drag()
	_expect(not mouse_drag_state.is_dragging(), "敵ドラッグ終了を共通状態へ通知する")

	root.remove_child(input_controller)
	input_controller.free()
	enemy.free()


func _check_seed_drag(mouse_drag_state: MouseDragTracker) -> void:
	var packed := load("res://scene/ui/seed/seed_button.tscn") as PackedScene
	_expect(packed != null, "夢の種Button Sceneを読み込める")
	if packed == null:
		return
	var button := packed.instantiate() as SeedButton
	var seed := SeedInfo.new()
	root.add_child(button)
	await process_frame
	button.set_seed_source(seed)
	button.set_sub_skill_drag_enabled(true)
	button.tooltip_panel.show_tooltip_at(button.global_position)
	_expect(button.tooltip_panel.visible, "ドラッグ前は夢の種ツールチップを表示できる")

	button.call("_handle_press", Vector2.ZERO)
	button.call("_start_drag", Vector2.ONE)
	_expect(mouse_drag_state.is_dragging(), "夢の種ドラッグ開始を共通状態へ通知する")
	_expect(not button.tooltip_panel.visible, "夢の種ドラッグ開始時に表示中ツールチップを閉じる")
	button.tooltip_panel.show_tooltip_at(button.global_position)
	_expect(not button.tooltip_panel.visible, "夢の種ドラッグ中はツールチップを再表示しない")
	button.call("_handle_release", Vector2.ONE)
	_expect(not mouse_drag_state.is_dragging(), "夢の種ドラッグ終了を共通状態へ通知する")
	button.tooltip_panel.show_tooltip_at(button.global_position)
	_expect(button.tooltip_panel.visible, "夢の種ドラッグ終了後はツールチップを表示できる")

	root.remove_child(button)
	button.free()
	seed = null


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MouseDragIntegrationTest: %s" % message)
