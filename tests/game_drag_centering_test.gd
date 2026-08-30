extends Node

const GAME_SCENE := preload("res://scene/main/game/game.tscn")

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game := GAME_SCENE.instantiate()
	add_child(game)
	await get_tree().process_frame
	(game.get_node("ClickSe") as AudioStreamPlayer).stream = null

	var enemy_info := EnemyInfo.new()
	enemy_info.acid_block = AcidBlockInfo.new()
	var preset := EnemyPresetInfo.new()
	preset.enemies = [enemy_info]
	var seed := SeedInfo.new()
	seed.acid_block = AcidBlockInfo.new()
	seed.sub_skill_mode = SeedInfo.SubSkillMode.Drag
	var context := BattleInfo.new()
	context.enemy_preset = preset
	context.flowers = [seed]
	game.start_battle(context)
	await get_tree().process_frame

	var enemies: Array[Enemy] = game.enemies
	var enemy := enemies[0]
	var enemy_mouse_position := enemy.global_position + Vector2(12.0, 8.0)
	game._on_enemy_drag_started(
		enemy,
		enemy_mouse_position,
		enemy.global_position - enemy_mouse_position,
		Vector2i.ZERO
	)
	await get_tree().create_timer(0.35).timeout
	game._on_enemy_drag_moved(enemy, enemy_mouse_position, Vector2.ZERO, Vector2i.ZERO)
	_expect(
		enemy.global_position.is_equal_approx(enemy_mouse_position),
		"悪夢の中心を0.3秒でマウス中心へ移動する"
	)
	var stomach := game.stomach as StomachBoard
	var preview_mouse_position := stomach.get_global_position_for_cell(Vector2i(1, 0), enemy.get_stomach_size())
	game._on_enemy_drag_moved(enemy, preview_mouse_position, Vector2.ZERO, Vector2i(1, 0))
	var preview := stomach.get_node("EnemyPlacementPreview") as Sprite2D
	_expect(preview.visible, "胃袋内で悪夢の設置予測が表示される")
	_expect(
		is_equal_approx(preview.global_position.x, enemy.global_position.x),
		"つかんだセルに関係なく設置予測の中心が悪夢の表示中心と一致する"
	)
	var preview_position := preview.global_position
	game._on_enemy_drag_released(enemy, preview_mouse_position)
	_expect(
		enemy.global_position.is_equal_approx(preview_position),
		"確定後の悪夢の位置が設置予測と一致する"
	)

	var seed_button := game.get_node("UI/SeedButtonList").get_child(0) as SeedButton
	var seed_controller := game.seed_controller as GameSeedController
	var seed_mouse_position := seed_button.global_position
	var result := seed_controller.start_drag(seed_button, seed, seed_mouse_position)
	_expect(result.started, "夢の種ブロックのドラッグを開始できる")
	var seed_block := result.seed_block
	var moved_seed_mouse_position := seed_mouse_position + Vector2(90.0, 40.0)
	await get_tree().create_timer(0.35).timeout
	seed_controller.move_drag(moved_seed_mouse_position, enemies)
	_expect(
		seed_block.global_position.is_equal_approx(moved_seed_mouse_position),
		"夢の種ブロックの中心を0.3秒でマウス中心へ移動する"
	)
	seed_controller.cancel_drag()

	game.cancel_battle()
	remove_child(game)
	game.free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameDragCenteringTest: %s" % message)
