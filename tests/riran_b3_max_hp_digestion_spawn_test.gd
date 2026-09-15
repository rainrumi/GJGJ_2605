extends SceneTree

const E1_PATH := "res://data/resources/area/area_riran/enemy/boss/003/area_riran_enemy_boss_003_001.tres"
const E2_PATH := "res://data/resources/area/area_riran/enemy/boss/003/area_riran_enemy_boss_003_002.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_spawn_from_max_hp(E1_PATH, 64, 6, 256, 24, "E1")
	_check_spawn_from_max_hp(E2_PATH, 256, 24, 512, 48, "E2")
	quit(_failures)


func _check_spawn_from_max_hp(
	info_path: String,
	maximum_hp: int,
	attack_value: int,
	expected_spawn_hp: int,
	expected_spawn_attack: int,
	label: String
) -> void:
	var info := load(info_path) as EnemyInfo
	_expect(info != null, "%sの定義を読み込める" % label)
	if info == null:
		return

	var source := Enemy.new()
	source.data.setup(info, maximum_hp, attack_value, true, true)
	source.current_hp = 0
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnDigestedSpawnEnemy
	_expect(effect != null, "%sは消化時生成効果を持つ" % label)
	if effect == null:
		source.free()
		return
	_expect(effect.hp_source == EnemyEffect.ValueSource.SELF_MAX_HP, "%sの生成HP参照元はHP上限" % label)

	var queue := EnemySpawnQueue.new()
	effect.bind_source(source)
	effect.bind_owner(source.data, EnemyEffectStack.new())
	effect.setup_spawn_queue(queue)
	effect.apply()
	var requests := queue.consume()
	_expect(requests.size() == 2, "%sは寄生型悪夢を2体要求する" % label)
	for request in requests:
		_expect(request.max_hp == expected_spawn_hp, "%sの生成HPは%d" % [label, expected_spawn_hp])
		_expect(request.current_hp == expected_spawn_hp, "%sの生成現在HPは%d" % [label, expected_spawn_hp])
		_expect(request.damage == expected_spawn_attack, "%sの生成攻撃力は%d" % [label, expected_spawn_attack])
	effect.unbind()
	source.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranB3MaxHpDigestionSpawnTest: %s" % message)
