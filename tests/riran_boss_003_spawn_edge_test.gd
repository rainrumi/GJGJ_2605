extends SceneTree

const CASES := [
	{
		"label": "E3",
		"path": "res://data/resources/area/area_riran/enemy/boss/003/area_riran_enemy_boss_003_003.tres",
	},
	{
		"label": "E4",
		"path": "res://data/resources/area/area_riran/enemy/boss/003/area_riran_enemy_boss_003_004.tres",
	},
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for test_case in CASES:
		await _run_case(test_case.label, test_case.path)
	quit(_failures)


func _run_case(label: String, enemy_path: String) -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	var info := load(enemy_path) as EnemyInfo
	_expect(packed != null and info != null, "%sのゲームと悪夢定義を読み込める" % label)
	if packed == null or info == null:
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null

	var preset := EnemyPresetInfo.new()
	preset.enemies = [info]
	var context := BattleInfo.new()
	context.enemy_preset = preset
	game.call("start_battle", context)
	await process_frame

	var enemies: Array[Enemy] = game.get("enemies")
	var source := enemies[0]
	var stomach := game.get_node("Stomach") as StomachBoard
	source.set_hp_values(1, 1)
	source.set_damage_value(1)
	source.set_Aciding(true)
	stomach.place_enemy(source, Vector2i.ZERO)
	var enemy_count_before := enemies.size()

	game.call("_on_Acidion_requested")
	for _index in range(8):
		await process_frame

	var active_in_stomach := 0
	for enemy in enemies:
		if enemy != null and enemy.is_active_in_stomach():
			active_in_stomach += 1
	_expect(enemies.size() == enemy_count_before, "%s: HP1未満の生成で敵Nodeを増やさない" % label)
	_expect(active_in_stomach == 0, "%s: 消化後に新しい胃袋内悪夢を残さない" % label)
	_expect(source.is_Acided(), "%s: 元悪夢は消化済みになる" % label)
	_expect(source.max_hp == 1 and source.damage == 1, "%s: 生成失敗時に元悪夢の値を半減しない" % label)

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranBoss003SpawnEdgeTest: %s" % message)
