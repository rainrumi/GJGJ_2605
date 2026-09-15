extends SceneTree

const E2_PATH := "res://data/resources/area/area_lunova/enemy/boss/001/area_lunova_enemy_boss_001_002.tres"
const E2_EFFECT_SCRIPT := preload("res://scene/main/game/enemy/skill/time/enemy_effect_on_digestion_chance_scale_attack.gd")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var info := load(E2_PATH) as EnemyInfo
	_expect(info != null, "ルノヴァB-1 E2を読み込める")
	if info == null:
		quit(_failures)
		return

	var enemy := Enemy.new()
	enemy.data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	enemy.set_Aciding(true)
	var effect := enemy.get_enemy_effects()[0] as EnemyEffect
	_expect(effect != null and effect.get_script() == E2_EFFECT_SCRIPT, "E2が消化進行ごとの確率攻撃効果を持つ")
	if effect == null:
		quit(_failures)
		return

	var digestion_state := EnemyDigestionState.new()
	var system := _create_system(digestion_state)
	var enemies: Array[Enemy] = [enemy]
	system.refresh(enemies, null)

	# 1回目を必ず失敗させ、次の消化進行で必ず成功させる。
	effect.chance = 0.0
	effect.invert_chance = false
	digestion_state.complete_batch(1800, 1800, [])
	system.execute()
	_expect(enemy.data.attack.modifier_multiplier == 1.0, "1回目の消化進行で失敗時は攻撃倍率を適用しない")

	effect.chance = 1.0
	digestion_state.complete_batch(1800, 3600, [])
	system.execute()
	_expect(enemy.data.attack.modifier_multiplier == 777.0, "2回目の消化進行で再抽選し成功時は777倍を適用する")

	system.reset()
	enemy.free()
	quit(_failures)


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


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("LunovaB1E2DigestionChanceTest: %s" % message)
