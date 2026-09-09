extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_clock_boundary()
	_test_enemy_only_damage()
	_test_digested_adjacency()
	_test_line_targets()
	await _test_sunflower_max_hp()
	print("DreamSeedDescriptionContractTest: %d failures" % _failures)
	quit(_failures)


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
	_expect(is_equal_approx(effects.get_time_reduction_rate(false, 1559), -0.5), "ヒツジグサは2時前に間隔+50%")
	_expect(is_equal_approx(effects.get_time_reduction_rate(false, 1560), 0.5), "ヒツジグサは2時ちょうどから間隔-50%")


func _test_enemy_only_damage() -> void:
	var effects := SeedEffectResolver.new()
	effects.setup([_seed(109)])
	var resolver := EnemyDigestionResolver.new()
	resolver.setup(effects, DreamSeedBlockAcidResolver.new(), EnemyAcidDamageModifiers.new(), EnemyDigestionState.new())
	var enemy := _enemy(Vector2i.ZERO)
	var flower := _enemy(Vector2i(3, 0), _seed(101))
	var enemies: Array[Enemy] = [enemy, flower]
	_expect(resolver._get_final_damage(enemy, enemies, 100) == 125, "モウセンゴケは悪夢に+25%")
	_expect(resolver._get_final_damage(flower, enemies, 100) == 100, "モウセンゴケは花に適用しない")
	var belladonna := _seed(110).duplicate(true) as SeedInfo
	var chance := belladonna.main_skill.effects[0] as SeedEffectOnFireAcidEnemyProbabilityChangeAcidDamageRate
	chance.probabirlity = 1.0
	effects.setup([belladonna])
	_expect(effects.get_acid_damage_breakdown(100, 0.0, 0).total == 100, "ベラドンナは表示用の全体ダメージで抽選しない")
	_expect(resolver._get_final_damage(enemy, enemies, 100) == 300, "ベラドンナ当選時は悪夢に追加200%")
	_expect(resolver._get_final_damage(flower, enemies, 100) == 100, "ベラドンナの抽選効果は花に適用しない")
	var aura := belladonna.sub_skill.effects[0]
	_expect(aura.get_seed_block_target_acid_multiplier({"target": enemy}) == 2.0, "ベラドンナの隣接悪夢は2倍")
	_expect(aura.get_seed_block_target_acid_multiplier({"target": flower}) == 1.0, "ベラドンナの隣接花は対象外")
	enemy.free()
	flower.free()


func _test_digested_adjacency() -> void:
	var source := _enemy(Vector2i.ZERO, _seed(118))
	var target := _enemy(Vector2i.RIGHT)
	var distant := _enemy(Vector2i(3, 0))
	var enemies: Array[Enemy] = [source, target, distant]
	var resolver := DreamSeedBlockAcidResolver.new()
	_expect(resolver.get_target_acid_damage_multiplier(target, enemies) == 1.0, "ヤドリギは消化前に隣接倍率を与えない")
	source.set_Acided(true)
	_expect(EnemyPlacementQuery.get_adjacent_enemies(source, enemies).is_empty(), "通常の隣接検索は消化済み発生源を除外")
	var digested: Array[Enemy] = [source]
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(is_equal_approx(target.acid_damage_taken_multiplier, 1.1), "消化済みヤドリギの位置から隣接対象へ+10%")
	_expect(distant.acid_damage_taken_multiplier == 1.0, "非隣接対象は変化しない")
	source.seed_info = _seed(122)
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(is_equal_approx(target.attack_multiplier, 0.5), "消化済みトリカブトの隣接攻撃力-50%")
	source.seed_info = _seed(114)
	resolver.append_Acided_by_seed_block_effects(source, enemies, null, 0, {}, digested)
	_expect(target.current_hp == 9000, "消化済みノイバラの隣接1000ダメージ")
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
	root.add_child(game)
	await process_frame
	game.seed_effects.setup([])
	var flower := _enemy(Vector2i.ZERO, _seed(120))
	flower.set_Acided(true)
	var digested: Array[Enemy] = [flower]
	var initial_hp: int = game.hp
	game._apply_Acided_seed_effects(digested)
	_expect(game.effective_max_hp == roundi(float(game.MAX_HP) * 1.1), "ヒマワリ消化時に実際のHP上限+10%")
	_expect(game.hp == initial_hp, "HP上限増加は回復を伴わない")
	flower.free()
	game.free()
	await process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("DreamSeedDescriptionContractTest: %s" % message)
