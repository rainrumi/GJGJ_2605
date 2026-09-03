extends SceneTree

var _failures := 0


func _initialize() -> void:
	var seed := load("res://data/resources/seeds/skills/seed_100_109.tres") as SeedInfo
	_expect(seed != null, "夢の種100109を読み込める")
	if seed == null:
		quit(_failures)
		return

	var effects := SeedEffectResolver.new()
	effects.setup([seed])
	var before := effects.get_acid_damage_breakdown(100, 0.0, 0, false, 0, 0, 3)
	_expect(before.seed_buff == 20, "消化前はメイン効果だけを消化ダメージへ反映する")

	effects.refresh_flowers([])
	_expect(effects.add_Acided_seed_effect(seed), "消化時に100109の副効果を発動する")
	var active := effects.get_acid_damage_breakdown(100, 0.0, 0, false, 0, 0, 3)
	_expect(active.seed_buff == 50, "消化後の+50%を夢の種バフへ反映する")
	_expect(is_equal_approx(float(active.seed_rate), 0.5), "消化後の倍率を夢の種倍率へ反映する")

	var inactive := effects.get_acid_damage_breakdown(100, 0.0, 0, false, 0, 0, 4)
	_expect(inactive.seed_buff == 0, "胃内が4体以上なら持続効果を適用しない")

	effects.refresh_flowers([])
	var after_sync := effects.get_acid_damage_breakdown(100, 0.0, 0, false, 0, 0, 3)
	_expect(after_sync.seed_buff == 50, "装備同期後も今回のゲーム中は副効果を保持する")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Seed100109PersistentSubEffectTest: %s" % message)
