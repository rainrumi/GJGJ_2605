extends Node

const TEXT_SCREENSHOT_PATH := "res://.godot/agent-logs/debug-seed-retry-text.png"
const NUMBER_SCREENSHOT_PATH := "res://.godot/agent-logs/debug-seed-retry-number.png"

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var save_path := "user://debug_seed_retry_visual_test.tres"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var original := SeedInfo.new()
	original.skill_id = 990001
	original.display_name = "Retry Visual Test Seed"
	original.main_description = "Before retry"
	original.acid_block = AcidBlockInfo.new()
	original.acid_block.max_hp = 10
	_expect(ResourceSaver.save(original, save_path) == OK, "テスト用の種を保存できる")
	original.take_over_path(save_path)

	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var debug_panel := game.get_node("UI/DebugPanel") as DebugPanel
	var all_seed_panel := debug_panel.all_seed_panel
	var catalog := SeedCatalogInfo.new()
	catalog.normal_skills = [original]
	all_seed_panel.seed_catalog = catalog
	all_seed_panel.seed_list.set_seed_sources([original])

	game.call("start_battle", BattleInfo.new())
	DebugState.set_debug_enabled(true)
	all_seed_panel.seed_acquisition_requested.emit(original)
	await get_tree().process_frame
	_expect((game.call("get_equipped_seeds") as Array).has(original), "一覧から種を取得できる")

	var parameter_panel := debug_panel.seed_parameter_panel
	parameter_panel.open_panel()
	var description_editor: TextEdit
	var hp_editor: SpinBox
	for binding in parameter_panel.get("_bindings"):
		if binding.resource is SeedInfo and binding.property == &"main_description":
			description_editor = binding.editor as TextEdit
		if binding.resource is AcidBlockInfo and binding.property == &"max_hp":
			hp_editor = binding.editor as SpinBox
	_expect(description_editor != null and hp_editor != null, "テキストと数値の編集欄を表示する")
	if description_editor != null:
		description_editor.text = "After retry"
	if hp_editor != null:
		hp_editor.value = 777
	(parameter_panel.get_node("Margin/Content/Buttons/ApplyButton") as Button).pressed.emit()
	await get_tree().process_frame

	var saved_seed := catalog.normal_skills[0]
	_expect(saved_seed != original, "取得元カタログを保存後の種へ置換する")
	_expect(saved_seed.main_description == "After retry", "取得元カタログへ変更後テキストを反映する")
	_expect(saved_seed.acid_block.max_hp == 777, "取得元カタログへ変更後数値を反映する")

	debug_panel.debug_retry_button.pressed.emit()
	await get_tree().process_frame
	all_seed_panel.seed_acquisition_requested.emit(catalog.normal_skills[0])
	await get_tree().process_frame
	parameter_panel.open_panel()
	await get_tree().process_frame

	description_editor = null
	hp_editor = null
	for binding in parameter_panel.get("_bindings"):
		if binding.resource is SeedInfo and binding.property == &"main_description":
			description_editor = binding.editor as TextEdit
		if binding.resource is AcidBlockInfo and binding.property == &"max_hp":
			hp_editor = binding.editor as SpinBox
	_expect(description_editor != null and description_editor.text == "After retry", "再取得後の画面に変更後テキストを表示する")
	_expect(hp_editor != null and int(hp_editor.value) == 777, "再取得後の画面に変更後数値を表示する")
	if DisplayServer.get_name() != "headless":
		_save_screenshot(TEXT_SCREENSHOT_PATH)
		var scroll := parameter_panel.get_node("Margin/Content/Scroll") as ScrollContainer
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
		await get_tree().process_frame
		await get_tree().process_frame
		_save_screenshot(NUMBER_SCREENSHOT_PATH)

	DebugState.set_debug_enabled(false)
	saved_seed.take_over_path("")
	catalog.normal_skills.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	game.queue_free()
	packed = null
	call_deferred("_quit_after_cleanup")


func _save_screenshot(path: String) -> void:
	var screenshot := get_viewport().get_texture().get_image()
	if screenshot != null:
		_expect(screenshot.save_png(path) == OK, "確認用スクリーンショットを保存する")


func _quit_after_cleanup() -> void:
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("DebugSeedRetryVisualTest: %s" % message)
