extends SceneTree

var _failures := 0 # 失敗数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 敵データ試験
func _run() -> void:
	var template_effect := EnemyEffect.new() # 原本効果
	var main_skill := EnemySkill.new() # 主スキル原本
	main_skill.effects = [template_effect]
	var definition := EnemyInfo.new() # 敵定義
	definition.main_skill = main_skill
	var first := EnemyData.new() # 一体目データ
	var second := EnemyData.new() # 二体目データ
	first.setup(definition, 20, 5, true, true)
	second.setup(definition, 20, 5, true, true)
	_expect(first.definition == definition, "EnemyInfoを保持する")
	_expect(first.hp.maximum == 20 and first.attack.value == 5, "初期値を反映する")
	_expect(first.hp != second.hp, "HP状態を共有しない")
	_expect(first.attack != second.attack, "攻撃状態を共有しない")
	_expect(first.defense_status != second.defense_status, "防御状態を共有しない")
	_expect(first.digestion_state != second.digestion_state, "消化状態を共有しない")
	_expect(first.main_skill != second.main_skill, "敵同士でスキルを共有しない")
	_expect(first.main_skill.effects[0] != second.main_skill.effects[0], "敵同士でEffectを共有しない")
	first.main_skill_active = false
	_expect(first.get_active_skill() == null, "メインスキル無効時はスキルを返さない")
	first.main_skill_active = true
	first.hp.take_damage(3)
	first.attack.add_value(2)
	_expect(second.hp.current == 20, "HP変更を他個体へ漏らさない")
	_expect(second.attack.value == 5, "攻撃変更を他個体へ漏らさない")
	var enemy := Enemy.new() # Enemy経由の個体
	enemy.setup(definition, Vector2.ONE, true, Vector2.ZERO, true)
	_expect(enemy.data.definition == definition, "Enemyが敵定義をEnemyDataへ保持する")
	_expect(enemy.data.main_skill_active, "Enemyがメインスキル状態をEnemyDataへ保持する")
	_expect(enemy.data.skills_enabled, "Enemyがスキル有効状態をEnemyDataへ保持する")
	enemy.free()
	first.unbind_skills()
	second.unbind_skills()
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyDataTest: %s" % message)
