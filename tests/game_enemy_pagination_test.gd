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
	var previous_button := game.get_node("UI/EnemyPreviousPageButton") as Button
	var next_button := game.get_node("UI/EnemyNextPageButton") as Button
	var return_hint := game.get_node("UI/EnemyReturnHint") as PanelContainer
	var return_damage_value_label := game.get_node("UI/EnemyReturnHint/CenterContainer/TextContainer/DamageRow/ValueLabel") as Label
	var click_se := game.get_node("ClickSe") as AudioStreamPlayer
	click_se.stream = null
	_expect(previous_button != null, "前ページボタンを構成する")
	_expect(next_button != null, "次ページボタンを構成する")
	_expect(return_hint != null, "悪夢吐き戻し案内を構成する")
	_expect(return_damage_value_label != null, "悪夢吐き戻しダメージ数値を構成する")
	_expect(return_damage_value_label.get_theme_color("font_color").is_equal_approx(Color(1, 0.2, 0.2)), "吐き戻しダメージ数値を赤色にする")
	var return_hint_style := return_hint.get_theme_stylebox("panel") as StyleBoxFlat
	_expect(return_hint_style != null, "悪夢吐き戻し案内に長方形パネルを構成する")
	_expect(
		return_hint_style != null and return_hint_style.bg_color.a > 0.0 and return_hint_style.bg_color.a < 1.0,
		"悪夢吐き戻し案内の背景を半透明にする"
	)
	_expect(return_hint.get_node_or_null("CenterContainer/TextContainer") != null, "吐き戻し文言をページ中央へ配置する")
	_expect(not return_hint.visible, "通常時は悪夢吐き戻し案内を隠す")
	_check_six_enemy_page(game, previous_button, next_button)
	_check_seven_enemy_pages(game, previous_button, next_button)
	_check_drag_compacts_enemy_page(game, previous_button, next_button, return_hint, return_damage_value_label)
	await _check_stomach_damage_visuals(game)
	await _check_time_effect_damage_visuals(game)
	_check_eleven_enemy_pages(game, previous_button, next_button)
	_check_thirteen_enemy_pages(game, previous_button, next_button)
	game.call("cancel_battle")
	root.remove_child(game)
	game.free()
	click_se = null
	previous_button = null
	next_button = null
	return_hint = null
	return_damage_value_label = null
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


# 胃袋への移動後の前詰め・吐き戻し案内・ページ再表示試験
func _check_drag_compacts_enemy_page(
	game: Node,
	previous_button: Button,
	next_button: Button,
	return_hint: PanelContainer,
	return_damage_value_label: Label
) -> void:
	_start_battle_with_enemy_count(game, 7)
	var enemies: Array[Enemy] = game.get("enemies")
	var stomach := game.get_node("Stomach") as StomachBoard
	var moved_enemy := enemies[1]
	var drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, moved_enemy.get_stomach_size())
	game.set("dragged_enemy_was_Aciding", false)
	game.set("drag_grab_cell", Vector2i.ZERO)
	game.call("_try_start_Aciding", moved_enemy, drop_position)
	_expect(moved_enemy.is_active_in_stomach(), "悪夢を胃袋へ移動できる")
	_expect(enemies[2].position == Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y), "空いた2枠目へ後続の悪夢を前詰めする")
	_expect(not previous_button.visible, "胃袋外が6体になったら前ページボタンを隠す")
	_expect(not next_button.visible, "胃袋外が6体になったら次ページボタンを隠す")
	game.call("_on_enemy_drag_started", moved_enemy, drop_position, Vector2.ZERO, Vector2i.ZERO)
	_expect(return_hint.visible, "胃袋内の悪夢をドラッグ中は吐き戻し案内を表示する")
	_expect(return_damage_value_label.text == "5", "吐き戻しダメージを正の値で表示する")
	game.call("_on_enemy_drag_released", moved_enemy, moved_enemy.origin_position)
	_expect(not return_hint.visible, "悪夢のドラッグ終了時は吐き戻し案内を隠す")
	_expect(not moved_enemy.is_active_in_stomach(), "悪夢を胃袋から取り出せる")
	_expect(enemies[1].position == Vector2(ENEMY_CENTER_X, ENEMY_TOP_Y), "戻った悪夢をページ内へ詰め直す")
	_expect(not previous_button.visible, "7体へ戻った1ページ目では前ページボタンを隠す")
	_expect(next_button.visible, "胃袋外が7体へ戻ったら次ページボタンを再表示する")


# 胃袋内の悪夢に対する被弾表示と死亡演出の維持試験
func _check_stomach_damage_visuals(game: Node) -> void:
	_start_battle_with_enemy_count(game, 7)
	var enemies: Array[Enemy] = game.get("enemies")
	var stomach := game.get_node("Stomach") as StomachBoard
	var enemy_setup := game.get("enemy_setup") as GameEnemySetupController
	var target := enemies[0]
	var drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, target.get_stomach_size())
	game.set("dragged_enemy_was_Aciding", false)
	game.set("drag_grab_cell", Vector2i.ZERO)
	game.call("_try_start_Aciding", target, drop_position)
	target.take_acid_damage(1, false)
	target.show_acid_damage_values([1])
	enemy_setup.refresh_enemy_page_visibility(enemies)
	_expect(target.visible, "胃袋内で被弾した悪夢をページ更新後も表示する")
	_expect(_has_visible_damage_popup(target), "胃袋内で受けたダメージ数を表示する")
	await create_timer(
		EnemyDamagePopup.DURATION * 2.0 + EnemyDamagePopup.HIDE_DELAY + 0.05
	).timeout
	_expect(not _has_visible_damage_popup(target), "被弾ダメージ数の表示を終了する")
	var lethal_damage := target.current_hp
	target.take_acid_damage(lethal_damage, false)
	target.show_acid_damage_values([lethal_damage])
	enemy_setup.refresh_enemy_page_visibility(enemies)
	await process_frame
	_expect(target.visible, "消化直後は死亡演出のため悪夢を表示したままにする")
	_expect(_has_visible_damage_popup(target), "死亡時もダメージ数を表示する")
	await create_timer(
		EnemyDamagePopup.DURATION * 2.0 + EnemyDamagePopup.HIDE_DELAY + 0.05
	).timeout
	_expect(not target.visible, "死亡演出の完了後に悪夢を隠す")


# 時間効果による消化ダメージ表示試験
func _check_time_effect_damage_visuals(game: Node) -> void:
	var skill := load(
		"res://data/resources/area/area_elmena/enemy/normal/001/area_elmena_enemy_normal_001_001.tres"
	) as EnemyInfo
	var preset := EnemyPresetInfo.new()
	var enemy_infos: Array[EnemyInfo] = [skill]
	preset.enemies = enemy_infos
	var battle := BattleInfo.new()
	battle.enemy_preset = preset
	game.call("start_battle", battle)
	var enemies: Array[Enemy] = game.get("enemies")
	var target := enemies[0]
	var stomach := game.get_node("Stomach") as StomachBoard
	var drop_position := stomach.get_global_position_for_cell(Vector2i.ZERO, target.get_stomach_size())
	game.set("dragged_enemy_was_Aciding", false)
	game.set("drag_grab_cell", Vector2i.ZERO)
	game.call("_try_start_Aciding", target, drop_position)
	for _index in range(3):
		game.call("_apply_elapsed_time", 30)
	var battle_results: Array[bool] = []
	game.connect("battle_finished", func(won: bool) -> void: battle_results.append(won), CONNECT_ONE_SHOT)
	game.call("_advance_acid_turn")
	await process_frame
	await process_frame
	_expect(target.is_Acided(), "11010001001の時間効果で対象が消化される")
	_expect(_has_visible_damage_popup_text(target, "-999"), "時間効果で受けた999消化ダメージを表示する")
	_expect(battle_results.is_empty(), "999消化ダメージの表示中はステージクリアを通知しない")
	await create_timer(EnemyDamagePopup.TOTAL_DURATION + 0.1).timeout
	_expect(not _has_visible_damage_popup(target), "999消化ダメージの表示完了後に演出待機を終える")
	_expect(battle_results == [true], "999消化ダメージの表示完了後にステージクリアを通知する")


# 表示中ダメージポップアップ有無
func _has_visible_damage_popup(enemy: Enemy) -> bool:
	for child in enemy.get_children():
		if child is Label and child.is_visible_in_tree():
			return true
	return false


# 指定文言の表示中ダメージポップアップ有無
func _has_visible_damage_popup_text(enemy: Enemy, text: String) -> bool:
	for child in enemy.get_children():
		if child is Label and child.is_visible_in_tree() and (child as Label).text == text:
			return true
	return false


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
