extends SceneTree

var _failures := 0 # 失敗数


class TestEffect:
	extends EnemyEffect

	var activation_count := 0 # 発動回数
	var maximum_current_seconds := 86400 # 発動上限時刻
	var battle_clock: BattleClock # 時刻依存


	# 発動Signal接続
	func bind_triggers(installer: EnemyEffectInstaller) -> void:
		installer.connect_progress_time(self)


	# 依存関係設定
	func bind_dependencies(installer: EnemyEffectInstaller) -> void:
		battle_clock = installer.get_battle_clock()


	# 依存関係解除
	func clear_dependencies() -> void:
		battle_clock = null


	# 発動条件判定
	func accepts_activation(data: EnemyEffectActivationData) -> bool:
		var time_data := data as TimeActivationData # 時刻発動値
		return time_data != null and time_data.current_seconds <= maximum_current_seconds


	# 試験効果適用
	func apply() -> void:
		activation_count += 1


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 配線試験
func _run() -> void:
	var enemy := Enemy.new() # 効果所有者
	var effect := TestEffect.new() # 試験効果
	effect.maximum_current_seconds = 90
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
	_expect(effect.battle_clock == battle_clock, "必要な時刻参照だけを保持する")
	var property_names := effect.get_property_list().map(func(property: Dictionary) -> StringName: return property.name) # 保持項目
	_expect(not property_names.has(&"player_health") and not property_names.has(&"stomach"), "未使用参照を保持しない")
	battle_clock.notify_progress_resolved(ProgressTimeActivationData.new(60, 60))
	stack.execute()
	_expect(effect.activation_count == 1, "対象Signalで一度発動する")
	effect.set_state("counter", 7)
	var extra_enemy := Enemy.new() # 追加敵
	enemies.append(extra_enemy)
	installer.sync(enemies, null)
	_expect(effect.get_state_int("counter") == 7, "敵一覧変更で効果状態を維持する")
	battle_clock.notify_turn_started(TurnStartActivationData.new(60, 60))
	stack.execute()
	_expect(effect.activation_count == 1, "対象外Signalでは発動しない")
	battle_clock.notify_progress_resolved(ProgressTimeActivationData.new(60, 120))
	stack.execute()
	_expect(effect.activation_count == 1, "条件外Requestを追加しない")
	var next_effect := TestEffect.new() # 切替後効果
	var next_skill := EnemySkill.new() # 切替後スキル
	next_skill.effects = [next_effect]
	enemy.data.unbind_skills()
	enemy.data.main_skill = next_skill
	installer.sync(enemies, null)
	battle_clock.notify_progress_resolved(ProgressTimeActivationData.new(60, 120))
	stack.execute()
	_expect(effect.activation_count == 1, "切替前効果を再発動しない")
	_expect(next_effect.activation_count == 1, "切替後効果を接続する")
	installer.reset()
	battle_clock.notify_progress_resolved(ProgressTimeActivationData.new(60, 180))
	stack.execute()
	_expect(next_effect.activation_count == 1, "解除後は発動しない")
	_test_effect_duplication()
	extra_enemy.free()
	enemy.free()
	quit(_failures)


# 効果複製試験
func _test_effect_duplication() -> void:
	var template_effect := TestEffect.new() # 原本効果
	var template_skill := EnemySkill.new() # 原本スキル
	template_skill.effects = [template_effect]
	var definition := EnemyInfo.new() # 敵定義
	definition.main_skill = template_skill
	var first_data := EnemyData.new() # 1体目データ
	var second_data := EnemyData.new() # 2体目データ
	first_data.setup(definition, 10, 1, true, true)
	second_data.setup(definition, 10, 1, true, true)
	var first_effect := first_data.get_effects()[0] # 1体目効果
	var second_effect := second_data.get_effects()[0] # 2体目効果
	_expect(first_effect != template_effect, "原本Effectを直接使用しない")
	_expect(first_effect != second_effect, "敵同士でEffectを共有しない")
	first_effect.set_state("count", 1)
	_expect(second_effect.get_state_int("count") == 0, "敵ごとの状態を分離する")
	first_data.unbind_skills()
	second_data.unbind_skills()


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyEffectInstallerTest: %s" % message)
