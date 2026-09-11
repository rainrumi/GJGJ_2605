extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_clock_boundary()
	_test_enemy_only_damage()
	_test_digested_adjacency()
	_test_line_targets()
	_test_persistence_and_counts()
	_test_fuji_and_tokon()
	_test_immediate_line_damage()
	await _test_sunflower_max_hp()
	await _test_player_heal_chain()
	print("DreamSeedDescriptionContractTest: %d failures" % _failures)
	get_tree().quit(_failures)


func _seed(number: int) -> SeedInfo:
	return load("res://data/resources/seeds/skills/seed_100_%d.tres" % number) as SeedInfo


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


func _test_clock_boundary() -> void:
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(123)])
	_expect(is_equal_approx(effects.get_interval_minutes_delta(1559), 60), "ヒツジグサは2時前に間隔+60分")
	_expect(is_equal_approx(effects.get_interval_minutes_delta(1560), -10), "ヒツジグサは2時ちょうどから間隔-10分")


func _test_enemy_only_damage() -> void:
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(109)])
	var resolver := EnemyDigestionResolver.new()
	resolver.setup(effects, DreamSeedBlockAcidResolver.new(), EnemyAcidDamageModifiers.new(), EnemyDigestionState.new())
	var enemy := _enemy(Vector2i.ZERO)
	var flower := _enemy(Vector2i(3, 0), _seed(101))
	var enemies: Array[Enemy] = [enemy, flower]
	_expect(resolver._get_final_damage(enemy, enemies, 100) == 150, "モウセンゴケの実データは悪夢に+50%")
	_expect(resolver._get_final_damage(flower, enemies, 100) == 100, "モウセンゴケは花に適用しない")
	var belladonna := _seed(110).duplicate(true) as SeedInfo
	var chance := belladonna.main_skill.effects[0] as SeedEffectOnFireAcidEnemyProbabilityChangeAcidDamageRate
	chance.probabirlity = 1.0
	effects.setup([belladonna])
	_expect(effects.get_acid_damage_breakdown(100, 0.0, 0).total == 100, "ベラドンナは表示用の全体ダメージで抽選しない")
	_expect(resolver._get_final_damage(enemy, enemies, 100) == 900, "ベラドンナ当選時は実データの9倍")
	_expect(resolver._get_final_damage(flower, enemies, 100) == 100, "ベラドンナの抽選効果は花に適用しない")
	var aura := belladonna.sub_skill.effects[0]
	_expect(aura.get_seed_block_target_acid_multiplier({"target": enemy}) == 2.0, "ベラドンナの隣接悪夢は2倍")
	_expect(aura.get_seed_block_target_acid_multiplier({"target": flower}) == 1.0, "ベラドンナの隣接花は対象外")
	enemy.free()
	flower.free()


func _test_digested_adjacency() -> void:
	var source := _enemy(Vector2i.ZERO, _seed(108))
	var target := _enemy(Vector2i.RIGHT, _seed(101))
	var distant := _enemy(Vector2i(3, 0), _seed(101))
	var enemies: Array[Enemy] = [source, target, distant]
	var resolver := DreamSeedBlockAcidResolver.new()
	source.set_Acided(true)
	_expect(EnemyPlacementQuery.get_adjacent_enemies(source, enemies).is_empty(), "通常の隣接検索は消化済み発生源を除外")
	var digested: Array[Enemy] = [source]
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(target.current_hp == 30000, "消化済みフジの位置から隣接花のHPを実データの3倍にする")
	_expect(distant.current_hp == 10000, "非隣接対象は変化しない")
	source.free()
	target.free()
	distant.free()


func _test_line_targets() -> void:
	var board := StomachBoard.new()
	board.rows = 3
	var enemy := _enemy(Vector2i(0, 2))
	var flower := _enemy(Vector2i(1, 2), _seed(101))
	var enemies: Array[Enemy] = [enemy, flower]
	var digested: Array[Enemy] = []
	_seed(111).sub_skill.effects[0].on_finish_acid_seed_block({
		"enemies": enemies, "stomach": board, "acided_enemies": digested,
		"acid_damage": 100, "acid_interval_minutes": 30,
	})
	_expect(enemy.current_hp == 8500 and flower.current_hp == 8500, "マツヨイグサは悪夢と花に3000を等分")
	enemy.free()
	flower.free()
	board.free()


func _test_sunflower_max_hp() -> void:
	var game := (load("res://scene/main/game/game.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	game.seed_effects.setup([])
	var flower := _enemy(Vector2i.ZERO, _seed(120))
	flower.set_Acided(true)
	var digested: Array[Enemy] = [flower]
	var initial_hp: int = game.hp
	game._apply_Acided_seed_effects(digested)
	_expect(game.effective_max_hp == roundi(float(game.MAX_HP) * 1.5), "ヒマワリ消化時に実際のHP上限+50%")
	_expect(game.hp == initial_hp + game.effective_max_hp - game.MAX_HP, "ヒマワリ消化時にHP上限の増加量だけ回復")
	flower.free()
	game.free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("DreamSeedDescriptionContractTest: %s" % message)


func _test_persistence_and_counts() -> void:
	for number in [101, 103, 107]:
		var effects := SeedEffectResolver.new()
		effects.setup([])
		effects.add_Acided_seed_effect(_seed(number), 1680)
		var damage: int = effects.get_acid_damage_breakdown(100, 0.0, 1680, true).total
		var interval := effects.get_time_reduction_rate(true, 1680)
		_expect(effects.get_acid_damage_breakdown(100, 0.0, 1680, true).total == damage, "%d消化強化が複数回持続" % number)
		_expect(is_equal_approx(effects.get_time_reduction_rate(true, 1680), interval), "%d間隔強化が複数回持続" % number)
		effects.setup([])
		_expect(effects.get_acid_damage_breakdown(100, 0.0, 1680).total == 100, "次の試合で消化強化リセット")
		_expect(effects.get_time_reduction_rate() == 1.0, "次の試合で間隔強化リセット")
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(124)])
	effects.apply_progress_time(100, 101)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 0.96), "クレマチス1分経過1回で4%")
	effects.apply_progress_time(101, 201)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 0.94), "100分経過も1回として6%")
	for index in range(30):
		effects.apply_progress_time(index, index + 1)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 0.6), "メイン上限40%")
	effects.refresh_flowers([])
	effects.add_Acided_seed_effect(_seed(124))
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 0.4), "消化後の副効果は消化前に蓄積した60%から開始")
	for index in range(30):
		effects.apply_progress_time(index, index + 1)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 0.4), "副効果は60%で固定")
	effects.setup([_seed(122)])
	effects.notify_hp_lost(80)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 1.02), "被ダメ80でも発生1回で間隔+2%")
	effects.notify_hp_lost(1)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 1.04), "2回目で+4%")
	for index in range(250):
		effects.notify_hp_lost(1)
	_expect(is_equal_approx(effects.get_time_reduction_rate(), 3.0), "トリカブト上限+200%")
	var controller: RefCounted = load("res://scene/main/game/controller/seed/game_seed_controller.gd").new()
	var flower := _enemy(Vector2i.ZERO, _seed(104))
	var flowers: Array[Enemy] = [flower]
	controller.apply_direct_Acided_seed_effects(flowers, 50, 100)
	_expect(controller.consume_rest_time_skip() and controller.consume_rest_time_skip(), "アネモネは複数回の蘇生で時間経過を無効化")
	controller.set_seed_inventory([], [])
	_expect(not controller.consume_rest_time_skip(), "アネモネ無効化は試合開始でリセット")
	flower.free()


func _test_fuji_and_tokon() -> void:
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(108), _seed(101)])
	_expect(effects.get_acid_damage_breakdown(100, 0.0, 0).total == 110, "フジのメインは全体の消化バフへ乗算しない")
	for flowers in [[_seed(125), _seed(126)], [_seed(126), _seed(125)]]:
		effects.setup(flowers)
		_expect(effects.get_remove_from_stomach_damage_rate(0.05) == 0.1, "装備順によらずトコンでHP上限10%のダメージ")
		_expect(is_equal_approx(effects.get_remove_from_stomach_acid_damage_rate(), 10.0), "ドクダミの悪夢への消化ダメージは維持")
	var source := _enemy(Vector2i.ZERO, _seed(108))
	var flower := _enemy(Vector2i.RIGHT, _seed(101))
	var enemy := _enemy(Vector2i.DOWN)
	var enemies: Array[Enemy] = [source, flower, enemy]
	source.set_Acided(true)
	var digested: Array[Enemy] = [source]
	var resolver := DreamSeedBlockAcidResolver.new()
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(flower.current_hp == 30000 and flower.acid_damage_taken_multiplier == 1.0, "フジのサブは隣接する花のHPだけ実データの3倍")
	_expect(enemy.current_hp == 10000 and enemy.acid_damage_taken_multiplier == 1.0, "フジのサブは悪夢を変更しない")
	source.seed_info = _seed(125)
	source.set_Acided(false)
	source.set_Aciding(true)
	source.current_hp = 10000
	_expect(not source.take_acid_damage(0, false), "トコンは0ダメージでは消化されない")
	_expect(source.take_acid_damage(1, false), "トコンは1ダメージでもHP0")
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(not enemy.is_active_in_stomach() and not enemy.is_Acided(), "トコンは隣接悪夢を吐き戻す")
	_expect(flower.is_active_in_stomach(), "トコンは花を吐き戻さない")
	source.free()
	flower.free()
	enemy.free()


func _test_immediate_line_damage() -> void:
	var board := StomachBoard.new()
	board.columns = 4
	board.rows = 4
	board._acid_line_rows = 2
	var edge := _enemy(Vector2i(0, 2))
	var center := _enemy(Vector2i(1, 2))
	var off_line := _enemy(Vector2i(0, 1))
	var flower := _enemy(Vector2i(3, 2), _seed(101))
	var enemies: Array[Enemy] = [edge, center, off_line, flower]
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(114)])
	effects.apply_progress_time(0, 30, enemies, board)
	_expect(edge.current_hp == 9500 and flower.current_hp == 9500, "ノイバラは端のライン上のモノに500")
	_expect(center.current_hp == 10000 and off_line.current_hp == 10000, "ノイバラは内側・ライン外に当たらない")
	effects.setup([_seed(121)])
	effects.add_heal_event(100, enemies, board)
	_expect(edge.current_hp == 9400 and center.current_hp == 9900, "オトギリソウは回復時に即座に回復量と同じ100ダメージ")
	_expect(flower.current_hp == 9500 and off_line.current_hp == 10000, "回復攻撃はライン内の悪夢だけ")
	_expect(effects.get_acid_damage_breakdown(100, 0.0, 0).total == 100, "回復攻撃を次回通常ダメージへ加算しない")
	var source := _enemy(Vector2i(1, 1), _seed(121))
	source.set_Acided(true)
	enemies.append(source)
	var digested: Array[Enemy] = [source]
	DreamSeedBlockAcidResolver.new().append_Acided_by_seed_block_effects(source, enemies, board, 0, {}, digested, 100, 30, 70, 100)
	_expect(center.current_hp == 6900 and off_line.current_hp == 7000, "オトギリソウ副効果はHP上限100の30倍3000")
	for enemy in enemies:
		enemy.free()
	board.free()


func _test_player_heal_chain() -> void:
	var game := (load("res://scene/main/game/game.tscn") as PackedScene).instantiate()
	get_tree().root.add_child(game)
	await get_tree().process_frame
	var source := _enemy(Vector2i(0, 1), _seed(119))
	var target := _enemy(Vector2i(0, 2))
	var second := _enemy(Vector2i(1, 2))
	var enemies: Array[Enemy] = [source, target, second]
	game.enemies = enemies
	game.stomach.rows = 3
	game.hp = 10
	game.seed_effects.setup([_seed(121)])
	target.set_Acided(true)
	second.current_hp = 5
	var digested: Array[Enemy] = [target]
	game._recover_player(20)
	_expect(game.hp == 30, "20回復を起点に消化連鎖を処理する")
	_expect(second.is_Acided(), "その回復でオトギリソウの即時攻撃が発動")
	var extra: Array[Enemy] = game._resolve_extra_seed_digestions()
	_expect(extra.has(second) and extra.size() == 1, "即時攻撃の消化を重複せず回収")
	game.hp = 10
	source.set_Acided(true)
	var sources: Array[Enemy] = [source]
	game._apply_Acided_seed_effects(sources)
	_expect(game.hp == 10, "ラフレシア自身の消化では20%回復しない")
	game.enemies = [] as Array[Enemy]
	for enemy in enemies:
		enemy.free()
	game.free()
	await get_tree().process_frame
