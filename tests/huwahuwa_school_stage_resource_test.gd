extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_enemy := load("res://data/resources/area/area_huwahuwa/area_huwahuwa_enemy.tres") as StageEnemyInfo
	_expect(stage_enemy != null, "ふわふわ学校の敵定義を読み込める")
	if stage_enemy != null:
		_expect(stage_enemy.strengthened_enemy_presets.size() == 5, "5つのボスプリセットが登録されている")
		for index in range(mini(5, stage_enemy.strengthened_enemy_presets.size())):
			var preset := stage_enemy.strengthened_enemy_presets[index] as EnemyPresetInfo
			_expect(preset != null, "ボスプリセットを読み込める: %d" % (index + 1))
			if preset == null:
				continue
			var expected_count := 1 if index == 4 else 3
			_expect(preset.enemies.size() == expected_count, "ステージ%dの敵数" % [index + 1])
			for enemy in preset.enemies:
				_expect(enemy != null and enemy.acid_block != null, "ステージ%dのEnemyInfoを読み込める" % [index + 1])
			if index == 0:
				_validate_stage_4(preset)
			elif index == 1:
				_validate_stage_8(preset)
			elif index == 2:
				_validate_stage_12(preset)
			elif index == 3:
				_validate_stage_16(preset)
			elif index == 4:
				_validate_stage_20(preset)
	quit(_failures)


func _validate_stage_4(preset: EnemyPresetInfo) -> void:
	_expect(preset.enemies[0].main_skill == null, "ST4 E1は説明文だけのスキル")
	_expect(preset.enemies[1].main_skill == null, "ST4 E2は説明文だけのスキル")
	_expect(preset.enemies[2].main_skill == null, "ST4 E3は説明文だけのスキル")


func _validate_stage_8(preset: EnemyPresetInfo) -> void:
	_expect(preset.enemies[0].main_skill != null, "ST8 E1の半減効果")
	_expect(preset.enemies[1].main_skill != null, "ST8 E2の隣接伝播効果")
	_expect(preset.enemies[2].main_skill == null, "ST8 E3は説明文だけのスキル")


func _validate_stage_12(preset: EnemyPresetInfo) -> void:
	_expect(preset.enemies[0].main_skill != null and preset.enemies[0].main_skill.effects.size() == 2, "ST12 E1の時間効果")
	_expect(preset.enemies[1].main_skill != null, "ST12 E2の隣接伝播効果")
	_expect(preset.enemies[2].main_skill != null, "ST12 E3の隣接伝播効果")


func _validate_stage_16(preset: EnemyPresetInfo) -> void:
	_validate_stage_16_fixed_tooltip(preset.enemies[1])
	_expect(preset.enemies[0].main_skill != null and preset.enemies[0].main_skill.effects.size() == 2, "ST16 E1の生成・自己弱体化効果")
	_expect(preset.enemies[1].main_skill != null, "ST16 E2の2倍効果")
	_expect(preset.enemies[2].main_skill != null, "ST16 E3の2倍効果")
	_expect(preset.enemies[1].description == "胃袋内の他のモノの効果を2倍する。", "ST16 E2の説明文")
	_expect(preset.enemies[2].description == "胃袋内の他のモノの効果を2倍する。", "ST16 E3の説明文")


func _validate_stage_16_fixed_tooltip(skill_definition: EnemyInfo) -> void:
	var source := _create_active_enemy(skill_definition, true)
	var other_1 := _create_active_enemy(skill_definition, false)
	var other_2 := _create_active_enemy(skill_definition, false)
	var objects: Array[Enemy] = [source, other_1, other_2]
	var effects := source.get_enemy_effects()
	_expect(effects.size() == 1, "ST16 E2の倍率効果数を確認する")
	if effects.is_empty():
		for enemy in objects:
			enemy.free()
		return
	var effect := effects[0] as EnemyEffectOnOtherObjectScaleEffectByObjectCount
	_expect(effect != null, "ST16 E2の2倍効果を取得する")
	if effect != null:
		effect.setup_enemies(objects)
		_expect(source.get_main_effect_text() == skill_definition.description, "ST16 E2のツールチップに倍率表示を付けない")
	for enemy in objects:
		enemy.free()


func _create_active_enemy(info: EnemyInfo, use_skill: bool) -> Enemy:
	var enemy := Enemy.new()
	enemy.data.setup(info, 100, 10, use_skill, use_skill)
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_Aciding(true)
	return enemy


func _validate_stage_20(preset: EnemyPresetInfo) -> void:
	_expect(preset.enemies[0].main_skill != null, "ST20 E1の指数ダメージ効果")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HuwahuwaSchoolStageResourceTest: %s" % message)
