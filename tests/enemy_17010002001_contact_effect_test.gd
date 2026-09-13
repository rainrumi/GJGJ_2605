extends SceneTree

const SOURCE_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_002_001.tres"
const OTHER_SOURCE_PATH := "res://data/resources/area/area_iriyu/enemy/normal/006/area_iriyu_enemy_normal_006_003.tres"
const SEED_PATH := "res://data/resources/seeds/skills/seed_100_102.tres"
const ENEMY_SCENE := preload("res://scene/object/enemy/enemy.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_info := load(SOURCE_PATH) as EnemyInfo
	var seed_info := load(SEED_PATH) as SeedInfo
	_expect(source_info != null and seed_info != null, "悪夢と1マスの夢の種を読み込める")
	if source_info == null or seed_info == null:
		quit(_failures)
		return
	_expect(seed_info.acid_block.get_cell_count() == 1, "夢の種は1マス")
	var source := _create_source(source_info)
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnAdjacentObjectScaleEffect
	_expect(effect != null and effect.required_contact_count == 3, "接触3箇所の効果設定")
	if effect == null:
		source.free()
		quit(_failures)
		return
	var seed_block := _create_seed(seed_info, Vector2i(1, 0))
	var one_contact := _create_seed(seed_info, Vector2i(0, -1))
	var another_contact := _create_seed(seed_info, Vector2i(2, -1))
	var third_contact := _create_seed(seed_info, Vector2i(3, 0))
	var enemies: Array[Enemy] = [source, seed_block, one_contact, another_contact, third_contact]
	effect.bind_source(source)
	effect.setup_enemies(enemies)
	effect.apply()
	_expect(seed_block.data.defense_status.effect_multiplier == 1.0, "2辺接触の種は強化されない")
	_expect(one_contact.data.defense_status.effect_multiplier == 1.0, "1辺接触のモノが3個いても強化されない")
	seed_block.set_stomach_cell(Vector2i(1, 1))
	effect.apply()
	_expect(seed_block.data.defense_status.effect_multiplier == 6.0, "くぼみで3辺接触する1個の種を6倍にする")
	_expect(one_contact.data.defense_status.effect_multiplier == 1.0, "3辺接触しない別の種は強化されない")
	effect.unbind()
	source.free()
	for enemy in [seed_block, one_contact, another_contact, third_contact]:
		root.remove_child(enemy)
		enemy.free()
	_test_other_adjacent_effect(seed_info)
	quit(_failures)


func _test_other_adjacent_effect(seed_info: SeedInfo) -> void:
	var info := load(OTHER_SOURCE_PATH) as EnemyInfo
	_expect(info != null, "既存の隣接強化悪夢を読み込める")
	if info == null:
		return
	var source := _create_source(info)
	var target := _create_seed(seed_info, Vector2i(-1, 0))
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnAdjacentObjectScaleEffect
	_expect(effect != null and effect.required_contact_count == 1, "従来の悪夢は1辺接触のまま")
	if effect != null:
		var enemies: Array[Enemy] = [source, target]
		effect.bind_source(source)
		effect.setup_enemies(enemies)
		effect.apply()
		_expect(target.data.defense_status.effect_multiplier == 2.0, "従来の隣接強化は1辺で発動する")
		effect.unbind()
	source.free()
	root.remove_child(target)
	target.free()


func _create_source(info: EnemyInfo) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(Vector2i.ZERO)
	enemy.set_Aciding(true)
	return enemy


func _create_seed(info: SeedInfo, cell: Vector2i) -> Enemy:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	root.add_child(enemy)
	enemy.setup_seed(info, Vector2.ONE)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy17010002001ContactEffectTest: %s" % message)
