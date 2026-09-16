extends SceneTree

var _failures := 0
const SHEEP_PATH := "res://data/resources/seeds/skills/seed_100_123.tres"


func _initialize() -> void:
	var definition := load(
		"res://data/resources/area/area_huwahuwa/enemy/boss/005/area_huwahuwa_enemy_boss_005_001.tres"
	) as EnemyInfo
	_expect(definition != null, "ふわふわ学校B5の敵定義を読み込める")
	if definition != null:
		_expect_one_activation(definition, 60, "1分経過")
		_expect_one_activation(definition, 1800, "30分経過")
	_expect_final_interval_with_sheep(definition)
	quit(_failures)


func _expect_one_activation(definition: EnemyInfo, elapsed_seconds: int, label: String) -> void:
	var enemy := Enemy.new()
	enemy.data.setup(definition, 100000, 1, true, true)
	enemy.set_Aciding(true)
	var stomach := StomachBoard.new()
	var digestion_state := EnemyDigestionState.new()
	var clock := BattleClock.new()
	var stack := EnemyEffectStack.new()
	var installer := EnemyEffectInstaller.new()
	installer.setup(
		PlayerHealth.new(),
		EnemySpawnQueue.new(),
		clock,
		DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(),
		digestion_state,
		EnemyEffectInheritance.new(),
		stack,
		EnemyEffectRefreshProcessor.new()
	)
	installer.sync([enemy], stomach)

	clock.set_time(elapsed_seconds, elapsed_seconds)
	stack.execute()
	_expect(enemy.received_acid_damage_total == 9, "%sで消化ダメージは1回だけ" % label)
	_expect(enemy.get_current_hp() == enemy.get_max_hp(), "%sで生存時に全回復する" % label)

	installer.reset()
	enemy.free()
	stomach.free()


func _expect_final_interval_with_sheep(definition: EnemyInfo) -> void:
	var sheep := load(SHEEP_PATH) as SeedInfo
	_expect(sheep != null, "ヒツジグサの定義を読み込める")
	if sheep == null:
		return
	var enemy := Enemy.new()
	enemy.data.setup(definition, 100000, 1, true, true)
	enemy.set_Aciding(true)
	var stomach := StomachBoard.new()
	var digestion_state := EnemyDigestionState.new()
	var clock := BattleClock.new()
	var stack := EnemyEffectStack.new()
	var interval := DigestionInterval.new()
	var seed_effects := SeedEffectResolver.new()
	seed_effects.setup([sheep, sheep, sheep, sheep, sheep])
	var turn_processor := EnemyTurnProcessor.new()
	turn_processor.setup(seed_effects, EnemyEffectSystem.new(), interval, clock, digestion_state, 30)
	var installer := EnemyEffectInstaller.new()
	installer.setup(
		PlayerHealth.new(),
		EnemySpawnQueue.new(),
		clock,
		interval,
		EnemyAcidDamageModifiers.new(),
		digestion_state,
		EnemyEffectInheritance.new(),
		stack,
		EnemyEffectRefreshProcessor.new(),
		turn_processor
	)
	installer.sync([enemy], stomach)

	clock.set_time(60, 60)
	stack.execute()
	_expect(enemy.received_acid_damage_total == 31381059609, "5個のヒツジグサを含む最終消化間隔で指数ダメージを計算する")
	_expect(enemy.is_Acided(), "最終消化間隔の指数ダメージでHPが0になる")

	installer.reset()
	enemy.free()
	stomach.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HuwahuwaB5TimeEffectTest: %s" % message)
