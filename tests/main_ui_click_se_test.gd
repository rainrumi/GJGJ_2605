extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/main.tscn") as PackedScene
	_expect(packed != null, "Main Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var main := packed.instantiate()
	root.add_child(main)
	await process_frame
	var click_se := main.get_node("SeClick") as AudioStreamPlayer
	var stage_choice := main.get_node(
		"StageSelect/UI/StageChoicesScroll/StageChoicesMargin/StageChoices/StageChoice1"
	) as BaseButton
	var drag_owner := Node.new()
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	root.add_child(drag_owner)
	click_se.stream = AudioStreamGenerator.new()
	click_se.stop()
	var opening_novel := main.get_node("OpeningNovel") as OpeningNovel
	opening_novel.advanced.emit()
	_expect(not click_se.playing, "ノベル送り操作はクリックSEを再生しない")

	mouse_drag_state.begin_drag(drag_owner)
	main.call("_on_ui_button_pressed", stage_choice)
	_expect(not click_se.playing, "ドラッグで操作がキャンセルされたボタンはクリックSEを再生しない")

	mouse_drag_state.end_drag(drag_owner)
	main.call("_on_ui_button_pressed", stage_choice)
	_expect(click_se.playing, "通常のボタン操作はクリックSEを再生する")

	root.remove_child(drag_owner)
	drag_owner.free()
	root.remove_child(main)
	main.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("MainUiClickSeTest: %s" % message)
