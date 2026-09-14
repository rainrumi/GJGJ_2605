extends SceneTree

const ACID_LINE_CASES: Array[Dictionary] = [
	{
		"path": "res://data/resources/area/area_iriyu/enemy/normal/008/area_iriyu_enemy_normal_008_001.tres",
		"delta": 3000,
	},
	{
		"path": "res://data/resources/area/area_iriyu/enemy/boss/002/area_iriyu_enemy_boss_002_003.tres",
		"delta": 190,
	},
]
const EMPTY_CELL_PATH := "res://data/resources/area/area_lunova/enemy/normal/007/area_lunova_enemy_normal_007_001.tres"

var _failures := 0


func _initialize() -> void:
	for case in ACID_LINE_CASES:
		_test_acid_line_effect(case.path, case.delta)
	_test_empty_cell_effect()
	quit(_failures)


func _test_acid_line_effect(path: String, delta: int) -> void:
	var enemy := _create_enemy(path)
	if enemy == null:
		return
	var board := StomachBoard.new()
	var bottom_extent := 0
	for cell in enemy.get_occupied_cells(Vector2i.ZERO):
		bottom_extent = maxi(bottom_extent, cell.y)
	enemy.set_stomach_cell(Vector2i(0, board.rows - 1 - bottom_extent))
	var max_hp_effect: EnemyEffectOnTouchAcidLineChangeMaxHp
	var hp_effect: EnemyEffectOnTouchAcidLineChangeHp
	for effect in enemy.get_enemy_effects():
		if effect is EnemyEffectOnTouchAcidLineChangeMaxHp:
			max_hp_effect = effect
		elif effect is EnemyEffectOnTouchAcidLineChangeHp:
			hp_effect = effect
	_expect(max_hp_effect != null and hp_effect != null, "%s: 最大HPとHPの両効果がある" % path)
	if max_hp_effect != null and hp_effect != null:
		_expect(max_hp_effect.max_hp_delta == delta, "%s: 最大HP増加量" % path)
		_expect(hp_effect.hp_delta == delta and hp_effect.heal_over_maximum, "%s: HP増加量と上限外回復" % path)
		max_hp_effect.bind_source(enemy)
		max_hp_effect.setup_stomach(board)
		hp_effect.bind_source(enemy)
		hp_effect.setup_stomach(board)
		var original_max := enemy.max_hp
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + delta, "%s: 接触時の最大HP" % path)
		_expect(enemy.current_hp == original_max + delta, "%s: 接触時の現在HP" % path)
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + delta, "%s: 再評価時の最大HP" % path)
		_expect(enemy.current_hp == original_max + delta, "%s: 再評価でHPを重複加算しない" % path)
		enemy.set_stomach_cell(Vector2i.ZERO)
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max, "%s: 非接触時に最大HP補正が外れる" % path)
		max_hp_effect.unbind()
		hp_effect.unbind()
	enemy.free()
	board.free()


func _test_empty_cell_effect() -> void:
	var enemy := _create_enemy(EMPTY_CELL_PATH)
	if enemy == null:
		return
	var board := StomachBoard.new()
	board.columns = 2
	board.rows = 2
	var max_hp_effect: EnemyEffectOnBattleChangeMaxHpByEmptyCell
	var hp_effect: EnemyEffectOnBattleChangeHpByEmptyCell
	for effect in enemy.get_enemy_effects():
		if effect is EnemyEffectOnBattleChangeMaxHpByEmptyCell:
			max_hp_effect = effect
		elif effect is EnemyEffectOnBattleChangeHpByEmptyCell:
			hp_effect = effect
	_expect(max_hp_effect != null and hp_effect != null, "空きマス数に応じた最大HPとHPの両効果がある")
	if max_hp_effect != null and hp_effect != null:
		_expect(max_hp_effect.max_hp_delta_per_cell == 500, "空きマスごとの最大HP増加量")
		_expect(hp_effect.hp_delta_per_cell == 500 and hp_effect.heal_over_maximum, "空きマスごとのHP増加量と上限外回復")
		_expect(hp_effect.activates_outside_stomach, "胃袋外で回復差分の記録をリセットできる")
		var enemies: Array[Enemy] = [enemy]
		max_hp_effect.bind_source(enemy)
		max_hp_effect.setup_enemies(enemies)
		max_hp_effect.setup_stomach(board)
		hp_effect.bind_source(enemy)
		hp_effect.setup_enemies(enemies)
		hp_effect.setup_stomach(board)
		var original_max := enemy.max_hp
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + 1500, "空き3マスで最大HPが1500増える")
		_expect(enemy.current_hp == original_max + 1500, "空き3マスで現在HPが1500増える")
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + 1500, "再評価時の最大HP")
		_expect(enemy.current_hp == original_max + 1500, "再評価でHPを重複加算しない")
		board.rows = 3
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + 2500, "空き5マスに増えると最大HPも2500増える")
		_expect(enemy.current_hp == original_max + 2500, "空き5マスに増えると現在HPも2500増える")
		board.rows = 2
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + 1500, "空き3マスに戻ると最大HP補正も戻る")
		enemy.set_Aciding(false)
		enemy.data.hp.reset_modifiers()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max and enemy.current_hp == original_max, "吐き出し時は最大HPと現在HPが元に戻る")
		enemy.data.hp.set_current(original_max - 200)
		enemy.set_Aciding(true)
		enemy.data.hp.reset_modifiers()
		max_hp_effect.apply()
		hp_effect.apply()
		enemy.data.hp.apply_modifiers()
		_expect(enemy.max_hp == original_max + 1500, "再投入時に最大HP補正を再適用する")
		_expect(enemy.current_hp == original_max - 200 + 1500, "再投入時に増えた最大HPと同じ量を回復する")
		max_hp_effect.unbind()
		hp_effect.unbind()
	enemy.free()
	board.free()


func _create_enemy(path: String) -> Enemy:
	var info := load(path) as EnemyInfo
	_expect(info != null, "%sを読み込める" % path)
	if info == null:
		return null
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_stomach_cell(Vector2i.ZERO)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyHpLimitIncreaseEffectTest: %s" % message)
