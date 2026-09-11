extends Node

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed := load("res://data/resources/seeds/skills/seed_100_124.tres") as SeedInfo
	var effects := SeedEffectResolver.new()
	effects.setup([seed])
	var rates := effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.main) * 100.0) == 2, "メイン現在値は2%から開始")
	_expect(roundi(float(rates.sub) * 100.0) == 3, "サブ現在値は3%から開始")
	effects.apply_progress_time(0, 1)
	rates = effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.main) * 100.0) == 4, "時間経過後のメイン現在値を更新する")
	_expect(roundi(float(rates.sub) * 100.0) == 6, "未消化のサブ現在値は時間経過で6%へ増える")
	effects.refresh_flowers([])
	effects.add_Acided_seed_effect(seed)
	effects.apply_progress_time(1, 2)
	rates = effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.sub) * 100.0) == 6, "消化後のサブ現在値は消化時点の6%を維持する")
	_expect(
		SeedDescription.get_main_description(seed, 4).ends_with("(現在4%)"),
		"メイン説明の後ろに現在値を表示する"
	)
	_expect(
		SeedDescription.get_sub_description(seed, 8).ends_with("(現在8%)"),
		"サブ説明の後ろに現在値を表示する"
	)
	var button := (load("res://scene/ui/seed/seed_button.tscn") as PackedScene).instantiate() as SeedButton
	get_tree().root.add_child(button)
	await get_tree().process_frame
	button.set_seed_source(seed)
	button.set_dynamic_description_rates({"main": 4, "sub": 8})
	var tooltip_text := button.call("_get_tooltip_text") as String
	_expect(tooltip_text.contains("メイン:") and tooltip_text.contains("(現在4%)"), "ボタンのメインツールチップを更新する")
	_expect(tooltip_text.contains("サブ:") and tooltip_text.contains("(現在8%)"), "ボタンのサブツールチップを更新する")
	var moon := load("res://data/resources/seeds/skills/seed_100_106.tres") as SeedInfo
	button.set_seed_source(moon)
	button.set_dynamic_description_rates({"main": 20})
	_expect((button.call("_get_tooltip_text") as String).contains("(現在20%)"), "100106の累積消化ダメージをツールチップへ表示する")
	var sunflower := load("res://data/resources/seeds/skills/seed_100_120.tres") as SeedInfo
	button.set_seed_source(sunflower)
	button.set_dynamic_description_rates({"main": 10})
	_expect((button.call("_get_tooltip_text") as String).contains("(現在+10%)"), "100120のHP上限増加を符号付きでツールチップへ表示する")
	button.queue_free()
	await get_tree().process_frame
	print("Seed100124DynamicDescriptionTest: %d failures" % _failures)
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Seed100124DynamicDescriptionTest: %s" % message)
