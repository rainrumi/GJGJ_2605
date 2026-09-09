extends SceneTree

var _failures := 0
var _choice_pressed_count := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/stage_select/stage_select.tscn") as PackedScene
	_expect(packed != null, "エリア選択Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var stage_select := packed.instantiate()
	root.add_child(stage_select)
	await process_frame
	var scroll := stage_select.get_node("UI/StageChoicesScroll") as ScrollContainer
	var choice_list := scroll.get_node("StageChoicesMargin/SelectContainer/StageChoices") as StageSelectChoiceList
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	var start_position := scroll.global_position + scroll.size * 0.5
	choice_list.choice_pressed.connect(_on_choice_pressed)
	_expect_choices_centered(scroll, choice_list)
	var last_choice := choice_list.get_child(choice_list.get_child_count() - 1) as Control
	last_choice.hide()
	await process_frame
	_expect_choices_centered(scroll, choice_list)
	choice_list.custom_minimum_size.y = 600.0
	await process_frame
	scroll.scroll_vertical = 40
	scroll.call("reset_to_top")
	await process_frame
	_expect(scroll.scroll_vertical == 0, "一覧表示時はスクロール位置を最上部へ戻す")

	scroll.scroll_vertical = 20
	scroll.call("_begin_press", start_position)
	scroll.call("_update_drag", start_position + Vector2(0.0, 4.0))
	_expect(scroll.scroll_vertical == 20, "deadzone内の移動ではスクロールしない")
	_expect(not mouse_drag_state.is_dragging(), "deadzone内ではドラッグ状態にしない")

	scroll.call("_update_drag", start_position + Vector2(0.0, -16.0))
	_expect(scroll.scroll_vertical == 36, "上方向のドラッグ量に応じて下へスクロールする")
	_expect(mouse_drag_state.is_dragging(), "スクロールドラッグを共通状態へ通知する")
	choice_list.call("_on_stage_choice_pressed", 0)
	_expect(_choice_pressed_count == 0, "ドラッグ中はエリア選択を確定しない")
	scroll.call("_end_press")
	await process_frame
	_expect(not mouse_drag_state.is_dragging(), "マウス解放時にドラッグ状態を解除する")
	choice_list.call("_on_stage_choice_pressed", 0)
	_expect(_choice_pressed_count == 1, "ドラッグ終了後はエリアを選択できる")

	root.remove_child(stage_select)
	stage_select.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageChoicesScrollTest: %s" % message)


func _expect_choices_centered(scroll: ScrollContainer, choice_list: Control) -> void:
	for child in choice_list.get_children():
		if child is Control and (child as Control).visible:
			var button := child as Control
			_expect(
				is_equal_approx(button.position.x + button.size.x * 0.5, choice_list.size.x * 0.5),
				"Stage choice buttons are horizontally centered"
			)
	_expect(
		is_equal_approx(
			choice_list.global_position.y + choice_list.size.y * 0.5,
			scroll.global_position.y + scroll.size.y * 0.5
		),
		"Stage choice list is vertically centered"
	)


func _on_choice_pressed(_choice_index: int) -> void:
	_choice_pressed_count += 1
