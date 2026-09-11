extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed := load("res://data/resources/seeds/skills/seed_100_124.tres") as SeedInfo
	var effects := SeedEffectResolver.new()
	effects.setup([seed])
	var rates := effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.main) * 100.0) == 2, "メイン現在値は2%から開始")
	_expect(roundi(float(rates.sub) * 100.0) == 4, "サブ現在値は4%から開始")
	effects.apply_progress_time(0, 1)
	rates = effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.main) * 100.0) == 4, "時間経過後のメイン現在値を更新する")
	_expect(roundi(float(rates.sub) * 100.0) == 4, "未発動のサブ現在値は4%を維持する")
	effects.refresh_flowers([])
	effects.add_Acided_seed_effect(seed)
	effects.apply_progress_time(1, 2)
	rates = effects.get_seed_time_reduction_rates(seed)
	_expect(roundi(float(rates.sub) * 100.0) == 8, "消化後のサブ現在値を更新する")
	_expect(
		SeedDescription.get_main_description(seed, 4).ends_with("(現在4%)"),
		"メイン説明の後ろに現在値を表示する"
	)
	_expect(
		SeedDescription.get_sub_description(seed, 8).ends_with("(現在8%)"),
		"サブ説明の後ろに現在値を表示する"
	)
	var button := (load("res://scene/ui/seed/seed_button.tscn") as PackedScene).instantiate() as SeedButton
	root.add_child(button)
	await process_frame
	button.set_seed_source(seed)
	button.set_dynamic_description_rates({"main": 4, "sub": 8})
	var tooltip_text := button.call("_get_tooltip_text") as String
	_expect(tooltip_text.contains("メイン:") and tooltip_text.contains("(現在4%)"), "ボタンのメインツールチップを更新する")
	_expect(tooltip_text.contains("サブ:") and tooltip_text.contains("(現在8%)"), "ボタンのサブツールチップを更新する")
	button.queue_free()
	await process_frame
	print("Seed100124DynamicDescriptionTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Seed100124DynamicDescriptionTest: %s" % message)
