extends SceneTree

var _failures := 0


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# HP枯渇処理試験
func _run() -> void:
	var digestion_state := EnemyDigestionState.new()
	var system := _create_system(digestion_state)
	var depleted_enemy := Enemy.new()
	var surviving_enemy := Enemy.new()
	var seed_block := Enemy.new()
	depleted_enemy.data.hp.setup(10, 0)
	depleted_enemy.set_Aciding(false)
	surviving_enemy.data.hp.setup(10, 1)
	seed_block.data.hp.setup(10, 0)
	seed_block.seed_info = SeedInfo.new()
	var enemies: Array[Enemy] = [depleted_enemy, surviving_enemy, seed_block]

	system.refresh(enemies, null)
	var digested := digestion_state.consume()
	_expect(depleted_enemy.is_Acided(), "消化ライン外でもHP 0の悪夢を消化済みにする")
	_expect(digested == [depleted_enemy], "HP 0の悪夢だけを消化処理へ登録する")
	_expect(not surviving_enemy.is_Acided(), "HPが残る悪夢を消化済みにしない")
	_expect(not seed_block.is_Acided(), "夢種ブロックを悪夢のHP枯渇判定へ含めない")

	system.refresh(enemies, null)
	_expect(digestion_state.consume().is_empty(), "消化済み悪夢を重複登録しない")
	system.reset()
	depleted_enemy.free()
	surviving_enemy.free()
	seed_block.free()
	quit(_failures)


# 効果システム生成
func _create_system(digestion_state: EnemyDigestionState) -> EnemyEffectSystem:
	var system := EnemyEffectSystem.new()
	system.setup(
		PlayerHealth.new(),
		EnemySpawnQueue.new(),
		BattleClock.new(),
		DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(),
		digestion_state,
		EnemyEffectInheritance.new(),
		EnemyEffectStack.new(),
		EnemyEffectInstaller.new()
	)
	return system


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectSystemDepletionTest: %s" % message)
