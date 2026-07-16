extends SceneTree

const ENEMY_LEFT_X := 425.0
const ENEMY_CENTER_X := 500.0
const ENEMY_RIGHT_X := 575.0
const ENEMY_TOP_Y := 140.0
const ENEMY_BOTTOM_Y := 252.5

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 悪夢ページ表示試験
func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "戦闘シーンを読める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	var previous_button := game.get_node("UI/NightmarePreviousPageButton") as Button
	var next_button := game.get_node("UI/NightmareNextPageButton") as Button
	var click_se := game.get_node("ClickSe") as AudioStreamPlayer
	click_se.stream = null
	_expect(previous_button != null, "前ページボタンを構成する")
	_expect(next_button != null, "次ページボタンを構成する")
	_check_six_enemy_page(game, previous_button, next_button)
	_check_seven_enemy_pages(game, previous_button, next_button)
	_check_eleven_enemy_pages(game, previous_button, next_button)
	_check_thirteen_enemy_pages(game, previous_button, next_button)
	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	click_se = null
	previous_button = null
	next_button = null
	game = null
	packed = null
	await process_frame
	quit(_failures)


# 6体表示試験
func _check_six_enemy_page(game: Node, previous_button: Button, next_button: Button) -> void:
	_start_battle_with_enemy_count(game, 6)
	var enemies: Array[Enemy] = game.get("enemies")
	_expect_visible_range(enemies, 0, 6, 6, "6体編成の1ページ目")
	_expect(not previous_button.visible, "6体編成では前ページボタンを隠す")
	_expect(not next_button.visible, "6体編成では次ページボタンを隠す")


# 7体表示試験
func _check_seven_enemy_pages(game: Node, previous_button: Button, next_button: Button) -> void:
	_start_battle_with_enemy_count(game, 7)
	var enemies: Array[Enemy] = game.get("enemies")
	_expect_visible_range(enemies, 0, 6, 7, "7体編成の1ページ目")
	_expect(not previous_button.visible, "1ページ目では前ページボタンを隠す")
	_expect(next_button.visible, "7体編成の1ページ目では次ページボタンを表示する")
	next_button.pressed.emit()
	_expect_visible_range(enemies, 6, 7, 7, "7体編成の2ページ目")
	_expect(enemies[6].position == Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y), "1体のページは従来の1体配置を使う")
	_expect(previous_button.visible, "2ページ目では前ページボタンを表示する")
	_expect(not next_button.visible, "最終ページでは次ページボタンを隠す")
	previous_button.pressed.emit()
	_expect_visible_range(enemies, 0, 6, 7, "前ページへ戻った表示")


# 11体表示試験
func _check_eleven_enemy_pages(game: Node, previous_button: Button, next_button: Button) -> void:
	_start_battle_with_enemy_count(game, 11)
	var enemies: Array[Enemy] = game.get("enemies")
	next_button.pressed.emit()
	_expect_visible_range(enemies, 6, 11, 11, "11体編成の2ページ目")
	var expected_positions: Array[Vector2] = [
		Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y),
		Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y),
		Vector2(ENEMY_RIGHT_X, ENEMY_BOTTOM_Y),
		Vector2(ENEMY_LEFT_X, ENEMY_TOP_Y),
		Vector2(ENEMY_RIGHT_X, ENEMY_TOP_Y),
	]
	for i in range(expected_positions.size()):
		_expect(enemies[i + 6].position == expected_positions[i], "5体のページは従来の5体配置を使う: %d" % i)


# 13体表示試験
func _check_thirteen_enemy_pages(game: Node, previous_button: Button, next_button: Button) -> void:
	_start_battle_with_enemy_count(game, 13)
	var enemies: Array[Enemy] = game.get("enemies")
	next_button.pressed.emit()
	_expect(previous_button.visible, "中間ページでは前ページボタンを表示する")
	_expect(next_button.visible, "中間ページでは次ページボタンを表示する")
	next_button.pressed.emit()
	_expect_visible_range(enemies, 12, 13, 13, "13体編成の3ページ目")
	_expect(enemies[12].position == Vector2(ENEMY_LEFT_X, ENEMY_BOTTOM_Y), "3ページ目にも従来の1体配置を使う")
	_expect(previous_button.visible, "3ページ目では前ページボタンを表示する")
	_expect(not next_button.visible, "3ページ目では次ページボタンを隠す")


# 指定数の悪夢で戦闘開始
func _start_battle_with_enemy_count(game: Node, enemy_count: int) -> void:
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = []
	for i in range(enemy_count):
		var enemy_info := EnemyInfo.new()
		enemy_info.skill_id = i
		enemy_infos.append(enemy_info)
	preset.enemies = enemy_infos
	var battle := BattleInfo.new()
	battle.enemy_preset = preset
	game.call("start_battle", battle)


# 表示範囲確認
func _expect_visible_range(
	enemies: Array[Enemy],
	visible_start: int,
	visible_end: int,
	preset_count: int,
	message: String
) -> void:
	for i in range(preset_count):
		var expected_visible := i >= visible_start and i < visible_end
		_expect(enemies[i].visible == expected_visible, "%s: 悪夢%d" % [message, i])


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameEnemyPaginationTest: %s" % message)
