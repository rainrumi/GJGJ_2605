extends SceneTree

const E1_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_001.tres"
const E2_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_002.tres"
const SEED_PATH := "res://data/resources/seeds/skills/seed_100_121.tres"
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var e1_info := load(E1_PATH) as EnemyInfo
	var e2_info := load(E2_PATH) as EnemyInfo
	var seed_info := load(SEED_PATH) as SeedInfo
	_expect(e1_info != null and e2_info != null and seed_info != null, "E1・E2・オトギリソウを読み込める")
	if e1_info == null or e2_info == null or seed_info == null:
		quit(_failures)
		return
	var e1 := _create_enemy(e1_info, Vector2i.ZERO)
	var e2 := _create_enemy(e2_info, Vector2i(1, 0))
	var seed_block := ENEMY_SCENE.instantiate() as Enemy
	root.add_child(seed_block)
	seed_block.setup_seed(seed_info, Vector2.ONE)
	seed_block.set_stomach_cell(Vector2i(1, 1))
	seed_block.set_Aciding(true)
	var enemies: Array[Enemy] = [e1, e2, seed_block]
	var stomach := StomachBoard.new()
	var effects := EnemyEffectSystem.new()
	effects.setup(
		PlayerHealth.new(), EnemySpawnQueue.new(), BattleClock.new(), DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(), EnemyDigestionState.new(), EnemyEffectInheritance.new(),
		EnemyEffectStack.new(), EnemyEffectInstaller.new()
	)
	effects.refresh(enemies, stomach)
	_expect(e1.data.defense_status.effect_multiplier == 2.0, "E2がE1の効果量を2倍にする")
	_expect(seed_block.data.defense_status.effect_multiplier == 24.0, "E1の12倍とE2の2倍が種へ重なる")
	e1.max_hp = 100000
	e1.current_hp = 100000
	seed_block.set_Acided(true)
	var digested: Array[Enemy] = [seed_block]
	DreamSeedBlockAcidResolver.new().append_Acided_by_seed_block_effects(
		seed_block, enemies, stomach, 0, {}, digested, 0, 0, 100, 100
	)
	_expect(e1.current_hp == 28000, "HP上限100の3000%を24倍し、72000ダメージを与える")
	effects.reset()
	e1.free()
	e2.free()
	root.remove_child(seed_block)
	seed_block.free()
	stomach.free()
	quit(_failures)


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("LunovaN2EffectChainTest: %s" % message)
