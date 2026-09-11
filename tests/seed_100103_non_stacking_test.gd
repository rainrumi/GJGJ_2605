extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed := load("res://data/resources/seeds/skills/seed_100_103.tres") as SeedInfo
	_expect(seed != null, "夢の種100103を読み込める")
	_expect(
		StageClearCalculatorRecovery.can_receive_seed(seed, [seed, seed]),
		"同じ種を所持していても追加取得できる"
	)
	var effects := SeedEffectResolver.new()
	effects.setup([seed, seed])
	_expect(
		is_equal_approx(effects.get_time_reduction_rate(), 0.2),
		"メイン効果は複数装備しても20%だけ発動する"
	)
	effects.add_Acided_seed_effect(seed)
	effects.add_Acided_seed_effect(seed)
	_expect(
		is_equal_approx(effects.get_time_reduction_rate(), 0.7),
		"サブ効果はメインと独立して50%だけ発動する"
	)
	print("Seed100103NonStackingTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("Seed100103NonStackingTest: %s" % message)
