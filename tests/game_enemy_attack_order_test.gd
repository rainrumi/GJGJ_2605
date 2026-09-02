extends SceneTree

const TARGET_PATH := "res://data/resources/area/area_iriyu/enemy/normal/001/area_iriyu_enemy_normal_001_001.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


# 時間進行効果で消化された悪夢が通常攻撃しないことを確認
func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	var enemy_info := load(TARGET_PATH) as EnemyInfo
	_expect(packed != null, "戦闘シーンを読める")
	_expect(enemy_info != null, "16010001001の定義を読める")
	if packed == null or enemy_info == null:
		quit(_failures)
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null
	(game.get_node("AttackSe") as AudioStreamPlayer).stream = null

	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [enemy_info]
	preset.enemies = enemy_infos
	var battle := BattleInfo.new()
	battle.starting_hp = 100
	battle.enemy_preset = preset
	game.call("start_battle", battle)
	await process_frame

	var enemies: Array[Enemy] = game.get("enemies")
	var target := enemies[0]
	var stomach := game.get_node("Stomach") as StomachBoard
	var bottom_left := Vector2i(0, stomach.rows - target.get_stomach_size().y)
	target.set_Aciding(true)
	stomach.place_enemy(target, bottom_left)
	game.call("_refresh_after_battle_event")
	_expect(stomach.get_bottom_row_cell_count(target) == 2, "対象を消化ラインへ2マス接触させる")

	game.call("_advance_acid_turn")
	await process_frame
	await process_frame
	_expect(target.is_Acided(), "時間進行効果の200ダメージで対象が消化される")
	_expect(game.call("get_current_hp") == 100, "時間進行効果で消化された対象は通常攻撃しない")
	await create_timer(EnemyDamagePopup.TOTAL_DURATION + 0.1).timeout

	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	target = null
	stomach = null
	game = null
	battle = null
	preset = null
	enemy_info = null
	packed = null
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemyAttackOrderTest: %s" % message)
