extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var e2_info := load("res://data/resources/area/area_huwahuwa/enemy/boss/004/area_huwahuwa_enemy_boss_004_002.tres") as EnemyInfo
	var e3_info := load("res://data/resources/area/area_huwahuwa/enemy/boss/004/area_huwahuwa_enemy_boss_004_003.tres") as EnemyInfo
	var lotus := load("res://data/resources/seeds/skills/seed_100_112.tres").duplicate(true) as SeedInfo
	_expect(e2_info != null and e3_info != null and lotus != null, "B4効果とハスを読み込む")
	if e2_info == null or e3_info == null or lotus == null:
		quit(_failures)
		return

	var e2 := _create_enemy(e2_info, null, true)
	var e3 := _create_enemy(e3_info, null, true)
	var lotus_block := _create_enemy(null, lotus, false)
	var enemies: Array[Enemy] = [e2, e3, lotus_block]
	var effect := lotus.sub_skill.effects[0] as SeedEffectOnFinishAcidSeedChangeLine
	effect.effect_amount_configured = true
	effect.effect_amount_fields = PackedStringArray(["line_delta"])
	var stomach := StomachBoard.new()
	stomach.set_acid_line_rows(1)

	var enemy_effects := EnemyEffectSystem.new()
	enemy_effects.setup(
		PlayerHealth.new(),
		EnemySpawnQueue.new(),
		BattleClock.new(),
		DigestionInterval.new(),
		EnemyAcidDamageModifiers.new(),
		EnemyDigestionState.new(),
		EnemyEffectInheritance.new(),
		EnemyEffectStack.new(),
		EnemyEffectInstaller.new()
	)
	enemy_effects.refresh(enemies, stomach)
	_expect(lotus_block.data.defense_status.effect_multiplier == 4.0, "E2/E3の2倍効果をハスへ累積する")
	lotus_block.set_Acided(true)
	enemy_effects.refresh(enemies, stomach)
	_expect(lotus_block.data.defense_status.effect_multiplier == 1.0, "消化済みハスの一時倍率は再評価で解除される")

	var resolver := SeedEffectResolver.new()
	resolver.add_Acided_seed_effect(lotus, 0, stomach, lotus_block)
	_expect(stomach.get_acid_line_rows() == 9, "E2/E3の4倍をハスのline_deltaへ適用する")

	for enemy in enemies:
		enemy.free()
	stomach.free()
	quit(_failures)


func _create_enemy(info: EnemyInfo, seed: SeedInfo, use_skill: bool) -> Enemy:
	var enemy := Enemy.new()
	if info != null:
		enemy.data.setup(info, info.acid_block.max_hp, info.acid_block.damage, use_skill, use_skill)
	else:
		var dummy_info := EnemyInfo.new()
		dummy_info.acid_block = AcidBlockInfo.new()
		dummy_info.acid_block.max_hp = 10000
		dummy_info.acid_block.damage = 1
		enemy.data.setup(dummy_info, 10000, 1, false, false)
	enemy.seed_info = seed
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_Aciding(true)
	return enemy


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HuwahuwaLotusEffectChainTest: %s" % message)
