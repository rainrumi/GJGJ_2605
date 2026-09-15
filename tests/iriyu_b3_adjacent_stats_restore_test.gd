extends SceneTree

const RESOURCE_PATHS: Array[String] = [
	"res://data/resources/area/area_iriyu/enemy/boss/003/area_iriyu_enemy_boss_003_003.tres",
	"res://data/resources/area/area_iriyu/enemy/boss/003/area_iriyu_enemy_boss_003_004.tres",
]

var _failures := 0


func _initialize() -> void:
	for path in RESOURCE_PATHS:
		_test_adjacent_stats_restore(path)
	quit(_failures)


func _test_adjacent_stats_restore(path: String) -> void:
	var info := load(path) as EnemyInfo
	_expect(info != null, "%sを読み込める" % path)
	if info == null:
		return
	var source := _create_enemy(info, Vector2i.ZERO)
	var target := _create_enemy(_create_target_info(), Vector2i(1, 0))
	var hp_effect: EnemyEffectOnAdjacentObjectChangeTargetMaxHp
	var attack_effect: EnemyEffectOnAdjacentObjectChangeTargetAttackModifier
	for candidate in source.get_enemy_effects():
		if candidate is EnemyEffectOnAdjacentObjectChangeTargetMaxHp:
			hp_effect = candidate
		elif candidate is EnemyEffectOnAdjacentObjectChangeTargetAttackModifier:
			attack_effect = candidate
	_expect(hp_effect != null and hp_effect.max_hp_delta == -100 and hp_effect.follow_current_hp, "%sが隣接中のHPを100減らす" % path)
	_expect(attack_effect != null and attack_effect.attack_delta == 10, "%sが隣接中の攻撃力を10増やす" % path)
	if hp_effect != null and attack_effect != null:
		var enemies: Array[Enemy] = [source, target]
		hp_effect.bind_source(source)
		hp_effect.setup_enemies(enemies)
		attack_effect.bind_source(source)
		attack_effect.setup_enemies(enemies)
		_refresh(target, hp_effect, attack_effect)
		_expect(target.get_max_hp() == 200 and target.get_current_hp() == 200, "%sとの隣接中は対象の最大HPと現在HPが100減る" % path)
		_expect(target.data.attack.get_modified_value(target.get_damage()) == 30, "%sとの隣接中は対象の攻撃力が10増える" % path)
		target.take_acid_damage(40, false)
		target.set_stomach_cell(Vector2i(3, 0))
		_refresh(target, hp_effect, attack_effect)
		_expect(target.get_max_hp() == 300 and target.get_current_hp() == 260, "%sとの隣接解除時はHP補正だけが戻る" % path)
		_expect(target.data.attack.get_modified_value(target.get_damage()) == 20, "%sとの隣接解除時は攻撃力が元に戻る" % path)
		hp_effect.unbind()
		attack_effect.unbind()
	source.free()
	target.free()


func _refresh(
	target: Enemy,
	hp_effect: EnemyEffectOnAdjacentObjectChangeTargetMaxHp,
	attack_effect: EnemyEffectOnAdjacentObjectChangeTargetAttackModifier
) -> void:
	target.data.hp.reset_modifiers()
	target.data.attack.reset_modifiers()
	hp_effect.apply()
	attack_effect.apply()
	target.data.hp.apply_modifiers()


func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


func _create_target_info() -> EnemyInfo:
	var block := AcidBlockInfo.new()
	block.max_hp = 300
	block.damage = 20
	block.stomach_shape = [PackedInt32Array([1])]
	var info := EnemyInfo.new()
	info.acid_block = block
	info.main_skill = EnemySkill.new()
	return info


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("IriyuB3AdjacentStatsRestoreTest: %s" % message)
