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
	var settings_store := root.get_node("EffectFieldSettings") as EffectFieldSettingsStore
	settings_store.settings_path = "res://tests/_effect_field_settings_test.cfg"
	settings_store.load_settings()
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
	var settings_path := "res://tests/_effect_field_settings_test.cfg"
	var panel := PANEL_SCENE.instantiate() as EffectFieldSettingsPanel
	root.add_child(panel)
	await process_frame
	panel.open()
	_expect(not panel._catalog.is_empty(), "画面に悪夢・夢の種の一覧を読み込める")
	var rows := panel.amount_tab.get_node("Scroll/Rows") as VBoxContainer
	var scroll := panel.amount_tab.get_node("Scroll") as ScrollContainer
	var seed_count := 0
	var enemy_count := 0
	var separator_count := 0
	var has_seed_description := false
	var has_enemy_description := false
	for child in rows.get_children():
		if child is HSeparator:
			separator_count += 1
		elif child is Label:
			if child.text.begins_with("夢の種 "):
				seed_count += 1
			elif child.text.begins_with("悪夢 "):
				enemy_count += 1
			elif child.text.begins_with("メイン: "):
				has_seed_description = has_seed_description or child.text.length() > "メイン: ".length()
			elif child.text.begins_with("効果: "):
				has_enemy_description = has_enemy_description or child.text.length() > "効果: ".length()
	_expect(seed_count > 0 and enemy_count > 0, "初期表示で夢の種と悪夢をすべて縦に並べる")
	_expect(seed_count + enemy_count == panel._catalog.size(), "検索前は対象の全件を表示する")
	_expect(separator_count == seed_count + enemy_count - 1, "各項目を線で区切る")
	_expect(has_seed_description and has_enemy_description, "夢の種と悪夢の効果をテキスト表示する")
	await process_frame
	_expect(scroll.get_v_scroll_bar().max_value > scroll.size.y, "マウスホイールで一覧を縦スクロールできる")
	var wheel := InputEventMouseButton.new()
	wheel.position = scroll.get_global_rect().get_center()
	wheel.global_position = wheel.position
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	wheel.pressed = true
	root.push_input(wheel, true)
	await process_frame
	_expect(scroll.scroll_vertical > 0, "マウスホイール入力で一覧が下へ動く")
	var search := panel.amount_tab.get_node("Picker/Search") as LineEdit
	search.text = "100121"
	search.text_changed.emit(search.text)
	_expect(rows.get_child_count() > 0 and (rows.get_child(0) as Label).text.contains("100121"), "ID検索でオトギリソウを絞り込める")
	await process_frame
	var has_value := false
	for row in rows.get_children():
		if row is HBoxContainer and row.get_child_count() > 0 and "player_max_hp_rate = 30" in String(row.get_child(0).text):
			has_value = true
			var target := row.get_child(1) as CheckBox
			var excluded := row.get_child(2) as CheckBox
			scroll.ensure_control_visible(target)
			await process_frame
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
	_expect(bool(panel._drafts[0][panel._draft_key(SEED_PATH, "sub_skill", 0, "player_max_hp_rate")].selected), "対象を選んだ結果を保持")
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
	var real_seed_path := "res://tests/_effect_field_settings_real_seed_temporary.tres"
	var real_seed := load(SEED_PATH) as SeedInfo
	_expect(ResourceSaver.save(real_seed.duplicate(true), real_seed_path) == OK, "100121の複製を保存できる")
	panel._resources[real_seed_path] = ResourceLoader.load(real_seed_path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var real_key := panel._draft_key(real_seed_path, "sub_skill", 0, "player_max_hp_rate")
	panel._drafts[0][real_key] = {"path": real_seed_path, "slot": "sub_skill", "index": 0, "field": "player_max_hp_rate", "selected": true}
	panel._save_tab(0)
	var saved_real_seed := ResourceLoader.load(real_seed_path, "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
	_expect(FileAccess.get_file_as_string(real_seed_path).contains('effect_amount_fields = PackedStringArray("player_max_hp_rate")'), "100121の対象変数名をファイルへ記録")
	_expect(saved_real_seed != null and saved_real_seed.sub_skill.effects[0].effect_amount_fields.has("player_max_hp_rate"), "100121の対象選択をディスクから再読込できる")
	_expect(not panel._drafts[0].has(real_key), "再読込で一致した選択だけ未保存から外す")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(real_seed_path))
	panel.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))


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
