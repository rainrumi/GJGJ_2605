extends SceneTree

const ENEMY_DIR := "res://data/resources/area/area_riran/enemy/normal/006/"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var first := load(ENEMY_DIR + "area_riran_enemy_normal_006_001.tres") as EnemyInfo
	var second := load(ENEMY_DIR + "area_riran_enemy_normal_006_002.tres") as EnemyInfo
	var third := load(ENEMY_DIR + "area_riran_enemy_normal_006_003.tres") as EnemyInfo
	if first == null or second == null or third == null:
		_expect(false, "リランN-6のE1、E2、E3を読み込める")
		quit(_failures)
		return

	var e1 := first.main_skill.effects[0] as EnemyEffectOnDigestedSpawnEnemy
	var e2 := second.main_skill.effects[0] as EnemyEffectOnDigestedDealAdjacentInheritedOverkillAcidDamage
	var e3 := third.main_skill.effects[0] as EnemyEffectOnDigestedSpawnEnemy
	_expect(e1 != null and e2 != null and e3 != null, "指定された消化時効果が設定されている")
	if e1 == null or e2 == null or e3 == null:
		quit(_failures)
		return

	_expect(e1.enemy_info == second, "E1がE2を生成する")
	_expect(e1.spawn_count == 4 and e1.max_spawn_count == 4, "E1の生成上限は4マス")
	_expect(e1.spawn_area == EnemyEffect.SpawnArea.EMPTY_STOMACH, "E1は空き胃袋マスに生成する")
	_expect(e1.hp_base == 120 and e1.hp_source == EnemyEffect.ValueSource.FIXED, "E1の生成HPは120")
	_expect(e2.target == EnemyEffect.EffectTarget.ADJACENT_OBJECTS, "E2は隣接するモノを対象にする")
	_expect(second.description == "消化された時、隣接するモノに自身の消化時に受けた超過ダメージ分の消化ダメージを与える。", "E2の説明文")
	_expect(e3.spawn_count == 1 and e3.enemy_info.skill_id == 20010006004, "E3はE4を1体生成する")
	_expect(e3.hp_base == 120 and e3.hp_source == EnemyEffect.ValueSource.FIXED, "E3の生成HPは120")
	_expect(e3.attack_base == 0 and e3.attack_source == EnemyEffect.ValueSource.OVERKILL_DAMAGE, "E3のATは自身の消化時の超過ダメージ")

	var source := Enemy.new()
	var other := Enemy.new()
	var own_digestion := DigestedActivationData.new()
	own_digestion.setup(source, 135, 15, 0, 0, [source])
	var other_digestion := DigestedActivationData.new()
	other_digestion.setup(other, 150, 30, 0, 0, [other])
	e2.bind_source(source)
	_expect(e2.accepts_activation(own_digestion), "E2は自身の消化で発動する")
	_expect(not e2.accepts_activation(other_digestion), "E2は他の悪夢の消化では発動しない")
	e2.begin_activation(own_digestion)
	_expect(e2.get_activation_overkill_damage() == 15, "E2の消化ダメージは自身の超過ダメージを参照する")
	source.data.setup(second, 120, 6, true, true)
	other.data.setup(second, 100, 6, true, true)
	source.set_stomach_cell(Vector2i.ZERO)
	other.set_stomach_cell(Vector2i(1, 0))
	source.set_Acided(true)
	other.set_Aciding(true)
	var enemies: Array[Enemy] = [source, other]
	e2.setup_enemies(enemies)
	e2.setup_digestion_state(EnemyDigestionState.new())
	e2.apply()
	_expect(other.get_current_hp() == 85, "E2が消化済みの自身に隣接するモノへ超過ダメージ15を与える")
	e2.end_activation()

	var queue := EnemySpawnQueue.new()
	e1.bind_source(source)
	e1.setup_spawn_queue(queue)
	e1.begin_activation(own_digestion)
	e1.apply()
	var spawned := queue.consume()
	_expect(spawned.size() == 4, "E1が最大4体を生成要求する")
	for data in spawned:
		_expect(data.max_hp == 120 and data.current_hp == 120, "E1の寄生型悪夢はHP120")
		_expect(data.spawn_area == EnemyEffect.SpawnArea.EMPTY_STOMACH, "E1の寄生型悪夢は空きマスに置く")
	e1.end_activation()

	e3.bind_source(source)
	e3.setup_spawn_queue(queue)
	e3.begin_activation(own_digestion)
	e3.apply()
	spawned = queue.consume()
	_expect(spawned.size() == 1, "E3は1体を生成要求する")
	if spawned.size() == 1:
		_expect(spawned[0].max_hp == 120 and spawned[0].damage == 15, "E3の寄生型悪夢はHP120、ATは超過ダメージ15")
	e3.end_activation()
	source.free()
	other.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranN6SkillTest: %s" % message)
