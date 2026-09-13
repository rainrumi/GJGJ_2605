extends SceneTree

const PRESET_PATH := "res://data/resources/area/area_lunova/enemy/normal/002/area_lunova_enemy_normal_preset_002.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var preset := load(PRESET_PATH) as EnemyPresetInfo
	_expect(preset != null, "ルノヴァN-2の編成を読み込める")
	if preset == null:
		quit(_failures)
		return
	_expect(preset.enemies.size() == 2, "ルノヴァN-2の悪夢は2体")
	if preset.enemies.size() != 2:
		quit(_failures)
		return
	_expect(preset.enemies[0].skill_id == 17010002001, "E1を維持する")
	var info: EnemyInfo = preset.enemies[1]
	_expect(info.skill_id == 17010002002, "E2を維持しE3を編成から外す")
	_expect(info.description == "隣接するモノが提供する効果量を2倍する。", "E2の説明を更新する")
	var source := _create_enemy(info, Vector2i.ZERO)
	var adjacent := _create_enemy(info, Vector2i(1, 0))
	var distant := _create_enemy(info, Vector2i(3, 0))
	var effect := source.get_enemy_effects()[0] as EnemyEffectOnAdjacentObjectScaleEffect
	_expect(effect != null, "E2は隣接するモノの効果量を変更する")
	if effect != null:
		_expect(effect.effect_multiplier == 2.0, "効果量は2倍")
		var enemies: Array[Enemy] = [source, adjacent, distant]
		effect.bind_source(source)
		effect.setup_enemies(enemies)
		effect.apply()
		_expect(adjacent.data.defense_status.effect_multiplier == 2.0, "隣接するモノの効果量を2倍にする")
		_expect(distant.data.defense_status.effect_multiplier == 1.0, "隣接しないモノは変更しない")
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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("LunovaN2EnemyConfigTest: %s" % message)
