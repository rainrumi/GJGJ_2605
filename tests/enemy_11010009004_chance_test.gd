extends SceneTree

const SOURCE_PATH := "res://data/resources/area/area_elmena/enemy/normal/009/area_elmena_enemy_normal_009_004.tres"
const TARGET_PATH := "res://data/resources/area/area_elmena/enemy/normal/009/area_elmena_enemy_normal_009_003.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var source_info := load(SOURCE_PATH) as EnemyInfo
	var target_info := load(TARGET_PATH) as EnemyInfo
	_expect(source_info != null and target_info != null, "対象Resourceを読み込める")
	if source_info == null or target_info == null:
		quit(_failures)
		return
	var source := _create_enemy(source_info, Vector2i.ZERO)
	var adjacent := _create_enemy(target_info, Vector2i(2, 0))
	var distant := _create_enemy(target_info, Vector2i(5, 0))
	var effects := source.get_enemy_effects()
	_expect(effects.size() == 1, "E4の効果が1つ")
	if effects.size() == 1:
		var effect := effects[0] as EnemyEffectOnAdjacentObjectChangeChance
		_expect(effect != null, "E4が隣接確率変更効果を持つ")
		if effect != null:
			_expect(effect.chance_multiplier == 2.0, "E4の確率倍率が2倍")
			var enemies: Array[Enemy] = [source, adjacent, distant]
			effect.bind_source(source)
			effect.setup_enemies(enemies)
			effect.apply()
			_expect(adjacent.data.defense_status.chance_multiplier == 2.0, "隣接対象だけ2倍")
			_expect(distant.data.defense_status.chance_multiplier == 1.0, "非隣接対象は等倍")
			_expect(source.data.defense_status.chance_multiplier == 1.0, "自身は等倍")
			_check_roll(adjacent, 0.4, 0.8, false)
			_check_roll(adjacent, 0.4, 0.2, true)
			adjacent.data.defense_status.reset_refresh_modifiers()
			_expect(adjacent.data.defense_status.chance_multiplier == 1.0, "再評価時に倍率を解除")
			effect.unbind()
	source.free()
	adjacent.free()
	distant.free()
	quit(_failures)


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _check_roll(enemy: Enemy, chance: float, expected_chance: float, invert: bool) -> void:
	for trial in range(32):
		seed(9017 + trial)
		var expected := randf() <= expected_chance
		seed(9017 + trial)
		_expect(EnemyEffectValueCalculator.roll(enemy, chance, invert) == expected, "確率判定に2倍補正を反映")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy11010009004ChanceTest: %s" % message)
