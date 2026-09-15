extends SceneTree

const E3_PATH := "res://data/resources/area/area_lunova/enemy/boss/003/area_lunova_enemy_boss_003_003.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var e3_info := load(E3_PATH) as EnemyInfo
	_expect(e3_info != null, "ルノヴァB-3 E3の定義を読み込む")
	if e3_info == null:
		quit(_failures)
		return

	var source_info := EnemyInfo.new()
	source_info.description = "吸収元のスキル説明"
	source_info.main_skill = EnemySkill.new()
	source_info.main_skill.effects = [EnemyEffect.new()]

	var e3 := Enemy.new()
	e3.data.setup(e3_info, 12500, 20, true, true)
	var source := Enemy.new()
	source.data.setup(source_info, 10, 1, true, true)
	var inheritance := EnemyEffectInheritance.new()
	var tooltip_scene := load("res://scene/object/enemy/tooltip/enemy_tooltip.tscn") as PackedScene
	_expect(tooltip_scene != null, "敵ツールチップSceneを読み込む")
	if tooltip_scene == null:
		_invalidate_enemies(e3, source)
		quit(_failures)
		return
	var tooltip := tooltip_scene.instantiate() as EnemyTooltip
	root.add_child(tooltip)
	await process_frame
	tooltip.show_enemy(e3, "", false)
	_expect(
		not (tooltip.call("_get_tooltip_text") as String).contains("吸収元のスキル説明"),
		"継承前のツールチップに追加スキルを表示しない"
	)

	inheritance.inherit(e3, source)
	var tooltip_text := e3.get_main_effect_text()
	_expect(tooltip_text.ends_with("追加スキル: 吸収元のスキル説明"), "継承スキルを効果文末尾へ表示する")
	_expect(
		(tooltip.call("_get_tooltip_text") as String).contains("追加スキル: 吸収元のスキル説明"),
		"表示中のツールチップを継承直後に更新する"
	)
	_expect(
		e3.get_main_effect_text(false) == e3_info.description,
		"継承スキルを除いた元の効果文を取得できる"
	)

	inheritance.reset()
	_expect(not e3.get_main_effect_text().contains("吸収元のスキル説明"), "継承状態のリセットで表示を解除する")
	_expect(
		not (tooltip.call("_get_tooltip_text") as String).contains("吸収元のスキル説明"),
		"表示中のツールチップをリセット直後に更新する"
	)

	tooltip.hide_tooltip()
	root.remove_child(tooltip)
	tooltip.free()
	_invalidate_enemies(e3, source)
	quit(_failures)


func _invalidate_enemies(e3: Enemy, source: Enemy) -> void:
	e3.free()
	source.free()


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyInheritedSkillTooltipTest: %s" % message)
