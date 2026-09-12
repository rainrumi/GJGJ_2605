extends Node

const RIRAN_STAGE_PATH := "res://data/resources/area/area_riran/area_riran.tres"

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	var stage := load(RIRAN_STAGE_PATH) as StageInfo
	_expect(packed != null, "戦闘シーンを読み込める")
	_expect(stage != null and stage.enemy_data != null, "リランのステージ定義を読み込める")
	if packed == null or stage == null or stage.enemy_data == null:
		get_tree().quit(_failures)
		return
	var presets := stage.enemy_data.normal_enemy_presets
	_expect(presets.size() == 9, "リランの通常敵がN-1からN-9まである")
	if presets.size() != 9:
		get_tree().quit(_failures)
		return

	var game := packed.instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var context := BattleInfo.new()
	context.stage_id = stage.stage_id
	context.stage = stage
	context.enemy_preset = presets[1]
	var run_state := RunState.new()
	var progress_key := "%d:%d" % [stage.stage_id, stage.stage_area]
	run_state.normal_enemy_preset_indices[progress_key] = 1
	game.start_battle(context)

	var next_enemy_button := game.get_node("UI/DebugPanel/DebugNextEnemyButton") as Button
	DebugState.set_debug_enabled(true)
	next_enemy_button.pressed.emit()
	_expect(game.current_enemy_preset == presets[2], "リラン-N-2からリラン-N-3へ切り替える")
	_expect(game.current_stage == stage, "切替後も同じエリアのステージ定義を使う")
	for _index in range(7):
		next_enemy_button.pressed.emit()
	_expect(game.current_enemy_preset == presets[0], "リラン-N-9の次はリラン-N-1へ戻る")
	game.retry_last_battle()
	_expect(game.current_enemy_preset == presets[0], "リトライは切替後の敵を維持する")
	_expect(run_state.pick_enemy_preset(stage) == presets[1], "デバッグ切替では正規の進行位置を変更しない")
	run_state.record_stage_clear(stage)
	_expect(run_state.pick_enemy_preset(stage) == presets[2], "切替後のクリアでも元のN-2の次はN-3になる")

	var boss_presets := stage.enemy_data.strengthened_enemy_presets
	_expect(boss_presets.size() == 3, "リランのボス敵がB-1からB-3まである")
	if boss_presets.size() == 3:
		context.enemy_preset = boss_presets[1]
		game.start_battle(context)
		next_enemy_button.pressed.emit()
		_expect(game.current_enemy_preset == boss_presets[2], "リラン-B-2からリラン-B-3へ切り替える")
		next_enemy_button.pressed.emit()
		_expect(game.current_enemy_preset == boss_presets[0], "リラン-B-3の次はリラン-B-1へ戻る")
		game.retry_last_battle()
		_expect(game.current_enemy_preset == boss_presets[0], "ボス戦のリトライも切替後の敵を維持する")

	DebugState.set_debug_enabled(false)
	get_tree().root.remove_child(game)
	game.free()
	next_enemy_button = null
	game = null
	run_state = null
	context = null
	presets.clear()
	boss_presets.clear()
	stage = null
	packed = null
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("GameDebugNextEnemyTest: %s" % message)
