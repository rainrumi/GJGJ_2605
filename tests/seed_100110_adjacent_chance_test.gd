extends SceneTree

const SEED_PATH := "res://data/resources/seeds/skills/seed_100_110.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var belladonna := load(SEED_PATH) as SeedInfo
	_expect(belladonna != null, "ベラドンナを読み込める")
	if belladonna == null:
		quit(_failures)
		return
	_expect(
		belladonna.sub_description == "この花と隣接しているモノが持つすべての確率を2倍にする",
		"サブスキル説明を更新する"
	)
	var effect := belladonna.sub_skill.effects[0] as SeedEffectOnAdjacentObjectChangeChance
	_expect(effect != null and effect.chance_multiplier == 2.0, "隣接確率2倍効果を設定する")

	var source := _create_object(Vector2i.RIGHT, belladonna)
	var nightmare := _create_object(Vector2i.ZERO)
	var flower_seed := belladonna.duplicate(true) as SeedInfo
	flower_seed.sub_skill = null
	var flower := _create_object(Vector2i(2, 0), flower_seed)
	var distant := _create_object(Vector2i(4, 0))
	var objects: Array[Enemy] = [source, nightmare, flower, distant]
	var resolver := DreamSeedBlockAcidResolver.new()
	resolver.apply_refresh_modifiers(objects)

	_expect(nightmare.data.defense_status.chance_multiplier == 2.0, "隣接悪夢の確率を2倍にする")
	_expect(flower.data.defense_status.chance_multiplier == 2.0, "隣接する夢の種の確率を2倍にする")
	_expect(source.data.defense_status.chance_multiplier == 1.0, "ベラドンナ自身は対象外")
	_expect(distant.data.defense_status.chance_multiplier == 1.0, "非隣接のモノは対象外")
	_check_enemy_probability(nightmare)
	_check_seed_probability(flower)

	for object in objects:
		object.data.defense_status.reset_refresh_modifiers()
	source.set_stomach_cell(Vector2i(5, 0))
	resolver.apply_refresh_modifiers(objects)
	_expect(nightmare.data.defense_status.chance_multiplier == 1.0, "隣接解除後は悪夢の倍率を戻す")
	_expect(flower.data.defense_status.chance_multiplier == 1.0, "隣接解除後は夢の種の倍率を戻す")

	for object in objects:
		object.free()
	print("Seed100110AdjacentChanceTest: %d failures" % _failures)
	quit(_failures)


func _create_object(cell: Vector2i, seed_info: SeedInfo = null) -> Enemy:
	var object := Enemy.new()
	var info := EnemyInfo.new()
	info.acid_block = AcidBlockInfo.new()
	info.acid_block.max_hp = 100
	info.acid_block.stomach_shape = [PackedInt32Array([1])]
	object.data.setup(info, 100, 1, seed_info == null, seed_info == null)
	object.seed_info = seed_info
	object.set_stomach_footprint_override(Vector2i.ONE, [Vector2i.ZERO], 1)
	object.set_stomach_cell(cell)
	object.set_Aciding(true)
	return object


func _check_enemy_probability(nightmare: Enemy) -> void:
	for trial in range(16):
		seed(11000 + trial)
		var expected := randf() <= 0.8
		seed(11000 + trial)
		_expect(
			EnemyEffectValueCalculator.roll(nightmare, 0.4) == expected,
			"悪夢の確率判定へ2倍補正を反映する"
		)


func _check_seed_probability(flower: Enemy) -> void:
	var probability_effect := flower.get_seed().main_skill.effects[0] as SeedEffect
	probability_effect.probability_configured = true
	probability_effect.probability_fields = PackedStringArray(["probabirlity"])
	var adjusted := probability_effect.adjusted_for_seed_block(flower)
	_expect(is_equal_approx(float(adjusted.get("probabirlity")), 0.1), "夢の種の確率変数へ2倍補正を反映する")


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Seed100110AdjacentChanceTest: %s" % message)
