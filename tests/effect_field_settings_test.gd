extends SceneTree

const PANEL_SCENE := preload("res://scene/main/title/effect_field_settings_panel.tscn")
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")
const E1_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_001.tres"
const E2_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_002.tres"
const SEED_PATH := "res://data/resources/seeds/skills/seed_100_121.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_selection_values()
	_test_effect_chain()
	await _test_panel_and_save()
	quit(_failures)


func _test_selection_values() -> void:
	var effect := SeedEffectOnFinishAcidSeedBlockDamageAdjacent.new()
	effect.player_max_hp_rate = 30.0
	var seed_block := Enemy.new()
	seed_block.data.defense_status.effect_multiplier = 24.0
	effect.effect_amount_configured = true
	effect.effect_amount_fields = PackedStringArray(["player_max_hp_rate"])
	var adjusted := effect.adjusted_for_seed_block(seed_block) as SeedEffectOnFinishAcidSeedBlockDamageAdjacent
	_expect(adjusted != effect and adjusted.player_max_hp_rate == 720.0, "選択した30倍の変数へ24倍を適用")
	_expect(effect.player_max_hp_rate == 30.0, "共有する種の定義値を変更しない")
	_expect(adjusted.elapsed_minute_damage == 0, "対象外の数値は変更しない")
	seed_block.free()
	var chance_effect := EnemyEffectOnAttackChanceScaleDamage.new()
	chance_effect.chance = 0.3
	chance_effect.probability_configured = true
	chance_effect.probability_fields = PackedStringArray(["chance"])
	chance_effect.begin_field_adjustment(1.0, 2.0)
	_expect(is_equal_approx(chance_effect.chance, 0.6), "確率の選択変数へ2倍を適用")
	chance_effect.end_field_adjustment()
	_expect(is_equal_approx(chance_effect.chance, 0.3), "悪夢の変数を発動後に戻す")


func _test_effect_chain() -> void:
	var e1_info := load(E1_PATH) as EnemyInfo
	var e2_info := load(E2_PATH) as EnemyInfo
	var seed_info := load(SEED_PATH) as SeedInfo
	var e1 := _create_enemy(e1_info, Vector2i.ZERO)
	var e2 := _create_enemy(e2_info, Vector2i(1, 0))
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	root.add_child(seed_block)
	seed_block.setup_seed(seed_info, Vector2.ONE)
	seed_block.set_stomach_cell(Vector2i(1, 1))
	seed_block.set_Aciding(true)
	var e1_effect := e1.get_enemy_effects()[0] as EnemyEffect
	e1_effect.effect_amount_configured = true
	e1_effect.effect_amount_fields = PackedStringArray(["effect_multiplier"])
	var sub_effect := seed_info.sub_skill.effects[0] as SeedEffect
	var previous_configured := sub_effect.effect_amount_configured
	var previous_fields := sub_effect.effect_amount_fields.duplicate()
	sub_effect.effect_amount_configured = true
	sub_effect.effect_amount_fields = PackedStringArray(["player_max_hp_rate"])
	var enemies: Array[Enemy] = [e1, e2, seed_block]
	var stomach := StomachBoard.new()
	var effects := EnemyEffectSystem.new()
	effects.setup(
		PlayerHealth.new(), EnemySpawnQueue.new(), BattleClock.new(), DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(), EnemyDigestionState.new(), EnemyEffectInheritance.new(),
		EnemyEffectStack.new(), EnemyEffectInstaller.new()
	)
	effects.refresh(enemies, stomach)
	_expect(seed_block.data.defense_status.effect_multiplier == 24.0, "選択式でもE1とE2が種に24倍を付与")
	e1.max_hp = 100000
	e1.current_hp = 100000
	seed_block.set_Acided(true)
	var digested: Array[Enemy] = [seed_block]
	DreamSeedBlockAcidResolver.new().append_Acided_by_seed_block_effects(
		seed_block, enemies, stomach, 0, {}, digested, 0, 0, 100, 100
	)
	_expect(e1.current_hp == 28000, "選択式でオトギリソウが72000ダメージ")
	sub_effect.effect_amount_configured = previous_configured
	sub_effect.effect_amount_fields = previous_fields
	effects.reset()
	e1.free()
	e2.free()
	root.remove_child(seed_block)
	seed_block.free()
	stomach.free()


func _test_panel_and_save() -> void:
	var panel := PANEL_SCENE.instantiate() as EffectFieldSettingsPanel
	root.add_child(panel)
	await process_frame
	panel.open()
	_expect(not panel._catalog.is_empty(), "画面に悪夢・夢の種の一覧を読み込める")
	var type_picker := panel.amount_tab.get_node("Picker/Type") as OptionButton
	_expect(type_picker.selected == 0 and panel._selected_paths[0].begins_with("res://data/resources/seeds/skills/"), "初期表示で夢の種の効果を見られる")
	type_picker.select(1)
	type_picker.item_selected.emit(1)
	_expect(panel._selected_paths[0].contains("/enemy/"), "種類を悪夢へ切り替えられる")
	type_picker.select(0)
	type_picker.item_selected.emit(0)
	var search := panel.amount_tab.get_node("Picker/Search") as LineEdit
	search.text = "100121"
	search.text_changed.emit(search.text)
	_expect(panel._selected_paths[0] == SEED_PATH, "ID検索でオトギリソウを選べる")
	await process_frame
	var rows := panel.amount_tab.get_node("Scroll/Rows") as VBoxContainer
	var has_value := false
	for row in rows.get_children():
		if row is HBoxContainer and row.get_child_count() > 0 and "player_max_hp_rate = 30" in String(row.get_child(0).text):
			has_value = true
			var target := row.get_child(1) as CheckBox
			var excluded := row.get_child(2) as CheckBox
			var bounds := target.get_global_rect()
			_expect(bounds.position.x >= 0 and bounds.end.x <= 640 and bounds.position.y >= 0 and bounds.end.y <= 360, "ラジオボタンが画面内に表示される: %s / panel %s / rows %s" % [bounds, panel.get_global_rect(), rows.get_global_rect()])
			_click(target)
			await process_frame
			_expect(target.button_pressed and not excluded.button_pressed, "対象をマウスでクリックできる")
			_click(excluded)
			await process_frame
			_expect(excluded.button_pressed and not target.button_pressed, "対象外もマウスでクリックできる")
			_click(target)
			await process_frame
	_expect(has_value, "変数名と現在値を表示する")
	_expect(panel._drafts[0].has(panel._draft_key(SEED_PATH, "sub_skill", 0, "player_max_hp_rate")), "ラジオ操作を未保存選択に反映")
	panel._drafts[0].clear()
	var temporary := SeedInfo.new()
	temporary.skill_id = 999999
	temporary.display_name = "test"
	temporary.sub_skill = SeedSkill.new()
	var amount_effect := SeedEffectOnFinishAcidSeedBlockDamageAdjacent.new()
	temporary.sub_skill.effects = [amount_effect]
	var path := "res://tests/_effect_field_settings_temporary.tres"
	_expect(ResourceSaver.save(temporary, path) == OK, "保存用のResourceを作れる")
	panel._resources[path] = temporary
	var key := panel._draft_key(path, "sub_skill", 0, "player_max_hp_rate")
	panel._drafts[0][key] = {"path": path, "slot": "sub_skill", "index": 0, "field": "player_max_hp_rate", "selected": true}
	panel._save_tab(0)
	var reloaded := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
	_expect(reloaded != null and reloaded.sub_skill.effects[0].effect_amount_fields.has("player_max_hp_rate"), "効果量タブの選択をResourceへ記録")
	_expect(reloaded != null and not reloaded.sub_skill.effects[0].probability_configured, "確率タブは独立して保存")
	var probability_key := panel._draft_key(path, "sub_skill", 0, "received_damage_rate")
	panel._drafts[1][probability_key] = {"path": path, "slot": "sub_skill", "index": 0, "field": "received_damage_rate", "selected": true}
	panel._save_tab(1)
	reloaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
	_expect(reloaded != null and reloaded.sub_skill.effects[0].probability_fields.has("received_damage_rate"), "確率タブの選択をResourceへ記録")
	_expect(reloaded != null and reloaded.sub_skill.effects[0].effect_amount_fields.has("player_max_hp_rate"), "確率保存でも効果量の選択を保持")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	panel.free()


func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	var event := InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	root.push_input(event, true)
	event = InputEventMouseButton.new()
	event.position = point
	event.global_position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = false
	root.push_input(event, true)


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EffectFieldSettingsTest: %s" % message)
