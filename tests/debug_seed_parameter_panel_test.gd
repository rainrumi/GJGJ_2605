extends Node

var _failures := 0
var _applied_original: SeedInfo
var _applied_edited: SeedInfo


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DebugState.set_debug_enabled(false)
	var save_path := "user://debug_seed_parameter_panel_test.tres"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var panel_scene := load("res://scene/ui/battle_ui/debug/debug_seed_parameter_panel.tscn") as PackedScene
	_expect(panel_scene != null, "パラメーター調整 Scene を読み込める")
	if panel_scene == null:
		get_tree().quit(_failures)
		return
	var panel := panel_scene.instantiate() as DebugSeedParameterPanel
	get_tree().root.add_child(panel)
	await get_tree().process_frame

	var original := SeedInfo.new()
	original.skill_id = 101
	original.display_name = "Test Seed"
	original.main_description = "Original description"
	original.main_skill = SeedSkill.new()
	original.main_skill.priority = 2
	var effect := SeedEffect.new()
	effect.priority = 3
	original.main_skill.effects = [effect]
	_expect(ResourceSaver.save(original, save_path) == OK, "テスト用の種 Resource を保存できる")
	panel.set_seed_inventory([original], [])
	panel.open_panel()
	_expect(not panel.visible, "Debug 無効時は調整画面を開かない")

	DebugState.set_debug_enabled(true)
	panel.open_panel()
	_expect(panel.visible, "Debug 有効時は調整画面を開ける")
	var viewport_rect := get_viewport().get_visible_rect()
	_expect(
		panel.get_global_rect().position.x >= viewport_rect.size.x * 0.5,
		"調整画面を画面右半分へ配置する"
	)
	_expect(
		panel.get_global_rect().end.x <= viewport_rect.end.x,
		"調整画面を画面右端からはみ出さない"
	)
	var actual_seed := load("res://data/resources/seeds/skills/seed_100_101.tres") as SeedInfo
	panel.set_seed_inventory([actual_seed], [])
	var actual_numeric_editors := 0
	for binding in panel.get("_bindings"):
		if binding.editor is SpinBox:
			actual_numeric_editors += 1
			_expect(
				(binding.editor as SpinBox).get_global_rect().size.x >= 90.0,
				"実データの数値入力欄へ表示幅を確保する"
			)
	_expect(actual_numeric_editors >= 6, "実際の夢の種から数値プロパティを列挙する")
	panel.set_seed_inventory([original], [])
	_expect(panel.get("_bindings").size() >= 4, "Skill と Effect の公開パラメーターを列挙する")
	panel.seed_parameter_applied.connect(_on_seed_parameter_applied)
	var priority_editor: SpinBox
	var description_editor: TextEdit
	for binding in panel.get("_bindings"):
		if binding.resource is SeedSkill and binding.property == &"priority":
			priority_editor = binding.editor as SpinBox
		if binding.resource is SeedInfo and binding.property == &"main_description":
			description_editor = binding.editor as TextEdit
	_expect(priority_editor != null, "主スキル priority の入力欄を作る")
	_expect(description_editor != null, "main_description の複数行入力欄を作る")
	if priority_editor != null:
		priority_editor.value = 7
	if description_editor != null:
		description_editor.text = "Saved description\nsecond line"
	(panel.get_node("Margin/Content/Buttons/ApplyButton") as Button).pressed.emit()
	_expect(_applied_original == original, "置換元の種を通知する")
	_expect(_applied_edited != null and _applied_edited != original, "複製した種を通知する")
	_expect(original.main_skill.priority == 2, "保存前の参照を直接変更しない")
	_expect(_applied_edited != null and _applied_edited.main_skill.priority == 7, "複製側へ変更を適用する")
	_expect(
		_applied_edited != null and _applied_edited.main_description == "Saved description\nsecond line",
		"main_description の変更を適用する"
	)
	var persisted := ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
	_expect(persisted != null and persisted.main_skill.priority == 7, "変更値を Resource へ永続化する")
	_expect(
		persisted != null and persisted.main_description == "Saved description\nsecond line",
		"main_description を Resource へ永続化する"
	)

	var controller := GameSeedController.new()
	controller.set_seed_inventory([original, original], [])
	_expect(controller.replace_seed(original, _applied_edited), "所持中の種を置換できる")
	_expect(controller.get_flowers()[0] == _applied_edited, "最初の同一参照を置換する")
	_expect(controller.get_flowers()[1] == _applied_edited, "重複する同一参照も置換する")

	DebugState.set_debug_enabled(false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	panel.queue_free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _on_seed_parameter_applied(original_seed: SeedInfo, edited_seed: SeedInfo) -> void:
	_applied_original = original_seed
	_applied_edited = edited_seed


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("DebugSeedParameterPanelTest: %s" % message)
