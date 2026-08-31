extends Node

const TEMP_MARK_PATH := "user://seed_performance_mark_test.txt"

var _failures := 0
var _original_path := ""
var _original_debug_enabled := false
var _original_marks: Dictionary = {}


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_preserve_debug_state()
	DebugState.seed_performance_mark_path = TEMP_MARK_PATH
	DebugState.set("_marked_seed_names", {})
	DebugState.set_debug_enabled(false)

	var seed := SeedInfo.new()
	seed.skill_id = 1234
	seed.display_name = "性能確認用の種"
	_expect(not DebugState.toggle_seed_performance_mark(seed), "デバッグ無効時はチェックできない")
	_expect(not DebugState.is_seed_performance_marked(seed.skill_id), "デバッグ無効時は状態を変更しない")

	DebugState.set_debug_enabled(true)
	_expect(DebugState.toggle_seed_performance_mark(seed), "デバッグ有効時はチェックできる")
	_expect(DebugState.is_seed_performance_marked(seed.skill_id), "夢の種IDごとにチェック状態を保持する")
	var saved_text := FileAccess.get_file_as_string(TEMP_MARK_PATH)
	_expect(saved_text.contains("1234\t性能確認用の種"), "IDと名前をtxtへ保存する")

	DebugState.set("_marked_seed_names", {})
	DebugState.load_seed_performance_marks()
	_expect(DebugState.is_seed_performance_marked(seed.skill_id), "txtからチェック状態を復元する")

	await _check_seed_button(seed)
	await _check_stage_clear_choice(seed)
	_restore_debug_state()
	get_tree().quit(_failures)


func _check_seed_button(seed: SeedInfo) -> void:
	var packed := load("res://scene/ui/seed/seed_button.tscn") as PackedScene
	var button := packed.instantiate() as SeedButton
	var duplicate_button := packed.instantiate() as SeedButton
	get_tree().root.add_child(button)
	get_tree().root.add_child(duplicate_button)
	await get_tree().process_frame
	button.set_seed_source(seed)
	duplicate_button.set_seed_source(seed)
	button.set_debug_numbers_visible(true)
	duplicate_button.set_debug_numbers_visible(true)
	_expect(button.performance_mark.visible, "アイテム一覧でチェックマークを表示する")
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	button.call("_gui_input", right_click)
	_expect(not DebugState.is_seed_performance_marked(seed.skill_id), "一覧の右クリックでチェックを解除する")
	_expect(not duplicate_button.performance_mark.visible, "同じIDの全一覧表示を同期する")
	DebugState.toggle_seed_performance_mark(seed)
	button.set_debug_numbers_visible(false)
	_expect(not button.performance_mark.visible, "デバッグ表示無効時は一覧のチェックを隠す")
	button.queue_free()
	duplicate_button.queue_free()
	await get_tree().process_frame


func _check_stage_clear_choice(seed: SeedInfo) -> void:
	var packed := load("res://scene/main/stage_clear/seed_choice/seed_choice.tscn") as PackedScene
	var choice := packed.instantiate() as StageClearSeedChoice
	get_tree().root.add_child(choice)
	await get_tree().process_frame
	choice.setup_choice(seed)
	choice.set_debug_numbers_visible(true)
	_expect(choice.performance_mark.visible, "夢の種選択ボタンでチェックマークを表示する")
	var right_click := InputEventMouseButton.new()
	right_click.button_index = MOUSE_BUTTON_RIGHT
	right_click.pressed = true
	choice.call("_on_gui_input", right_click)
	_expect(not DebugState.is_seed_performance_marked(seed.skill_id), "夢の種選択ボタンの右クリックでチェックを解除する")
	choice.set_debug_numbers_visible(false)
	_expect(not choice.performance_mark.visible, "デバッグ表示無効時は選択肢のチェックを隠す")
	choice.queue_free()
	await get_tree().process_frame


func _preserve_debug_state() -> void:
	_original_path = DebugState.seed_performance_mark_path
	_original_debug_enabled = DebugState.debug_enabled
	_original_marks = DebugState.get("_marked_seed_names").duplicate()


func _restore_debug_state() -> void:
	DebugState.seed_performance_mark_path = _original_path
	DebugState.set("_marked_seed_names", _original_marks)
	DebugState.set_debug_enabled(_original_debug_enabled)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
