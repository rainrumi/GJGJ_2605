extends SceneTree

var _failures := 0


func _initialize() -> void:
	var definition := load(
		"res://data/resources/area/area_iriyu/enemy/normal/003/area_iriyu_enemy_normal_003_002.tres"
	) as EnemyInfo
	var definition_003 := load(
		"res://data/resources/area/area_iriyu/enemy/normal/003/area_iriyu_enemy_normal_003_003.tres"
	) as EnemyInfo
	_expect(definition != null, "悪夢16010003002を読み込める")
	_expect(definition_003 != null, "悪夢16010003003を読み込める")
	if definition_003 != null:
		var effect_003 := (
			definition_003.get_main_skill_definition().get_effects()[0]
			as EnemyEffectOnDigestionNotTouchAcidLineTakeAcidDamage
		)
		_expect(
			effect_003 != null,
			"悪夢16010003003も消化進行時の直接ダメージ効果を使用する"
		)
		if effect_003 != null:
			_expect(effect_003.damage == 30, "悪夢16010003003の直接消化ダメージは30")
	if definition == null:
		quit(_failures)
		return

	var enemy := Enemy.new()
	enemy.data.definition = definition
	enemy.data.setup(definition, 120, 10, true, true)
	enemy.set_Aciding(true)
	enemy.stomach_cell = Vector2i(0, 0)
	var stomach := StomachBoard.new()
	stomach.columns = 4
	stomach.rows = 5

	var digestion_state := EnemyDigestionState.new()
	var stack := EnemyEffectStack.new()
	var installer := EnemyEffectInstaller.new()
	installer.setup(
		PlayerHealth.new(),
		EnemySpawnQueue.new(),
		BattleClock.new(),
		DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(),
		digestion_state,
		EnemyEffectInheritance.new(),
		stack,
		EnemyEffectRefreshProcessor.new()
	)
	var enemies: Array[Enemy] = [enemy]
	installer.sync(enemies, stomach)

	digestion_state.start_acid_line_damage()
	stack.execute()
	_expect(enemy.get_current_hp() == 90, "ライン内のモノが消化ダメージを受ける時に30ダメージを受ける")
	digestion_state.complete_batch(60, 60, [])
	stack.execute()
	_expect(enemy.get_current_hp() == 90, "時間進行側の消化完了通知では再発動しない")

	enemy.stomach_cell = Vector2i(0, 4)
	digestion_state.start_acid_line_damage()
	stack.execute()
	_expect(enemy.get_current_hp() == 90, "ライン接触時は追加の30ダメージを受けない")

	enemy.set_Aciding(false)
	enemy.stomach_cell = Vector2i(0, 0)
	digestion_state.start_acid_line_damage()
	stack.execute()
	_expect(enemy.get_current_hp() == 90, "胃袋の外ではライン非接触でもダメージを受けない")

	installer.reset()
	enemy.free()
	stomach.free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy16010003002EffectTest: %s" % message)
