extends Node

var _failures := 0
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _seed(number: int) -> SeedInfo:
	return load("res://data/resources/seeds/skills/seed_100_%d.tres" % number) as SeedInfo


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("SeedSkillAdjustmentTest: " + message)


func _enemy(cell: Vector2i, seed: SeedInfo = null) -> Enemy:
	var enemy := Enemy.new()
	var info := EnemyInfo.new()
	info.acid_block = AcidBlockInfo.new()
	info.acid_block.max_hp = 10000
	info.acid_block.stomach_shape = [PackedInt32Array([1])]
	enemy.data.setup(info, 10000, 100, false, false)
	enemy.seed_info = seed
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _run() -> void:
	_test_rates_and_growth()
	_test_day_end()
	_test_block_effects()
	await _test_game()
	print("SeedSkillAdjustmentTest: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)


func _test_rates_and_growth() -> void:
	var resolver := SeedEffectResolver.new()
	var seed := _seed(101)
	_expect(is_equal_approx(seed.main_skill.effects[0].rate, 1.1), "100101 actual Resource multiplier is 1.1")
	_expect(is_equal_approx(seed.main_skill.effects[0].get_acid_damage_rate(DreamSeedSkillState.new(), {}), 1.1), "effect API returns direct multiplier")
	resolver.setup([seed])
	_expect(resolver.get_acid_damage_breakdown(100, 0, 0).total == 110, "migration preserves main damage")
	resolver.add_Acided_seed_effect(seed)
	_expect(resolver.get_acid_damage_breakdown(100, 0, 0).total == 130, "migration preserves additive stacking")
	resolver.setup([_seed(103), _seed(103)])
	_expect(is_equal_approx(resolver.get_time_reduction_rate(), 0.8), "100103 migrated interval is still -20%, non-stacking")
	resolver.setup([_seed(124)])
	for index in range(3):
		resolver.apply_progress_time(index, index + 1)
	var rates := resolver.get_seed_time_reduction_rates(_seed(124))
	_expect(roundi(rates.main * 100) == 8 and roundi(rates.sub * 100) == 12, "100124 sub grows before digestion")
	resolver.add_Acided_seed_effect(_seed(124))
	resolver.refresh_flowers([])
	for index in range(25):
		resolver.apply_progress_time(index, index + 1)
	rates = resolver.get_seed_time_reduction_rates(_seed(124))
	_expect(roundi(rates.sub * 100) == 12, "100124 consumed sub freezes at 12%")
	resolver.setup([])
	_expect(resolver.get_time_reduction_rate() == 1, "100124 buff clears next stage")
	resolver.setup([_seed(123)])
	_expect(resolver.get_interval_minutes_delta(1559) == 60, "100123 before 2am +60 minutes")
	_expect(resolver.get_interval_minutes_delta(1560) == -10, "100123 at 2am -10 minutes")
	resolver.add_Acided_seed_effect(_seed(123), 1559)
	_expect(resolver.get_interval_minutes_delta(1560) == -30, "100123 sub snapshots -20 minutes")
	resolver.setup([])
	resolver.add_Acided_seed_effect(_seed(123), 1560)
	_expect(resolver.get_interval_minutes_delta(1600) == 120, "100123 late sub +120 minutes")


func _test_day_end() -> void:
	var state := RunState.new()
	state.planted_flowers = [_seed(106), _seed(106)]
	var rewards := StageClearCalculatorRecovery.get_selected_rewerd_context(state.planted_flowers, 1400)
	_expect(float(rewards.permanent_acid_rate) == 0, "100106 does not trigger on stage clear")
	state.current_minutes = 1500
	state.apply_day_finished_seed_effects()
	_expect(is_equal_approx(state.day_seed_acid_bonus, 0.2), "100106 two copies stack at day end")
	state.apply_day_finished_seed_effects()
	_expect(is_equal_approx(state.day_seed_acid_bonus, 0.4), "100106 increases by 10% per copy next day")
	state.current_minutes = 1501
	state.apply_day_finished_seed_effects()
	_expect(state.day_seed_acid_bonus == 0, "100106 late day resets accumulated effect")
	_expect(_seed(106).main_skill.effects.all(func(effect: SeedEffect) -> bool: return not effect is SeedEffectBringLimit), "100106 can be owned multiple times")


func _test_block_effects() -> void:
	var board := StomachBoard.new()
	board.columns = 4
	board.rows = 4
	var source := _enemy(Vector2i(1, 2), _seed(113))
	var line := _enemy(Vector2i(1, 3))
	var edge := _enemy(Vector2i(0, 0))
	var flower := _enemy(Vector2i(2, 3), _seed(101))
	var middle := _enemy(Vector2i(2, 1))
	var enemies: Array[Enemy] = [source, line, edge, flower, middle]
	var digested: Array[Enemy] = [source]
	var resolver := DreamSeedBlockAcidResolver.new()
	source.set_Acided(true)
	resolver.append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested)
	_expect(line.current_hp == 9920 and flower.current_hp == 10000, "100113 4x4x5=80 damage to line nightmares only")
	source.seed_info = _seed(114)
	resolver.append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested)
	_expect(edge.current_hp == 8500 and flower.current_hp == 8500, "100114 hits all stomach edges including top and seeds")
	_expect(middle.current_hp == 10000, "100114 excludes interior objects")
	source.seed_info = _seed(119)
	resolver.append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested)
	_expect(middle.current_hp == 25000, "100119 grows highest current HP by 150%")
	source.seed_info = _seed(121)
	var before := line.current_hp
	resolver.append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested, 0, 0, 7, 100, 120)
	_expect(line.current_hp == before - 3000, "100121 uses max HP 100, not current HP 7")
	source.seed_info = _seed(122)
	before = line.current_hp
	resolver.append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested, 0, 0, 7, 100, 180)
	_expect(line.current_hp == before - 1800, "100122 uses monotonic 180 minutes")
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(108)])
	var damage_resolver := EnemyDigestionResolver.new()
	damage_resolver.setup(effects, resolver, EnemyAcidDamageModifiers.new(), EnemyDigestionState.new())
	_expect(damage_resolver._get_final_damage(flower, enemies, 100) == 300, "100108 seed damage x3")
	_expect(damage_resolver._get_final_damage(middle, enemies, 100) == 100, "100108 nightmare unchanged")
	var housenka := _enemy(Vector2i.ZERO, _seed(105))
	housenka.take_acid_damage(100, false)
	housenka.set_Aciding(false)
	housenka.set_Aciding(true)
	housenka.take_acid_damage(100, false)
	_expect(housenka.current_hp == 9400 and housenka.received_acid_damage_total == 600, "100105 x3 persists across repeated entry, accumulated damage is actual damage")
	housenka.free()
	for enemy in enemies:
		enemy.free()
	board.free()


func _test_game() -> void:
	var game := (load("res://scene/main/game/game.tscn") as PackedScene).instantiate()
	add_child(game)
	await get_tree().process_frame
	var context := BattleInfo.new()
	context.day_start_minutes = 1200
	context.starting_minutes = 1320
	context.day_elapsed_minutes = 120
	context.flowers = [_seed(112), _seed(115), _seed(120), _seed(125), _seed(126)]
	game.start_battle(context)
	game._shift_clock(-60)
	_expect(game.minutes == 1260 and game.day_elapsed_minutes == 120, "rewind leaves accumulated minutes unchanged")
	game._shift_clock(60)
	_expect(game.day_elapsed_minutes == 180, "time re-traversed is counted again")
	var moon := _enemy(Vector2i.ZERO, _seed(106))
	moon.set_Acided(true)
	game._apply_Acided_seed_effects([moon] as Array[Enemy])
	_expect(game.minutes == 1200 and game.day_elapsed_minutes == 180, "100106 sub clamps to variable day start")
	game._shift_clock(-500)
	_expect(game.minutes == 1200, "nightmare rewind cannot precede variable day start")
	var lotus := _enemy(Vector2i.ZERO, _seed(112))
	var yugao := _enemy(Vector2i.ZERO, _seed(115))
	lotus.set_Acided(true)
	yugao.set_Acided(true)
	game._apply_Acided_seed_effects([lotus, yugao] as Array[Enemy])
	game._refresh_seed_structural_effects()
	_expect(game.stomach.columns == 7 and game.stomach.get_acid_line_rows() == 4, "100115 +2 columns and 100112 +2 lines survive structural refresh")
	_expect(game.get_base_stomach_columns() == 4, "sub-effect columns not exported as base size")
	var nightmare := _enemy(Vector2i.ZERO)
	game.hp = 100
	game.dragged_enemy_was_Aciding = true
	for index in range(3):
		nightmare.set_Aciding(true)
		game._remove_enemy_from_stomach(nightmare)
	_expect(game.hp == 70 and nightmare.current_hp == 9700, "three returns: player takes 10 each, nightmare takes 100 each")
	game.seed_effects.add_Acided_seed_effect(_seed(126))
	_expect(game.seed_effects.is_remove_from_stomach_disabled(), "100126 sub disables dragging return")
	_expect(game._get_remove_from_stomach_damage() == 20, "100126 doubles final 100125 return damage")
	game.seed_effects.setup([_seed(120), _seed(120)])
	nightmare.set_Acided(true)
	game.hp = 50
	game._apply_Acided_enemy_seed_effects([nightmare] as Array[Enemy])
	_expect(game.effective_max_hp == 110, "100120 two copies add 10% max HP")
	_expect(game.hp == 60, "100120 main heals the max HP increase")
	_expect(game._get_seed_dynamic_description_rates()[100120].main == 10, "100120 dynamic current bonus")
	DebugState.set_debug_enabled(true)
	game._on_debug_instant_clear_requested()
	_expect(not game.battle_active, "clear stage while sub skills are active")
	DebugState.set_debug_enabled(false)
	game.start_battle(context)
	_expect(game.stomach.columns == 5 and game.stomach.get_acid_line_rows() == 2, "next stage clears sub size and line buffs")
	_expect(game.effective_max_hp == 100 and not game.seed_effects.is_remove_from_stomach_disabled(), "next stage clears HP and return buffs")
	game.seed_effects.setup([_seed(118)])
	for enemy in [moon, lotus, yugao]:
		game.seed_effects.record_damaged_object(10, enemy)
	game.hp = 20
	game._apply_acid_damage_seed_heal()
	_expect(game.hp == 35, "100118 main heals 5 per damaged object")
	var mistletoe := _enemy(Vector2i.ZERO, _seed(118))
	mistletoe.set_Acided(true)
	game._apply_Acided_seed_effects([mistletoe] as Array[Enemy])
	_expect(game.hp == 65, "100118 sub heals 10 per damaged object")
	var previous_enemies: Array[Enemy] = game.enemies
	moon.set_Acided(false)
	moon.set_Aciding(true)
	moon.set_stomach_footprint_override(Vector2i(2, 2), [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.ONE], 4)
	lotus.set_Acided(false)
	lotus.set_Aciding(true)
	game.enemies = [moon, lotus] as Array[Enemy]
	game.seed_effects.setup([_seed(117)])
	game.hp = 20
	game._apply_time_seed_hp_recovery()
	_expect(game.hp == 35, "100117 heals 3% x five occupied cells, not two objects")
	game.enemies = previous_enemies
	await _test_digestion_batch(game)
	await _test_rotation_and_visual(game)
	for enemy in [moon, lotus, yugao, nightmare, mistletoe]:
		enemy.free()
	game.attack_se.stop()
	game.queue_free()
	await get_tree().process_frame


func _test_digestion_batch(game: Node) -> void:
	var context := BattleInfo.new()
	context.flowers = [_seed(118)]
	var info := EnemyInfo.new()
	info.acid_block = AcidBlockInfo.new()
	info.acid_block.max_hp = 10000
	info.acid_block.stomach_shape = [PackedInt32Array([1, 1])]
	var preset := EnemyPresetInfo.new()
	preset.enemies = [info, info]
	context.enemy_preset = preset
	game.start_battle(context)
	game.hp = 10
	var targets: Array[Enemy] = game.enemies
	targets[0].set_Aciding(true)
	game.stomach.place_enemy(targets[0], Vector2i(0, 4))
	var source := game.seed_controller._create_seed_block(_seed(118)) as Enemy
	game.enemies.append(source)
	source.set_Aciding(true)
	game.stomach.place_enemy(source, Vector2i(2, 4))
	var result: BattleTurnResultData = game._run_acid_core(game.minutes, 30)
	game._apply_acid_damage_seed_heal()
	_expect(game.hp == 20, "100118 actual batch counts two damaged objects, not three cells or outside enemy")
	_expect(result.Acided_enemies.has(source), "100118 actually digested in the line")
	game._apply_Acided_seed_effects(result.Acided_enemies)
	_expect(game.hp == 40, "100118 actual digestion sub heals twice 10 HP")
	game.seed_effects.setup([_seed(125), _seed(126)])
	game.seed_effects.add_Acided_seed_effect(_seed(126))
	var before_hp: int = game.hp
	var before_enemy_hp := targets[0].current_hp
	targets[0].set_Aciding(false)
	targets[0].forcibly_returned.emit()
	game._apply_forced_returns()
	_expect(game.hp == before_hp - 20, "forced return also applies final doubled player cost")
	_expect(targets[0].current_hp == before_enemy_hp - 200, "forced return deals 10 times actual doubled cost")
	game.seed_effects.setup([_seed(108)])
	game.acid_controller.refresh_enemy_effects(game.enemies, game.stomach)
	source.set_Acided(false)
	source.set_hp_values(1000, 1000)
	source.take_acid_damage(10, false)
	_expect(source.current_hp == 970, "100108 also triples damage from non-line effects")
	game.hp = 0
	var elapsed_before: int = game.day_elapsed_minutes
	game._apply_elapsed_time(30)
	_expect(game.day_elapsed_minutes == elapsed_before + 60, "revive counts normal time and rest once each")
	game.seed_effects.setup([_seed(125), _seed(126)])
	game.hp = 100
	var all_enemies: Array[Enemy] = game.enemies
	game.enemies = [targets[0]] as Array[Enemy]
	targets[0].set_hp_values(10000, 1)
	targets[0].set_Aciding(true)
	game.dragged_enemy_was_Aciding = true
	var hp_on_clear: Array[int] = []
	game.battle_finished.connect(func(_won: bool) -> void: hp_on_clear.append(game.hp), CONNECT_ONE_SHOT)
	game._remove_enemy_from_stomach(targets[0])
	_expect(hp_on_clear == [90], "lethal return pays player cost before stage-clear notification")
	game.enemies = all_enemies
	await get_tree().process_frame


func _test_rotation_and_visual(game: Node) -> void:
	game.start_battle(BattleInfo.new())
	var aura_seed := _seed(110).duplicate(true) as SeedInfo
	aura_seed.sub_skill.effects[0].enemies_only = false
	var source := game.seed_controller._create_seed_block(aura_seed) as Enemy
	var target_seed := _seed(124).duplicate(true) as SeedInfo
	target_seed.acid_block.stomach_shape = [PackedInt32Array([1, 1])]
	var target := game.seed_controller._create_seed_block(target_seed) as Enemy
	game.enemies.append(source)
	game.enemies.append(target)
	source.set_Aciding(true)
	target.set_Aciding(true)
	game.stomach.place_enemy(source, Vector2i(2, 1))
	game.stomach.place_enemy(target, Vector2i(1, 2))
	var resolver := DreamSeedBlockAcidResolver.new()
	_expect(resolver.get_target_acid_damage_multiplier(target, game.enemies) == 2.0, "adjacent aura before rotation")
	game._on_enemy_rotation_requested(target)
	_expect(target.get_stomach_size() == Vector2i(1, 2), "seed rotates inside stomach through game input handler")
	_expect(resolver.get_target_acid_damage_multiplier(target, game.enemies) == 1.0, "rotation removes lost adjacency effect")
	for index in range(3):
		game._on_enemy_rotation_requested(target)
	_expect(resolver.get_target_acid_damage_multiplier(target, game.enemies) == 2.0, "four rotations restore aura without stacking")
	var nightmare := game.enemies[0] as Enemy
	nightmare.set_Acided(false)
	var initial_size := nightmare.get_stomach_size()
	nightmare.set_Aciding(true)
	game._on_enemy_rotation_requested(nightmare)
	_expect(nightmare.get_stomach_size() == initial_size, "existing nightmare rotation prohibition remains enforced")
	nightmare.set_Aciding(false)
	for index in range(3):
		source.set_Aciding(false)
		_expect(resolver.get_target_acid_damage_multiplier(target, game.enemies) == 1.0, "aura removed on return")
		source.set_Aciding(true)
		_expect(resolver.get_target_acid_damage_multiplier(target, game.enemies) == 2.0, "aura restored exactly once on reinsertion")
	game._refresh_after_battle_event()
	game._set_hovered_enemy(null)
	game.ui.hide_enemy_tooltip()
	game.set_process_input(false)
	await get_tree().process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/agent-logs/seed-adjustment-game.png")
	var panel := game.get_node("UI/DebugPanel").seed_parameter_panel as DebugSeedParameterPanel
	DebugState.set_debug_enabled(true)
	panel.set_seed_inventory([_seed(124)], [])
	panel.open_panel()
	panel.status_label.text = "保存しました: res://data/resources/seeds/skills/seed_100_124.tres"
	game.ui.hide_enemy_tooltip()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(panel.status_label.get_line_count() == 1, "save message fits on one line")
	_expect(panel.status_label.get_theme_font_size("font_size") == 6, "save message font is about half of 11px")
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://.godot/agent-logs/seed-adjustment-panel.png")
	panel.close()
	DebugState.set_debug_enabled(false)
