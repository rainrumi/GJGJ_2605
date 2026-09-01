extends SceneTree

var _failures := 0


func _initialize() -> void:
	var anemone := load("res://data/resources/seeds/skills/seed_100_104.tres") as SeedInfo
	_expect(anemone != null, "アネモネを読み込める")
	if anemone == null:
		quit(_failures)
		return
	var effects := SeedEffectResolver.new()
	effects.setup([anemone])

	_expect(effects.get_rest_hp(100, 0.1) == 10, "アネモネは通常の休憩回復量を増やさない")
	effects.add_revive_event()
	_expect(effects.get_max_hp_bonus_rate() == 0.0, "アネモネは蘇生時にHP上限補正を加算しない")
	_expect(effects.get_revive_hp(100, 0.1) == 60, "蘇生回復量にHP上限の50%を加算する")
	effects.add_revive_event()
	_expect(effects.get_max_hp_bonus_rate() == 0.0, "複数回蘇生してもHP上限補正を加算しない")
	_expect(effects.get_revive_hp(100, 0.1) == 60, "蘇生回復補正は蘇生回数で累積しない")
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("AnemoneReviveRecoveryTest: %s" % message)
