extends Node

var _failures := 0
var _applied_original: EnemyInfo
var _applied_edited: EnemyInfo
var _panel: DebugEnemyParameterPanel
var _preset: EnemyPresetInfo
var _controller: GameEnemySetupController


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	DebugState.set_debug_enabled(false)
	var save_path := "user://debug_enemy_parameter_panel_test.tres"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var panel_scene := load("res://scene/ui/battle_ui/debug/debug_enemy_parameter_panel.tscn") as PackedScene
	_expect(panel_scene != null, "悪夢パラメーター調整 Scene を読み込める")
	if panel_scene == null:
		get_tree().quit(_failures)
		return
	var panel := panel_scene.instantiate() as DebugEnemyParameterPanel
	get_tree().root.add_child(panel)
	await get_tree().process_frame

	var original := EnemyInfo.new()
	original.skill_id = 201
	original.display_name = "Test Nightmare"
	original.description = "Original skill description"
	original.acid_block = AcidBlockInfo.new()
	original.acid_block.max_hp = 100
	original.acid_block.damage = 12
	original.main_skill = EnemySkill.new()
	original.main_skill.priority = 2
	var effect := EnemyEffectOnAdjacentStomachChangeAttack.new()
	effect.priority = 3
	effect.attack_delta = -8
	original.main_skill.effects = [effect]
	_expect(ResourceSaver.save(original, save_path) == OK, "テスト用の悪夢 Resource を保存できる")
	original = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyInfo
	_expect(original != null and not original.resource_path.is_empty(), "保存済みの悪夢 Resource を読み込める")
	var preset := EnemyPresetInfo.new()
	preset.enemies = [original, original]
	_panel = panel
	_preset = preset
	_controller = GameEnemySetupController.new()
	_controller.setup(self, GameInputController.new(), StomachBoard.new(), preset)
	panel.set_enemy_preset(preset)
	panel.open_panel()
	_expect(not panel.visible, "Debug 無効時は調整画面を開かない")

	DebugState.set_debug_enabled(true)
	panel.open_panel()
	await get_tree().process_frame
	_expect(panel.visible, "Debug 有効時は調整画面を開ける")
	var viewport_rect := get_viewport().get_visible_rect()
	_expect(panel.get_global_rect().position.x >= viewport_rect.size.x * 0.5, "調整画面を画面右半分へ配置する")
	_expect(panel.get_global_rect().end.x <= viewport_rect.end.x, "調整画面を画面右端からはみ出さない")
	_expect(panel.get("_enemies").size() == 1, "同じ悪夢 Resource は選択肢へ重複表示しない")
	_expect(panel.get("_bindings").size() == 4, "説明文、HP、攻撃、関与する効果プロパティだけを列挙する")
	var scroll := panel.get_node("Margin/Content/Scroll") as ScrollContainer
	_expect(not scroll.get_v_scroll_bar().visible, "E2相当の情報量はマウスホイールなしで一画面に収める")
	panel.enemy_parameter_applied.connect(_on_enemy_parameter_applied)
	var hp_editor: SpinBox
	var attack_delta_editor: SpinBox
	var description_editor: TextEdit
	for binding in panel.get("_bindings"):
		if binding.resource is EnemyInfo and binding.property == &"description":
			description_editor = binding.editor as TextEdit
		if binding.resource is AcidBlockInfo and binding.property == &"max_hp":
			hp_editor = binding.editor as SpinBox
		if binding.resource is EnemyEffectOnAdjacentStomachChangeAttack and binding.property == &"attack_delta":
			attack_delta_editor = binding.editor as SpinBox
		_expect(binding.property not in [&"priority", &"enabled"], "汎用の priority と enabled は表示しない")
	_expect(hp_editor != null, "悪夢 max_hp の入力欄を作る")
	_expect(attack_delta_editor != null, "関与する効果 attack_delta の入力欄を作る")
	_expect(description_editor != null, "悪夢スキル説明文の複数行入力欄を作る")
	if description_editor != null:
		description_editor.text = "Edited skill description"
	if hp_editor != null:
		hp_editor.value = 777
	if attack_delta_editor != null:
		attack_delta_editor.value = -20
	(panel.get_node("Margin/Content/Buttons/ApplyButton") as Button).pressed.emit()
	_expect(_applied_original == original, "置換元の悪夢を通知する")
	_expect(_applied_edited != null and _applied_edited != original, "複製した悪夢を通知する")
	_expect(original.acid_block.max_hp == 100, "保存前の参照を直接変更しない")
	_expect(_applied_edited != null and _applied_edited.acid_block.max_hp == 777, "複製側へ変更を適用する")
	_expect(_applied_edited != null and _applied_edited.description == "Edited skill description", "説明文の変更を複製側へ適用する")
	var edited_effect := _applied_edited.main_skill.effects[0] as EnemyEffectOnAdjacentStomachChangeAttack if _applied_edited != null else null
	_expect(
		edited_effect != null and edited_effect.attack_delta == -20,
		"効果固有プロパティの変更を適用する"
	)
	var persisted := ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyInfo
	_expect(
		persisted != null
		and persisted.acid_block.max_hp == 777
		and persisted.description == "Edited skill description",
		"数値と説明文を Resource へ永続化する"
	)
	_expect(_applied_edited.resource_path == save_path, "保存後の悪夢 Resource が保存先を引き継ぐ")
	_expect(panel.get("_enemies")[0] == _applied_edited, "選択肢の悪夢参照を保存後の Resource へ置換する")
	_expect(panel.get("_original_enemy") == _applied_edited, "パネルの保存元参照を保存後の Resource へ更新する")
	_expect(panel.get("_edited_enemy") != _applied_edited, "次回編集用に保存後の Resource を複製し直す")

	_expect(_applied_original == original, "編成中の悪夢の置換元を通知する")
	_expect(preset.enemies[0] == _applied_edited, "最初の同一参照を置換する")
	_expect(preset.enemies[1] == _applied_edited, "重複する同一参照も置換する")

	var first_saved_enemy := _applied_edited
	hp_editor = null
	for binding in panel.get("_bindings"):
		if binding.resource is AcidBlockInfo and binding.property == &"max_hp":
			hp_editor = binding.editor as SpinBox
	_expect(hp_editor != null, "保存後に更新された悪夢参照から入力欄を作り直す")
	if hp_editor != null:
		hp_editor.value = 888
	(panel.get_node("Margin/Content/Buttons/ApplyButton") as Button).pressed.emit()
	persisted = ResourceLoader.load(save_path, "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyInfo
	_expect(persisted != null and persisted.acid_block.max_hp == 888, "同じ悪夢を2回続けて保存できる")
	_expect(_applied_original == first_saved_enemy, "2回目は1回目に保存した悪夢参照を置換元として通知する")
	_expect(_applied_edited != first_saved_enemy, "2回目も次回編集用の複製を保存する")
	_expect(panel.get("_original_enemy") == _applied_edited, "2回目の保存後もパネルの保存元参照を更新する")

	var status := panel.get_node("Margin/Content/StatusLabel") as Label
	var buttons := panel.get_node("Margin/Content/Buttons") as HBoxContainer
	_expect(status.get_theme_font_size("font_size") == 6, "更新結果テキストをパネル標準の約0.5倍にする")
	_expect(status.max_lines_visible == 2, "更新結果テキストを最大2行に制限する")
	_expect(status.position.y >= buttons.position.y + buttons.size.y, "更新結果テキストを操作ボタンより下へ配置する")

	DebugState.set_debug_enabled(false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	panel.queue_free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _on_enemy_parameter_applied(original_enemy: EnemyInfo, edited_enemy: EnemyInfo) -> void:
	_applied_original = original_enemy
	_applied_edited = edited_enemy
	if _controller.replace_enemy_info(original_enemy, edited_enemy):
		_panel.set_enemy_preset(_preset)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("DebugEnemyParameterPanelTest: %s" % message)
