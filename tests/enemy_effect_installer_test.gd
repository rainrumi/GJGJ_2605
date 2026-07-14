extends SceneTree

var _failures := 0 # 失敗数


class TestEffect:
	extends EnemyEffect

	var activation_count := 0 # 発動回数


	# 発動種別取得
	func get_activation_mask() -> int:
		return ACTIVATION_PROGRESS_TIME


	# 試験効果適用
	func apply() -> void:
		if is_progress_time_activation():
			activation_count += 1


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 配線試験
func _run() -> void:
	var enemy := Enemy.new() # 効果所有者
	var effect := TestEffect.new() # 試験効果
	var skill := EnemySkill.new() # 試験スキル
	skill.effects = [effect]
	enemy.data.main_skill = skill
	enemy.data.main_skill_active = true
	var enemies: Array[Enemy] = [enemy] # 戦闘参加敵
	var player_health := PlayerHealth.new() # プレイヤーHP
	var spawn_queue := EnemySpawnQueue.new() # 敵生成要求
	var battle_clock := BattleClock.new() # 戦闘時刻
	var digestion_interval := DigestionInterval.new() # 消化間隔
	var acid_modifiers := EnemyAcidDamageModifiers.new() # 消化補正
	var digestion_state := EnemyDigestionState.new() # 消化状態
	var inheritance := EnemyEffectInheritance.new() # 継承効果
	var stack := EnemyEffectStack.new() # 効果スタック
	var installer := EnemyEffectInstaller.new() # 効果配線
	installer.setup(
		player_health,
		spawn_queue,
		battle_clock,
		digestion_interval,
		acid_modifiers,
		digestion_state,
		inheritance,
		stack
	)
	installer.sync(enemies, null)
	battle_clock.request_progress_effect(ProgressTimeActivationData.new(60, 60))
	stack.execute()
	_expect(effect.activation_count == 1, "対象Signalで一度発動する")
	battle_clock.request_turn_effect(TurnStartActivationData.new(60, 60))
	stack.execute()
	_expect(effect.activation_count == 1, "対象外Signalでは発動しない")
	installer.reset()
	battle_clock.request_progress_effect(ProgressTimeActivationData.new(60, 120))
	stack.execute()
	_expect(effect.activation_count == 1, "解除後は発動しない")
	enemy.free()
	quit(_failures)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectInstallerTest: %s" % message)
