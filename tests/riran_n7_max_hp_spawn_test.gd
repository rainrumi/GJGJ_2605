extends SceneTree

const ENEMY_DIR := "res://data/resources/area/area_riran/enemy/normal/007/"
const TARGET_IDS: Array[int] = [2, 5, 8]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for enemy_id in TARGET_IDS:
		_check_enemy(enemy_id)
	quit(_failures)


func _check_enemy(enemy_id: int) -> void:
	var path := ENEMY_DIR + "area_riran_enemy_normal_007_%03d.tres" % enemy_id
	var info := load(path) as EnemyInfo
	_expect(info != null, "E%dを読み込める" % enemy_id)
	if info == null:
		return
	var source := Enemy.new()
	source.data.setup(info, 100, 6, true, true)
	source.data.hp.set_current(25)
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnAcidDamageSpawnEnemy
	_expect(effect != null, "E%dは被消化ダメージ時に寄生型悪夢を生成する" % enemy_id)
	if effect != null:
		_expect(effect.hp_source == EnemyEffect.ValueSource.SELF_MAX_HP, "E%dの生成HP参照元は現在の最大HP" % enemy_id)
		_expect(info.description.contains("自身の現在の最大HPを持った寄生型悪夢を生成する。"), "E%dの説明文は現在の最大HP" % enemy_id)
		var queue := EnemySpawnQueue.new()
		effect.bind_source(source)
		effect.bind_owner(source.data, EnemyEffectStack.new())
		effect.setup_spawn_queue(queue)
		effect.apply()
		var spawned := queue.consume()
		_expect(spawned.size() == 2, "E%dは既存設定どおり2体の生成を要求する" % enemy_id)
		for data in spawned:
			_expect(data.max_hp == 100 and data.current_hp == 100, "E%dは残HP25ではなく最大HP100を引き継ぐ" % enemy_id)
		effect.unbind()
	source.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("RiranN7MaxHpSpawnTest: %s" % message)
