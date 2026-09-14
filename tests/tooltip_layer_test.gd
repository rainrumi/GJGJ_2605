extends SceneTree

const TOOLTIP_LAYER := 100

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await _check_left_tooltip()
	await _check_seed_tooltip()
	await _check_enemy_tooltip()
	quit(_failures)


func _check_left_tooltip() -> void:
	var packed := load("res://scene/ui/battle_ui/tooltip/left/left_tooltip.tscn") as PackedScene
	_expect(packed != null, "LeftTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as LeftTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "LeftTooltip uses the foreground canvas layer")
	tooltip.set_title("Tooltip")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "LeftTooltip can be shown")
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	mouse_drag_state.begin_drag(self)
	_expect(not tooltip.visible, "LeftTooltip closes when dragging starts")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(not tooltip.visible, "LeftTooltip stays hidden while dragging")
	mouse_drag_state.end_drag(self)
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "LeftTooltip can be shown after dragging ends")
	_dispose(tooltip)


func _check_seed_tooltip() -> void:
	var packed := load("res://scene/ui/seed/tooltip/seed_tooltip.tscn") as PackedScene
	_expect(packed != null, "SeedTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as SeedTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "SeedTooltip uses the foreground canvas layer")
	tooltip.set_text("Tooltip")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "SeedTooltip can be shown")
	var mouse_drag_state := root.get_node("MouseDragState") as MouseDragTracker
	mouse_drag_state.begin_drag(self)
	_expect(not tooltip.visible, "SeedTooltip closes when dragging starts")
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(not tooltip.visible, "SeedTooltip stays hidden while dragging")
	mouse_drag_state.end_drag(self)
	tooltip.show_tooltip_at(Vector2(32.0, 32.0))
	_expect(tooltip.visible, "SeedTooltip can be shown after dragging ends")
	_dispose(tooltip)


func _check_enemy_tooltip() -> void:
	var packed := load("res://scene/object/enemy/tooltip/enemy_tooltip.tscn") as PackedScene
	_expect(packed != null, "EnemyTooltip scene loads")
	if packed == null:
		return
	var tooltip := packed.instantiate() as EnemyTooltip
	root.add_child(tooltip)
	await process_frame
	_expect(tooltip.layer == TOOLTIP_LAYER, "EnemyTooltip inherits the foreground canvas layer")
	var enemy := Enemy.new()
	var enemy_entries := tooltip.call("_get_enemy_entries", enemy, false) as Array
	_expect(enemy_entries[1].explanation == "効果", "悪夢ツールチップのメイン効果表示を短縮する")
	var nightmare := load("res://data/resources/area/area_lunova/enemy/normal/003/area_lunova_enemy_normal_003_001.tres") as EnemyInfo
	_expect(nightmare != null, "17010003001の悪夢定義を読み込む")
	if nightmare != null:
		enemy.data.definition = nightmare
		enemy.data.main_skill_active = true
		enemy.stomach_elapsed_minutes = 35
		tooltip.show_enemy(enemy, "", false)
		_expect(tooltip.call("_get_tooltip_text").ends_with("(経過時間:0.6時間)"), "効果文末に小数第一位の経過時間を表示する")
		enemy.stomach_elapsed_minutes = 90
		_expect(tooltip.call("_get_tooltip_text").contains("(経過時間:1.5時間)"), "表示中の時間変更をツールチップへ反映する")
	var n9_path := "res://data/resources/area/area_lunova/enemy/normal/009/area_lunova_enemy_normal_009_00%d.tres"
	var n9_e1 := load(n9_path % 1) as EnemyInfo
	_expect(n9_e1 != null, "ルノヴァN-9 E1の定義を読み込む")
	if n9_e1 != null:
		enemy.data.definition = n9_e1
		enemy.data.main_skill_active = true
		enemy.set_hp_values(12000, 12000)
		enemy.stomach_elapsed_minutes = 59
		tooltip.show_enemy(enemy, "", false)
		_expect(tooltip.call("_get_tooltip_text").contains("(経過時間:0時間)(失ったHP:0)"), "E1の初期値を表示する")
		enemy.stomach_elapsed_minutes = 125
		enemy.current_hp = 11750
		_expect(tooltip.call("_get_tooltip_text").contains("(経過時間:2時間)(失ったHP:250)"), "E1の経過時間と失HPを表示中に更新する")
		enemy.heal(100)
		_expect(tooltip.call("_get_tooltip_text").contains("(失ったHP:250)"), "回復してもE1の失HP累計を減らさない")
		enemy.data.hp.take_damage(400)
		_expect(tooltip.call("_get_tooltip_text").contains("(失ったHP:650)"), "実際に失ったHPをE1の表示へ加算する")
		var lost_hp_effect := EnemyEffect.new()
		lost_hp_effect.owner = enemy.data
		_expect(lost_hp_effect.resolve_value(EnemyEffect.ValueSource.LOST_HP) == 650, "E1の攻撃値にも失HP累計を使用する")
		tooltip.hide_tooltip()
		tooltip.show_enemy(enemy, "", false)
		_expect(tooltip.call("_get_tooltip_text").contains("(失ったHP:650)"), "E1を再表示しても失HP累計を保持する")
		var n9_attack := n9_e1.main_skill.effects[0].duplicate(true) as EnemyEffectOnElapsedTimeAttack
		_expect(n9_attack != null, "E1の時間経過攻撃を読み込む")
		if n9_attack != null:
			var player_health := PlayerHealth.new()
			n9_attack.bind_owner(enemy.data, null)
			n9_attack.bind_source(enemy)
			n9_attack.setup_player_health(player_health)
			n9_attack.begin_activation(ProgressTimeActivationData.new(30 * 60, 30 * 60))
			n9_attack.apply()
			n9_attack.end_activation()
			_expect(player_health.consume_damage().is_empty() and enemy.data.hp.lost_hp_total == 650, "攻撃間隔前は失HPを保持する")
			n9_attack.begin_activation(ProgressTimeActivationData.new(30 * 60, 60 * 60))
			n9_attack.apply()
			n9_attack.end_activation()
			_expect(player_health.consume_damage() == [650], "最初の攻撃に失HP累計を使う")
			_expect(enemy.data.hp.lost_hp_total == 0 and tooltip.call("_get_tooltip_text").contains("(失ったHP:0)"), "攻撃後に失HP表示をリセットする")
			enemy.data.hp.take_damage(200)
			n9_attack.begin_activation(ProgressTimeActivationData.new(2 * 60 * 60, 3 * 60 * 60))
			n9_attack.apply()
			n9_attack.end_activation()
			_expect(player_health.consume_damage() == [200], "複数回発火時に同じ失HPを重複使用しない")
			_expect(enemy.data.hp.lost_hp_total == 0, "複数回発火後も失HPをリセットする")
			n9_attack.unbind()
	for enemy_number in [2, 3]:
		var n9_enemy := load(n9_path % enemy_number) as EnemyInfo
		_expect(n9_enemy != null, "ルノヴァN-9 E%dの定義を読み込む" % enemy_number)
		if n9_enemy == null:
			continue
		enemy.data.definition = n9_enemy
		enemy.data.main_skill_active = true
		enemy.stomach_elapsed_minutes = 9
		tooltip.show_enemy(enemy, "", false)
		_expect(tooltip.call("_get_tooltip_text").contains("(経過時間:9分)"), "E%dの経過分を表示する" % enemy_number)
		enemy.stomach_elapsed_minutes = 31
		_expect(tooltip.call("_get_tooltip_text").contains("(経過時間:31分)"), "E%dの経過分を表示中に更新する" % enemy_number)
	var seed := SeedInfo.new()
	seed.display_name = "テストの種"
	enemy.seed_info = seed
	tooltip.show_enemy(enemy, "", false)
	var tooltip_text := tooltip.call("_get_tooltip_text") as String
	_expect(tooltip_text.begins_with("テストの種\n"), "夢の種ブロックは名称をタイトルとして表示する")
	_expect(not tooltip_text.contains("名称:"), "夢の種ブロックの名称に項目名を付けない")
	enemy.free()
	_dispose(tooltip)


func _dispose(node: Node) -> void:
	root.remove_child(node)
	node.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("TooltipLayerTest: %s" % message)
