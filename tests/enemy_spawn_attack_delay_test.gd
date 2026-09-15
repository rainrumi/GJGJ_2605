extends SceneTree

var _failures := 0


class TestEnemyEffectSystem:
	extends EnemyEffectSystem


	func refresh(_enemies: Array[Enemy], _stomach: StomachBoard) -> void:
		pass


	func prepare(_enemies: Array[Enemy], _stomach: StomachBoard) -> void:
		pass


	func consume_player_damage() -> Array[int]:
		return []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_spawned_enemy_attack_delay()
	_test_stomach_elapsed_minutes_includes_clock_delta()
	_test_seed_block_attack()
	_test_elapsed_time_acid_damage_uses_own_accumulation()
	quit(_failures)


func _test_spawned_enemy_attack_delay() -> void:
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup([])
	var enemy_effects := TestEnemyEffectSystem.new()
	var enemy := Enemy.new()
	enemy.damage = 7
	enemy.set_Aciding(true)
	var enemies: Array[Enemy] = [enemy]

	var attack_resolver := EnemyAttackResolver.new()
	attack_resolver.setup(seed_effects, enemy_effects, 50)
	_expect(
		attack_resolver.resolve(enemies, null, 0).is_empty(),
		"胃袋内経過分数が0の生成直後の悪夢は通常攻撃しない"
	)
	enemy.stomach_elapsed_minutes = 40
	_expect(
		attack_resolver.resolve(enemies, null, 40) == [7],
		"胃袋内で時間が経過した悪夢は通常攻撃する"
	)

	var interval := DigestionInterval.new()
	interval.add_seconds(10 * 60)
	var turn_processor := EnemyTurnProcessor.new()
	turn_processor.setup(
		seed_effects,
		enemy_effects,
		interval,
		BattleClock.new(),
		EnemyDigestionState.new(),
		30
	)
	enemy.stomach_elapsed_minutes = 0
	var elapsed_minutes := turn_processor.begin_turn(enemies, null, 0)
	_expect(elapsed_minutes == 40, "補正後の消化間隔をターン経過分として返す")
	_expect(enemy.stomach_elapsed_minutes == 40, "悪夢へ補正後の消化間隔を加算する")

	enemy.free()


func _test_stomach_elapsed_minutes_includes_clock_delta() -> void:
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup([])
	var enemy_effects := TestEnemyEffectSystem.new()
	var enemy := Enemy.new()
	enemy.set_Aciding(true)
	var enemies: Array[Enemy] = [enemy]
	var turn_processor := EnemyTurnProcessor.new()
	turn_processor.setup(
		seed_effects,
		enemy_effects,
		DigestionInterval.new(),
		BattleClock.new(),
		EnemyDigestionState.new(),
		30
	)

	turn_processor.begin_turn(enemies, null, 100, 30)
	_expect(enemy.stomach_elapsed_minutes == 30, "初回は今ターンの経過時刻を加算する")
	turn_processor.begin_turn(enemies, null, 145, 30)
	_expect(
		enemy.stomach_elapsed_minutes == 75,
		"前回記録後にゲーム時刻へ追加された15分と今ターンの30分を加算する"
	)
	turn_processor.begin_turn(enemies, null, 120, 30)
	_expect(
		enemy.stomach_elapsed_minutes == 105,
		"ゲーム時刻が前回記録時刻より前でも負の差分を加算しない"
	)

	enemy.free()


func _test_seed_block_attack() -> void:
	var packed := load("res://scene/object/enemy/enemy.tscn") as PackedScene
	var seed_info := load("res://data/resources/seeds/skills/seed_100_101.tres") as SeedInfo
	_expect(packed != null and seed_info != null, "夢の種ブロックのSceneと定義を読める")
	if packed == null or seed_info == null:
		return
	var seed_block := packed.instantiate() as Enemy
	root.add_child(seed_block)
	seed_block.setup_seed(seed_info, Vector2(40, 40))
	seed_block.set_Aciding(true)
	seed_block.stomach_elapsed_minutes = 30
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup([])
	var attack_resolver := EnemyAttackResolver.new()
	attack_resolver.setup(seed_effects, TestEnemyEffectSystem.new(), 0)
	var objects: Array[Enemy] = [seed_block]
	_expect(seed_block.get_damage() == 0, "通常の夢の種ブロックは攻撃力0")
	_expect(attack_resolver.resolve(objects, null, 30).is_empty(), "攻撃力0ではプレイヤーにダメージを与えない")

	seed_block.add_damage(5)
	seed_block.data.defense_status.add_extra_attacks(1)
	_expect(seed_block.get_display_damage() == 5, "増加した夢の種ブロックの攻撃力を表示する")
	_expect(attack_resolver.resolve(objects, null, 30) == [5, 5], "攻撃力が増えた夢の種ブロックは追加攻撃も行う")
	root.remove_child(seed_block)
	seed_block.free()


func _test_elapsed_time_acid_damage_uses_own_accumulation() -> void:
	var enemy := Enemy.new()
	enemy.max_hp = 2000
	enemy.current_hp = 2000

	var effect := EnemyEffectOnElapsedTimeTakeAcidDamage.new()
	effect.interval_seconds = 40 * 60
	effect.damage = 999
	effect.bind_source(enemy)
	effect.setup_digestion_state(EnemyDigestionState.new())

	effect.begin_activation(ProgressTimeActivationData.new(30 * 60, 30 * 60))
	effect.apply()
	effect.end_activation()
	_expect(enemy.current_hp == 2000, "胃袋内の経過時間が間隔未満なら消化ダメージを受けない")

	effect.begin_activation(ProgressTimeActivationData.new(10 * 60, 40 * 60))
	effect.apply()
	effect.end_activation()
	_expect(enemy.current_hp == 1001, "同じ悪夢自身の胃袋内累積時間が間隔へ達した時だけ発火する")

	enemy.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemySpawnAttackDelayTest: %s" % message)
