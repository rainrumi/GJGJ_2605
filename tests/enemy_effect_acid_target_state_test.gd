extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var info := load("res://data/resources/area/area_huwahuwa/enemy/boss/003/area_huwahuwa_enemy_boss_003_001.tres") as EnemyInfo
	_expect(info != null, "ふわふわ学校B3 E1を読み込める")
	if info == null:
		quit(_failures)
		return
	var source := _create_enemy(info)
	var active_target := _create_enemy(info)
	var returned_target := _create_enemy(info)
	returned_target.set_Aciding(false)
	var effect := EnemyEffectOnAcidDamageToAdjacent.new()
	effect.bind_source(source)
	var digestion_state := EnemyDigestionState.new()
	var active_hp := active_target.current_hp
	var returned_hp := returned_target.current_hp
	EnemyEffectBattleActions.deal_acid_damage(effect, digestion_state, active_target, 500)
	EnemyEffectBattleActions.deal_acid_damage(effect, digestion_state, returned_target, 500)
	_expect(active_target.current_hp == active_hp - 500, "胃袋内の対象には消化ダメージを与える")
	_expect(returned_target.current_hp == returned_hp, "吐き戻し済みの対象には消化ダメージを与えない")
	source.free()
	active_target.free()
	returned_target.free()
	quit(_failures)


func _create_enemy(info: EnemyInfo) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectAcidTargetStateTest: %s" % message)
