extends SceneTree

const ENEMY_PATH := "res://data/resources/area/area_lunova/enemy/normal/007/area_lunova_enemy_normal_007_002.tres"

var _failures := 0


func _initialize() -> void:
	var info := load(ENEMY_PATH) as EnemyInfo
	_expect(info != null, "17010007002を読み込める")
	if info == null:
		quit(_failures)
		return
	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_Aciding(true)
	var board := StomachBoard.new()
	var effect := enemy.get_enemy_effects()[0] as EnemyEffectOnNotAdjacentAcidLineChangeHp
	_expect(effect != null, "消化ライン非接触時のHP倍率効果を持つ")
	if effect != null:
		_expect(effect.hp_multiplier == 5.0 and effect.activates_outside_stomach, "5倍効果と胃袋外での状態リセットを設定する")
		effect.bind_source(enemy)
		effect.setup_stomach(board)
		var base_maximum := enemy.max_hp
		var bonus := base_maximum * 4
		enemy.current_hp = base_maximum - 500
		enemy.set_stomach_cell(Vector2i.ZERO)
		_refresh(enemy, effect)
		_expect(enemy.max_hp == base_maximum * 5, "消化ライン非接触で最大HPが5倍になる")
		_expect(enemy.current_hp == base_maximum - 500 + bonus, "増加した最大HPと同じ量を回復する")
		_refresh(enemy, effect)
		_expect(enemy.current_hp == base_maximum - 500 + bonus, "再評価で重複回復しない")
		enemy.set_stomach_cell(Vector2i(0, board.rows - 1))
		_refresh(enemy, effect)
		_expect(enemy.max_hp == base_maximum, "消化ライン接触でHP上限補正が外れる")
		enemy.current_hp = base_maximum - 500
		enemy.set_stomach_cell(Vector2i.ZERO)
		_refresh(enemy, effect)
		_expect(enemy.current_hp == base_maximum - 500 + bonus, "ラインから離れた時に再び回復する")
		enemy.set_Aciding(false)
		_refresh(enemy, effect)
		enemy.current_hp = base_maximum - 500
		enemy.set_Aciding(true)
		_refresh(enemy, effect)
		_expect(enemy.max_hp == base_maximum * 5, "再投入でHP上限が5倍になる")
		_expect(enemy.current_hp == base_maximum - 500 + bonus, "再投入でも上限増加分を回復する")
		effect.unbind()
	enemy.free()
	board.free()
	quit(_failures)


func _refresh(enemy: Enemy, effect: EnemyEffectOnNotAdjacentAcidLineChangeHp) -> void:
	enemy.data.hp.reset_modifiers()
	effect.apply()
	enemy.data.hp.apply_modifiers()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy17010007002HpRecoveryTest: %s" % message)
