extends SceneTree

const PANEL_SCENE := preload("res://scene/main/title/effect_field_settings_panel.tscn")
const SEED_110_SOURCE := "res://data/resources/seeds/skills/seed_100_110.tres"
const SEED_121_SOURCE := "res://data/resources/seeds/skills/seed_100_121.tres"
const ENEMY_SOURCE := "res://data/resources/area/area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_004.tres"
const SEED_110_COPY := "res://data/resources/seeds/skills/_effect_field_persistence_110.tres"
const SEED_121_COPY := "res://data/resources/seeds/skills/_effect_field_persistence_121.tres"
const ENEMY_COPY := "res://data/resources/area/area_lunova/enemy/boss/002/_effect_field_persistence_enemy.tres"
const SETTINGS_COPY := "user://effect_field_persistence_test.cfg"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var settings_store := root.get_node("EffectFieldSettings") as EffectFieldSettingsStore
	settings_store.settings_path = SETTINGS_COPY
	settings_store.load_settings()
	var args := OS.get_cmdline_user_args()
	if args.has("write"):
		await _write_choices()
	elif args.has("verify"):
		_verify_choices()
	elif args.has("strip"):
		for pair in [[SEED_110_SOURCE, SEED_110_COPY], [SEED_121_SOURCE, SEED_121_COPY]]:
			var source := ResourceLoader.load(pair[0], "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
			_expect(ResourceSaver.save(source.duplicate(true), pair[1]) == OK, "テスト用Resourceを元の定義へ戻せる")
		_save_enemy_copy()
	elif args.has("verify_backup"):
		_verify_choices(true)
	else:
		_expect(false, "write / verify / strip / verify_backup を指定してください")
	quit(_failures)


func _write_choices() -> void:
	for pair in [[SEED_110_SOURCE, SEED_110_COPY], [SEED_121_SOURCE, SEED_121_COPY]]:
		var source := ResourceLoader.load(pair[0], "", ResourceLoader.CACHE_MODE_IGNORE) as SeedInfo
		_expect(source != null, "%s を読み込める" % pair[0])
		if source == null:
			return
		var copy := source.duplicate(true) as SeedInfo
		_expect(ResourceSaver.save(copy, pair[1]) == OK, "%s のコピーを保存できる" % pair[0])
	_save_enemy_copy()
	var identities := {
		SEED_110_COPY: _resource_identity(SEED_110_COPY),
		SEED_121_COPY: _resource_identity(SEED_121_COPY),
		ENEMY_COPY: _resource_identity(ENEMY_COPY),
	}
	var panel := PANEL_SCENE.instantiate() as EffectFieldSettingsPanel
	root.add_child(panel)
	await process_frame
	panel._resources[SEED_110_COPY] = ResourceLoader.load(SEED_110_COPY, "", ResourceLoader.CACHE_MODE_IGNORE)
	panel._resources[SEED_121_COPY] = ResourceLoader.load(SEED_121_COPY, "", ResourceLoader.CACHE_MODE_IGNORE)
	panel._resources[ENEMY_COPY] = ResourceLoader.load(ENEMY_COPY, "", ResourceLoader.CACHE_MODE_IGNORE)
	panel._catalog = [
		{"path": SEED_110_COPY, "kind": 0, "label": "夢の種 100110", "search": "100110"},
		{"path": SEED_121_COPY, "kind": 0, "label": "夢の種 100121", "search": "100121"},
		{"path": ENEMY_COPY, "kind": 1, "label": "悪夢 17020002004", "search": "17020002004"},
	]
	panel.visible = true
	panel._render_rows(0)
	await _select_target(panel, 0, SEED_110_COPY, "main_skill", "rate", "rate = 9")
	await _select_target(panel, 0, SEED_121_COPY, "sub_skill", "player_max_hp_rate", "player_max_hp_rate = 30")
	await _select_target(panel, 0, ENEMY_COPY, "main_skill", "chance_delta", "chance_delta = 0.1")
	panel._render_rows(0)
	await process_frame
	var amount_key := panel._draft_key(SEED_121_COPY, "sub_skill", 0, "player_max_hp_rate")
	_expect(panel._drafts[0].has(amount_key) and bool(panel._drafts[0][amount_key].selected), "一覧の再描画後も100121を対象として保持")
	panel._save_tab(0)
	_expect(panel._drafts[0].is_empty(), "効果量の保存が成功する")
	(panel.get_node("Margin/Layout/Tabs") as TabContainer).current_tab = 1
	panel._render_rows(1)
	await process_frame
	await _select_target(panel, 1, SEED_110_COPY, "main_skill", "probabirlity", "probabirlity = ")
	await _select_target(panel, 1, ENEMY_COPY, "main_skill", "chance", "chance = 0.01")
	panel._save_tab(1)
	_expect(panel._drafts[1].is_empty(), "確率の保存が成功する")
	for path in identities:
		_expect(_resource_identity(path) == identities[path], "%s のUIDとサブResource IDを維持" % path)
	_verify_choices()
	panel.free()


func _save_enemy_copy() -> void:
	var source := ResourceLoader.load(ENEMY_SOURCE, "", ResourceLoader.CACHE_MODE_IGNORE) as EnemyInfo
	_expect(source != null, "テスト用の悪夢を読み込める")
	if source == null:
		return
	var copy := source.duplicate(true) as EnemyInfo
	var effect := copy.main_skill.effects[0] as EnemyEffect
	effect.effect_amount_configured = false
	effect.effect_amount_fields = PackedStringArray()
	effect.probability_configured = false
	effect.probability_fields = PackedStringArray()
	_expect(ResourceSaver.save(copy, ENEMY_COPY) == OK, "テスト用の悪夢コピーを保存できる")


func _select_target(
	panel: EffectFieldSettingsPanel, tab_index: int, path: String, slot: String,
	field: String, label_prefix: String
) -> void:
	var tab := panel.amount_tab if tab_index == 0 else panel.probability_tab
	var rows := tab.get_node("Scroll/Rows") as VBoxContainer
	for row in rows.get_children():
		if row is not HBoxContainer or row.get_child_count() < 3:
			continue
		if not String((row.get_child(0) as Label).text).begins_with(label_prefix):
			continue
		var target := row.get_child(1) as CheckBox
		(tab.get_node("Scroll") as ScrollContainer).ensure_control_visible(target)
		await process_frame
		_click(target)
		await process_frame
		var key := panel._draft_key(path, slot, 0, field)
		_expect(target.button_pressed, "%s の対象ボタンを選べる" % label_prefix)
		_expect(panel._drafts[tab_index].has(key) and bool(panel._drafts[tab_index][key].selected), "%s の対象選択を保存待ちにする" % label_prefix)
		return
	_expect(false, "%s の対象ボタンが見つかる" % label_prefix)


func _click(control: Control) -> void:
	var point := control.get_global_rect().get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)


func _verify_choices(from_backup: bool = false) -> void:
	var config := ConfigFile.new()
	_expect(config.load(SETTINGS_COPY) == OK, "対象選択の設定ファイルを読み込める")
	_expect((config.get_value("%s|sub_skill|0" % SEED_121_COPY, "amount_fields", PackedStringArray()) as PackedStringArray).has("player_max_hp_rate"), "100121の対象が設定ファイルにも残る")
	_expect((config.get_value("%s|main_skill|0" % SEED_110_COPY, "amount_fields", PackedStringArray()) as PackedStringArray).has("rate"), "100110の効果量が設定ファイルにも残る")
	_expect((config.get_value("%s|main_skill|0" % SEED_110_COPY, "probability_fields", PackedStringArray()) as PackedStringArray).has("probabirlity"), "100110の確率が設定ファイルにも残る")
	_expect((config.get_value("%s|main_skill|0" % ENEMY_COPY, "amount_fields", PackedStringArray()) as PackedStringArray).has("chance_delta"), "悪夢の効果量が設定ファイルにも残る")
	_expect((config.get_value("%s|main_skill|0" % ENEMY_COPY, "probability_fields", PackedStringArray()) as PackedStringArray).has("chance"), "悪夢の確率が設定ファイルにも残る")
	var cache_mode := ResourceLoader.CACHE_MODE_REUSE if from_backup else ResourceLoader.CACHE_MODE_IGNORE
	var seed_110 := ResourceLoader.load(SEED_110_COPY, "", cache_mode) as SeedInfo
	var seed_121 := ResourceLoader.load(SEED_121_COPY, "", cache_mode) as SeedInfo
	var enemy := ResourceLoader.load(ENEMY_COPY, "", cache_mode) as EnemyInfo
	_expect(seed_110 != null and seed_121 != null and enemy != null, "保存した3件を読み込める")
	if seed_110 == null or seed_121 == null or enemy == null:
		return
	var main_110 := seed_110.main_skill.effects[0] as SeedEffect
	var sub_121 := seed_121.sub_skill.effects[0] as SeedEffect
	var enemy_effect := enemy.main_skill.effects[0] as EnemyEffect
	_expect(main_110.effect_amount_fields.has("rate"), "100110の効果量対象が残る")
	_expect(main_110.probability_fields.has("probabirlity"), "100110の確率対象が残る")
	_expect(sub_121.effect_amount_fields.has("player_max_hp_rate"), "100121の効果量対象が残る")
	_expect(enemy_effect.effect_amount_fields.has("chance_delta"), "悪夢の効果量対象が残る")
	_expect(enemy_effect.probability_fields.has("chance"), "悪夢の確率対象が残る")
	if not from_backup:
		_expect(
			FileAccess.get_file_as_string(SEED_121_COPY).contains('effect_amount_fields = PackedStringArray("player_max_hp_rate")'),
			"100121の対象変数名がファイルに残る"
		)
	var panel := PANEL_SCENE.instantiate() as EffectFieldSettingsPanel
	root.add_child(panel)
	panel._resources[SEED_110_COPY] = seed_110
	panel._resources[SEED_121_COPY] = seed_121
	panel._resources[ENEMY_COPY] = enemy
	panel._catalog = [
		{"path": SEED_110_COPY, "kind": 0, "label": "夢の種 100110", "search": "100110"},
		{"path": SEED_121_COPY, "kind": 0, "label": "夢の種 100121", "search": "100121"},
		{"path": ENEMY_COPY, "kind": 1, "label": "悪夢 17020002004", "search": "17020002004"},
	]
	panel._render_rows(0)
	_expect(_target_checked(panel.amount_tab, "rate = 9"), "再起動した設定画面で100110の効果量対象が選択される")
	_expect(_target_checked(panel.amount_tab, "player_max_hp_rate = 30"), "再起動した設定画面で100121の効果量対象が選択される")
	_expect(_target_checked(panel.amount_tab, "chance_delta = 0.1"), "再起動した設定画面で悪夢の効果量対象が選択される")
	panel._render_rows(1)
	_expect(_target_checked(panel.probability_tab, "probabirlity = "), "再起動した設定画面で100110の確率対象が選択される")
	_expect(_target_checked(panel.probability_tab, "chance = 0.01"), "再起動した設定画面で悪夢の確率対象が選択される")
	panel.free()
	print("EffectFieldPersistenceTest: verified")


func _target_checked(tab: VBoxContainer, label_prefix: String) -> bool:
	for row in (tab.get_node("Scroll/Rows") as VBoxContainer).get_children():
		if row is HBoxContainer and row.get_child_count() >= 3:
			if String((row.get_child(0) as Label).text).begins_with(label_prefix):
				return (row.get_child(1) as CheckBox).button_pressed
	return false


func _resource_identity(path: String) -> PackedStringArray:
	var identity := PackedStringArray()
	for line in FileAccess.get_file_as_string(path).split("\n"):
		if line.begins_with("[gd_resource") or line.begins_with("[sub_resource"):
			identity.append(line)
	return identity


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EffectFieldPersistenceTest: %s" % message)
