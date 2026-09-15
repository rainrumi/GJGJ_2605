extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/object/enemy/tooltip/enemy_tooltip.tscn") as PackedScene
	_expect(packed != null, "モノのツールチップを読み込める")
	if packed == null:
		quit(_failures)
		return
	var tooltip := packed.instantiate() as EnemyTooltip
	root.add_child(tooltip)
	await process_frame
	var enemy := Enemy.new()
	var other := Enemy.new()
	var seed_block := Enemy.new()
	seed_block.seed_info = SeedInfo.new()
	enemy.set_Aciding(true)
	other.set_Aciding(true)
	seed_block.set_Aciding(true)
	tooltip.show_enemy(enemy, "", false)
	_expect(not _tooltip_text(tooltip).contains("特殊効果:"), "未付与なら特殊効果欄を表示しない")

	var definition := load("res://data/resources/area/area_lunova/enemy/normal/004/area_lunova_enemy_normal_004_001.tres") as EnemyInfo
	_expect(definition != null and definition.skill_id == 17010004001, "災禍を付与する悪夢定義を読み込める")
	if definition == null or definition.main_skill == null or definition.main_skill.effects.is_empty():
		tooltip.hide_tooltip()
		enemy.free()
		other.free()
		seed_block.free()
		root.remove_child(tooltip)
		tooltip.free()
		quit(_failures + 1)
		return
	var effect := definition.main_skill.effects[0].duplicate(true) as EnemyEffectOnElapsedTimeGrantExtraAttack
	_expect(effect != null, "17010004001が追加攻撃の付与効果を使用する")
	if effect == null:
		tooltip.hide_tooltip()
		enemy.free()
		other.free()
		seed_block.free()
		root.remove_child(tooltip)
		tooltip.free()
		quit(_failures)
		return
	effect.bind_source(enemy)
	effect.setup_enemies([enemy, other, seed_block])
	_expect(effect.target == EnemyEffect.EffectTarget.ALL_OBJECTS, "17010004001はモノ全体を対象にする")
	effect.interval_seconds = 1
	effect.stack_limit = 3
	effect.begin_activation(ProgressTimeActivationData.new(1, 1))
	effect.apply()
	_expect(seed_block.data.defense_status.extra_attack_count == 1, "最初に夢の種ブロックへ災禍を付与する")
	_expect(seed_block.get_damage() == 5, "災禍1回分で対象の攻撃力を5増やす")
	_expect(other.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 0, "他の悪夢はまだ対象にしない")
	_expect(enemy.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 0, "自身はまだ対象にしない")
	_expect(other.get_damage() == 0 and enemy.get_damage() == 0, "対象外の攻撃力は変えない")
	tooltip.show_enemy(seed_block, "", false)
	_expect(_tooltip_text(tooltip).contains("特殊効果: 災禍+1"), "夢の種ブロックのツールチップを更新する")

	effect.begin_activation(ProgressTimeActivationData.new(2, 2))
	effect.apply()
	_expect(seed_block.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 3, "夢の種ブロックへの重複付与を許可する")
	_expect(seed_block.data.defense_status.extra_attack_count == 3, "経過時間分の追加攻撃を付与する")
	_expect(seed_block.get_damage() == 15, "重複した災禍の回数分だけ攻撃力を増やす")
	_expect(other.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 0, "夢の種ブロックがある間は他の悪夢を選ばない")
	_expect(_tooltip_text(tooltip).contains("特殊効果: 災禍+3"), "重複量の合計を表示する")

	seed_block.set_Aciding(false)
	effect.begin_activation(ProgressTimeActivationData.new(1, 1))
	effect.apply()
	_expect(other.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 1, "夢の種ブロック不在なら他の悪夢へ付与する")
	_expect(other.get_damage() == 5, "他の悪夢の攻撃力も増やす")
	_expect(enemy.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 0, "他の悪夢を自身より優先する")

	other.set_Aciding(false)
	effect.begin_activation(ProgressTimeActivationData.new(1, 1))
	effect.apply()
	_expect(enemy.data.get_special_effect_amount(EnemyData.SpecialEffect.CALAMITY) == 1, "他のモノが不在なら自身へ付与する")
	_expect(enemy.get_damage() == 5, "自身の攻撃力も増やす")
	tooltip.show_enemy(enemy, "", false)
	_expect(_tooltip_text(tooltip).contains("特殊効果: 災禍+1"), "表示中のツールチップを更新する")

	effect.begin_activation(ProgressTimeActivationData.new(1, 1))
	effect.apply()
	_expect(enemy.data.defense_status.extra_attack_count == 2, "自身にも重複付与できる")
	_expect(enemy.get_damage() == 10, "自身への重複付与でも攻撃力を加算する")

	var excuse_definition := load("res://data/resources/area/area_elmena/enemy/boss/003/area_elmena_enemy_boss_003_003.tres") as EnemyInfo
	_expect(excuse_definition != null and excuse_definition.skill_id == 11020003003, "エルメナB-3の言い逃れ付与悪夢を読み込める")
	var excuse_effect := excuse_definition.main_skill.effects[0].duplicate(true) as EnemyEffectOnClockCountGrantAdjacentGuard
	_expect(excuse_effect != null, "エルメナB-3 E3が言い逃れ付与効果を使用する")
	enemy.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	other.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	enemy.set_stomach_cell(Vector2i.ZERO)
	other.set_stomach_cell(Vector2i.RIGHT)
	enemy.set_Aciding(true)
	other.set_Aciding(true)
	excuse_effect.bind_source(enemy)
	excuse_effect.setup_enemies([enemy, other])
	for _count in excuse_effect.required_count:
		excuse_effect.apply()
	_expect(other.data.get_special_effect_amount(EnemyData.SpecialEffect.EXCUSE) == 1, "隣接する悪夢へ言い逃れを特殊効果として付与する")
	tooltip.show_enemy(other, "", false)
	_expect(_tooltip_text(tooltip).contains("言い逃れ+1"), "言い逃れを他の特殊効果と同じツールチップ欄へ表示する")
	var acid_modifiers := EnemyAcidDamageModifiers.new()
	_expect(acid_modifiers.resolve(other, 100) == 0, "言い逃れで次の消化ダメージを無効化する")
	_expect(other.data.get_special_effect_amount(EnemyData.SpecialEffect.EXCUSE) == 0, "無効化時に言い逃れを1回消費する")
	_expect(not _tooltip_text(tooltip).contains("言い逃れ"), "消費した言い逃れを表示中のツールチップから除く")
	_expect(acid_modifiers.resolve(other, 100) == 100, "言い逃れ消費後は消化ダメージを通す")
	excuse_effect.unbind()

	tooltip.show_enemy(enemy, "", false)
	enemy.data.setup(null, 10, 1, false, false)
	_expect(enemy.data.special_effects.is_empty(), "個体再設定時に特殊効果を消す")
	_expect(not _tooltip_text(tooltip).contains("特殊効果:"), "特殊効果消去時に表示も消す")

	tooltip.hide_tooltip()
	effect.unbind()
	enemy.free()
	other.free()
	seed_block.free()
	root.remove_child(tooltip)
	tooltip.free()
	quit(_failures)


func _tooltip_text(tooltip: EnemyTooltip) -> String:
	return tooltip.call("_get_tooltip_text") as String


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemySpecialEffectTest: %s" % message)
