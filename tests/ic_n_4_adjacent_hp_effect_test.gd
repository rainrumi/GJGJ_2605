extends SceneTree

const TARGET_RESOURCE_PATHS: Array[String] = [
	"res://data/resources/area/area_iriyu/enemy/normal/004/area_iriyu_enemy_normal_004_004.tres",
	"res://data/resources/area/area_iriyu/enemy/normal/004/area_iriyu_enemy_normal_004_005.tres",
	"res://data/resources/area/area_iriyu/enemy/boss/001/area_iriyu_enemy_boss_001_001.tres",
]

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 隣接最大HP・回復効果試験
func _run() -> void:
	for path in TARGET_RESOURCE_PATHS:
		_test_adjacent_hp_effect(path)
	quit(_failures)


# 隣接体力効果試験
func _test_adjacent_hp_effect(path: String) -> void:
	var source_info := load(path) as EnemyInfo # 効果元定義
	_expect(source_info != null, "%sのEnemyInfoを読み込める" % path)
	if source_info == null:
		return
	var source := _create_enemy(source_info, Vector2i.ZERO) # 効果元
	var target := _create_enemy(_create_target_info(), Vector2i.RIGHT) # 隣接対象
	var effects := source.get_enemy_effects() # メイン効果
	_expect(effects.size() == 2, "%dがメイン効果を2つ持つ" % source_info.skill_id)
	var max_hp_effect: EnemyEffectOnAdjacentObjectChangeTargetMaxHp
	var recovery_effect: EnemyEffectOnAdjacentObjectChangeTargetHp
	for effect in effects:
		if effect is EnemyEffectOnAdjacentObjectChangeTargetMaxHp:
			max_hp_effect = effect
		elif effect is EnemyEffectOnAdjacentObjectChangeTargetHp:
			recovery_effect = effect
	_expect(max_hp_effect != null, "%dが隣接対象の最大HP変更効果を持つ" % source_info.skill_id)
	_expect(recovery_effect != null, "%dが隣接対象のHP回復効果を持つ" % source_info.skill_id)
	if max_hp_effect != null and recovery_effect != null:
		_expect(max_hp_effect.max_hp_delta == 100, "%dの最大HP増加量が100" % source_info.skill_id)
		_expect(recovery_effect.hp_delta == 100, "%dのHP回復量が100" % source_info.skill_id)
		_expect(recovery_effect.heal_over_maximum, "%dが最大HP補正確定前に回復できる" % source_info.skill_id)
		var enemies: Array[Enemy] = [source, target] # 配置対象一覧
		max_hp_effect.bind_source(source)
		max_hp_effect.setup_enemies(enemies)
		recovery_effect.bind_source(source)
		recovery_effect.setup_enemies(enemies)
		max_hp_effect.apply()
		recovery_effect.apply()
		target.data.hp.apply_modifiers()
		_expect(target.max_hp == 200, "%dが隣接対象の最大HPを100増やす" % source_info.skill_id)
		_expect(target.current_hp == 200, "%dが満タンの隣接対象を追加で100回復する" % source_info.skill_id)
		max_hp_effect.unbind()
		recovery_effect.unbind()
	source.free()
	target.free()


# 試験Enemy作成
func _create_enemy(info: EnemyInfo, cell: Vector2i) -> Enemy:
	var enemy := Enemy.new() # 試験対象
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(cell)
	enemy.set_Aciding(true)
	return enemy


# 隣接対象定義作成
func _create_target_info() -> EnemyInfo:
	var block := AcidBlockInfo.new() # 対象ブロック
	block.max_hp = 100
	block.stomach_shape = [PackedInt32Array([1])]
	var info := EnemyInfo.new() # 対象定義
	info.acid_block = block
	info.main_skill = EnemySkill.new()
	return info


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("IcN4AdjacentHpEffectTest: %s" % message)
