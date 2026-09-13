extends SceneTree

const PRESET_PATH := "res://data/resources/area/area_riran/enemy/normal/009/area_riran_enemy_normal_preset_009.tres"
const E3_PATH := "res://data/resources/area/area_riran/enemy/normal/009/area_riran_enemy_normal_009_002.tres"
const E4_PATH := "res://data/resources/area/area_riran/enemy/normal/009/area_riran_enemy_normal_009_004.tres"
const SOURCE_CELL := Vector2i(1, 2)
const E1_DIGESTION_DAMAGE := 75
const E3_DIGESTION_DAMAGE := 100

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scene/main/game/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var context := BattleInfo.new()
	context.enemy_preset = load(PRESET_PATH) as EnemyPresetInfo
	game.start_battle(context)
	var e1: Enemy = game.enemies[0]
	var e3_template := load(E3_PATH) as EnemyInfo
	var e4_template := load(E4_PATH) as EnemyInfo
	_expect(e3_template != null and e4_template != null, "E3とE4の定義を読み込む")
	if e3_template == null or e4_template == null:
		game.free()
		quit(_failures)
		return
	_expect(e1.get_enemy_info().skill_id == 20010009001, "生成親はE1")
	_expect(e1.get_enemy_info().main_skill.effects.size() == 1, "E1は消化時生成スキルを持つ")
	_expect(e1.get_main_effect_text() == "消化された時、この悪夢が最後に受けた消化ダメージ以下のダメージを無効化するスキルを持った寄生型悪夢を生成する。", "E1の説明文は生成効果のみ")
	var e1_spawn := e1.get_enemy_effects()[0] as EnemyEffectOnDigestedSpawnEnemy
	_expect(e1_spawn != null and e1_spawn.enemy_info == e3_template, "E1の生成先はE3")
	_expect(e3_template.skill_id == 20010009002 and e3_template.display_name == "E3", "E3のIDと表示名")
	_expect(e4_template.skill_id == 20010009004 and e4_template.display_name == "E4", "E4のIDと表示名")
	_expect(e3_template.main_skill.effects.size() == 2, "E3は無効化と消化時生成の2スキルを持つ")
	_expect(e3_template.description == "寄生元が消化時に受けた消化ダメージ以下のダメージを無効化する。消化された時、この悪夢が最後に受けた消化ダメージ以下のダメージを無効化するスキルを持った寄生型悪夢を生成する。", "E3の説明文は無効化と生成の両方")
	var e3_spawn_template := e3_template.main_skill.effects[1] as EnemyEffectOnDigestedSpawnEnemy
	_expect(e3_spawn_template != null and e3_spawn_template.enemy_info == e4_template, "E3の生成先はE4")
	_expect(e4_template.main_skill.effects.size() == 1, "E4は無効化スキルのみを持つ")
	var e3_description := e3_template.description
	var e4_description := e4_template.description

	e1.set_Aciding(true)
	game.stomach.place_enemy(e1, SOURCE_CELL)
	var e1_cells := e1.get_occupied_cells(SOURCE_CELL)
	e1.set_Acided(true)
	e1.data.stomach_status.publish_digestion(E1_DIGESTION_DAMAGE, 11, 60, 60, [e1.data])
	game.enemy_effects.execute()
	var e3_requests: Array[BattleSpawnEnemyData] = game.enemy_effects.consume_spawns()
	_expect(e3_requests.size() == 4, "E1の消化でE3を4体要求する")
	for request in e3_requests:
		_expect(request.enemy_info.skill_id == 20010009002, "生成要求はE3")
		_expect(request.source_cells == e1_cells, "消化前のE1占有マスを保持する")
		_expect(request.enemy_info.description.ends_with("(消化ダメージ:75ダメージ)"), "E3の説明文にE1の消化ダメージを記載する")
		var immunity := request.enemy_info.main_skill.effects[0] as EnemyEffectOnBattleIgnoreAcidDamageAtMost
		_expect(immunity != null and immunity.threshold == E1_DIGESTION_DAMAGE, "E3へE1の受領値を継承する")
		_expect(request.enemy_info.main_skill.effects.size() == 2, "E3の生成スキルを継承後も保持する")
	game.call("_apply_acid_spawn_requests", e3_requests)
	var e3_enemies := _find_active_enemies(game.enemies, 20010009002)
	_expect(e3_enemies.size() == 4, "E3を4体生成する")
	var spawned_cells: Array[Vector2i] = []
	for e3 in e3_enemies:
		spawned_cells.append(e3.stomach_cell)
		_expect(e3.get_main_effect_text().ends_with("(消化ダメージ:75ダメージ)"), "E3個体の説明文にE1の受領値を記載する")
		var blocked := e3.data.hp.request_damage(E1_DIGESTION_DAMAGE, e3.data)
		game.enemy_effects.execute()
		_expect(blocked.amount == 0, "E3はE1の受領値以下を0ダメージにする")
		var passed := e3.data.hp.request_damage(E1_DIGESTION_DAMAGE + 1, e3.data)
		game.enemy_effects.execute()
		_expect(passed.amount == E1_DIGESTION_DAMAGE + 1, "E3は閾値超過分を元のダメージで通す")
	_expect(spawned_cells.size() == e1_cells.size() and spawned_cells.all(func(cell: Vector2i) -> bool: return e1_cells.has(cell)), "E3をE1の占有マスに生成する")

	if not e3_enemies.is_empty():
		var parent: Enemy = e3_enemies[0]
		var parent_cell := parent.stomach_cell
		var fatal := parent.data.hp.request_damage(E3_DIGESTION_DAMAGE, parent.data)
		game.enemy_effects.execute()
		_expect(fatal.amount == E3_DIGESTION_DAMAGE, "E3の閾値を超える消化ダメージを適用する")
		_expect(parent.take_acid_damage(fatal.amount, false, false), "E3を消化する")
		parent.data.stomach_status.publish_digestion(fatal.amount, E3_DIGESTION_DAMAGE - 30, 60, 60, [parent.data])
		game.enemy_effects.execute()
		var e4_requests: Array[BattleSpawnEnemyData] = game.enemy_effects.consume_spawns()
		_expect(e4_requests.size() == 1, "E3の消化でE4を1体要求する")
		for request in e4_requests:
			_expect(request.enemy_info.skill_id == 20010009004, "E3の生成要求はE4")
			_expect(request.source_cells == [parent_cell], "E3の占有マスを保持する")
			_expect(request.enemy_info.description.ends_with("(消化ダメージ:100ダメージ)"), "E4の説明文にE3の受領値を記載する")
			var immunity := request.enemy_info.main_skill.effects[0] as EnemyEffectOnBattleIgnoreAcidDamageAtMost
			_expect(immunity != null and immunity.threshold == E3_DIGESTION_DAMAGE, "E4へE3の受領値を継承する")
		game.call("_apply_acid_spawn_requests", e4_requests)
		var e4_enemies := _find_active_enemies(game.enemies, 20010009004)
		_expect(e4_enemies.size() == 1, "E4を1体生成する")
		if e4_enemies.size() == 1:
			var e4: Enemy = e4_enemies[0]
			_expect(e4.stomach_cell == parent_cell, "E4をE3の消化位置に生成する")
			_expect(e4.get_main_effect_text().ends_with("(消化ダメージ:100ダメージ)"), "E4個体の説明文にE3の受領値を記載する")
			var blocked := e4.data.hp.request_damage(E3_DIGESTION_DAMAGE, e4.data)
			game.enemy_effects.execute()
			_expect(blocked.amount == 0, "E4はE3の受領値以下を無効化する")
			var passed := e4.data.hp.request_damage(E3_DIGESTION_DAMAGE + 1, e4.data)
			game.enemy_effects.execute()
			_expect(passed.amount == E3_DIGESTION_DAMAGE + 1, "E4は閾値超過ダメージを通す")
	_expect(e3_template.description == e3_description and e4_template.description == e4_description, "E3とE4の共有定義を変更しない")
	game.cancel_battle()
	game.enemy_effects.reset()
	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _find_active_enemies(enemies: Array[Enemy], skill_id: int) -> Array[Enemy]:
	var found: Array[Enemy] = []
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach() and enemy.get_enemy_info().skill_id == skill_id:
			found.append(enemy)
	return found


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranN9DigestionSpawnTest: %s" % message)
