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
	var select_container := stage_select.get_node("UI/StageChoicesScroll/StageChoicesMargin/SelectContainer") as VBoxContainer
	var title_label := select_container.get_node("StageChoicesPadding/TitleLabel") as Label
	var scroll := select_container.get_node("StageChoicesListScroll") as ScrollContainer
	var choices_padding := scroll.get_node("StageChoicesPadding") as MarginContainer
	var choice_list := choices_padding.get_node("StageChoices") as StageSelectChoiceList
	var scroll_bar := scroll.get_v_scroll_bar()
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	choice_list.choice_pressed.connect(_on_choice_pressed)
	_expect(select_container.is_ancestor_of(title_label), "Title remains in the stage selection hierarchy")
	_expect(not scroll_bar.visible, "Scrollbar stays hidden while every stage choice fits")
	var first_choice := _get_first_visible_control(choice_list)
	_expect(
		first_choice != null
		and first_choice.get_global_rect().position.x - scroll.get_global_rect().position.x >= 10.0
		and scroll.get_global_rect().end.x - first_choice.get_global_rect().end.x >= 10.0,
		"Stage choices keep at least 10 pixels of horizontal padding"
	)
	_expect_choices_centered(scroll, choice_list)
	var initial_scroll_height := scroll.size.y
	var initial_title_y := title_label.global_position.y
	var last_choice := _get_last_visible_control(choice_list)
	last_choice.hide()
	await process_frame
	await process_frame
	_expect(scroll.size.y < initial_scroll_height, "StageChoices viewport shrinks with its visible content")
	_expect(title_label.global_position.y > initial_title_y, "Title follows the centered StageChoices group")
	_expect_choices_centered(scroll, choice_list)
	choice_list.custom_minimum_size.y = 600.0
	await process_frame
	await process_frame
	_expect(scroll_bar.visible, "Scrollbar appears when stage choices do not fit")
	_expect(is_equal_approx(scroll_bar.size.y, scroll.size.y), "Scrollbar height matches the StageChoices viewport")
	_expect(
		first_choice != null
		and scroll_bar.global_position.x - first_choice.get_global_rect().end.x >= 10.0,
		"Scrollbar keeps at least 10 pixels from stage choice buttons"
	)
	scroll.scroll_vertical = 40
	scroll.call("reset_to_top")
	await process_frame
	_expect(scroll.scroll_vertical == 0, "一覧表示時はスクロール位置を最上部へ戻す")

	var start_position := scroll.global_position + scroll.size * 0.5
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


func _get_first_visible_control(parent: Control) -> Control:
	for child in parent.get_children():
		if child is Control and (child as Control).visible:
			return child as Control
	return null


func _get_last_visible_control(parent: Control) -> Control:
	for child_index in range(parent.get_child_count() - 1, -1, -1):
		var child := parent.get_child(child_index)
		if child is Control and (child as Control).visible:
			return child as Control
	return null


func _on_choice_pressed(_choice_index: int) -> void:
	_choice_pressed_count += 1
