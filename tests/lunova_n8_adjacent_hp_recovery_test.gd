extends SceneTree

const RESOURCE_PATHS: Array[String] = [
	"res://data/resources/area/area_lunova/enemy/normal/008/area_lunova_enemy_normal_008_002.tres",
	"res://data/resources/area/area_lunova/enemy/normal/008/area_lunova_enemy_normal_008_003.tres",
]

var _failures := 0


func _initialize() -> void:
	for path in RESOURCE_PATHS:
		_test_recovery(path)
	_test_stacked_recovery()
	quit(_failures)


func _test_recovery(path: String) -> void:
	var info := load(path) as EnemyInfo
	_expect(info != null, "%sを読み込める" % path)
	if info == null:
		return
	var source := _create_enemy(info, Vector2i.ZERO)
	var target := _create_enemy(_create_target_info(), Vector2i(2, 0))
	var distant := _create_enemy(_create_target_info(), Vector2i(5, 0))
	var effect: EnemyEffectOnAdjacentObjectScaleTargetHp
	for candidate in source.get_enemy_effects():
		if candidate is EnemyEffectOnAdjacentObjectScaleTargetHp:
			effect = candidate
	_expect(effect != null and effect.hp_multiplier == 2.0, "%sが最大HP2倍効果を持つ" % path)
	if effect != null:
		var enemies: Array[Enemy] = [source, target, distant]
		var stack := EnemyEffectStack.new()
		effect.bind_source(source)
		effect.bind_owner(source.data, stack)
		effect.setup_enemies(enemies)
		_expect(effect.activates_outside_stomach, "%sは胃袋外で隣接履歴をリセットできる" % path)
		target.current_hp = 40
		_refresh(target, effect, stack)
		_expect(target.max_hp == 200 and target.current_hp == 140, "%sが増加した最大HP100と同量を回復する" % path)
		_expect(distant.max_hp == 100 and distant.current_hp == 100, "%sは非隣接対象を変えない" % path)
		_refresh(target, effect, stack)
		_expect(target.max_hp == 200 and target.current_hp == 140, "%sは再評価で重複回復しない" % path)
		target.set_stomach_cell(Vector2i(5, 0))
		_refresh(target, effect, stack)
		_expect(target.max_hp == 100, "%sは非隣接時に最大HP補正を外す" % path)
		target.current_hp = 40
		target.set_stomach_cell(Vector2i(2, 0))
		_refresh(target, effect, stack)
		_expect(target.max_hp == 200 and target.current_hp == 140, "%sは再隣接時に増加分を回復する" % path)
		source.set_Aciding(false)
		_refresh(target, effect, stack)
		_expect(target.max_hp == 100, "%sは効果元が胃袋外に出ると最大HP補正を外す" % path)
		target.current_hp = 40
		source.set_Aciding(true)
		_refresh(target, effect, stack)
		_expect(target.max_hp == 200 and target.current_hp == 140, "%sは効果元の再投入後にも増加分を回復する" % path)
		target.set_Aciding(false)
		_refresh(target, effect, stack)
		_expect(target.max_hp == 100, "%sは回復対象が胃袋外に出ると最大HP補正を外す" % path)
		target.current_hp = 40
		target.set_Aciding(true)
		_refresh(target, effect, stack)
		_expect(target.max_hp == 200 and target.current_hp == 140, "%sは回復対象の再投入後にも増加分を回復する" % path)
		effect.unbind()
	source.free()
	target.free()
	distant.free()


func _test_stacked_recovery() -> void:
	var first_source := _create_enemy(load(RESOURCE_PATHS[0]) as EnemyInfo, Vector2i.ZERO)
	var second_source := _create_enemy(load(RESOURCE_PATHS[1]) as EnemyInfo, Vector2i.ZERO)
	var target := _create_enemy(_create_target_info(), Vector2i(2, 0))
	var effects: Array[EnemyEffectOnAdjacentObjectScaleTargetHp] = []
	for source in [first_source, second_source]:
		for candidate in source.get_enemy_effects():
			if candidate is EnemyEffectOnAdjacentObjectScaleTargetHp:
				effects.append(candidate)
				candidate.bind_source(source)
				candidate.setup_enemies([source, target])
	_expect(effects.size() == 2, "2つの最大HP倍率効果を読み込める")
	if effects.size() == 2:
		target.current_hp = 40
		target.data.hp.reset_modifiers()
		for effect in effects:
			effect.apply()
		target.data.hp.apply_modifiers()
		_expect(target.max_hp == 400 and target.current_hp == 340, "倍率効果が重なるときも最大HP増加量300を回復する")
	for effect in effects:
		effect.unbind()
	first_source.free()
	second_source.free()
	target.free()


func _refresh(target: Enemy, effect: EnemyEffectOnAdjacentObjectScaleTargetHp, stack: EnemyEffectStack) -> void:
	target.data.hp.reset_modifiers()
	stack.request(effect, RefreshActivationData.new())
	stack.execute()
	target.data.hp.apply_modifiers()


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _create_target_info() -> EnemyInfo:
	var block := AcidBlockInfo.new()
	block.max_hp = 100
	block.stomach_shape = [PackedInt32Array([1])]
	var info := EnemyInfo.new()
	info.acid_block = block
	info.main_skill = EnemySkill.new()
	return info


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("LunovaN8AdjacentHpRecoveryTest: %s" % message)
