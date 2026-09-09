extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var schedule := load("res://data/resources/rara/lara_schedule.tres") as LaraScheduleInfo
	_expect(schedule.validate().is_empty(), "全予定の時刻・順序・値が有効")
	var lines := FileAccess.get_file_as_string("res://data/resources/rara/acid_mater.txt").strip_edges().split("\n")
	_expect(schedule.days.size() == lines.size(), "元データと日数が一致")
	var total := 0
	for index in range(lines.size()):
		var day := schedule.days[index]
		var expected := lines[index].strip_edges().to_int()
		_expect(day.get_digestion_count(1800) == expected, "%d日目の合計が元データと一致" % (index + 1))
		_expect(schedule.get_total_digestion_count(index + 1, 1320) == total, "日開始時は前日までの累積値")
		total += expected
		_expect(schedule.get_total_digestion_count(index + 1, 1800) == total, "朝6時は当日分を含む累積値")
		var last := day.digestions.back() as LaraDigestionInfo
		_expect(last.end_hour >= 3 and last.end_hour <= 5, "その日の最終加算は3〜5時台")
	var first := schedule.days[0].digestions[0]
	var boundary := first.get_end_minutes()
	_expect(schedule.get_total_digestion_count(1, boundary - 1) == 0, "終了1分前は未加算")
	_expect(schedule.get_total_digestion_count(1, boundary) == 1, "終了時刻に加算")
	_expect(schedule.get_area(1, boundary) == first.area, "終了時刻まではそのエリアにいる")
	_expect(schedule.get_area(1, boundary + 1) == schedule.days[0].digestions[1].area, "翌分に次エリアへ移る")
	_expect(schedule.get_area(1, 1800) == schedule.days[0].fallback_area, "予定終了後は予定外エリア")
	_expect(schedule.get_total_digestion_count(1, 180) == schedule.get_total_digestion_count(1, 1620),
		"午前3時の24時間表記と30時間表記を同じ時刻として扱う")
	var catalog := load("res://data/resources/area/lara_location_catalog.tres") as StageCatalogInfo
	var state := RunState.new()
	state.current_minutes = boundary
	state.update_lara_progress(schedule, catalog.stages)
	_expect(state.lara_digestion_count == 1 and state.lara_current_location == null, "解放前も消化数だけ進む")
	state.unlock_lara()
	state.update_lara_progress(schedule, catalog.stages)
	var location := state.lara_current_location
	state.update_lara_progress(schedule, catalog.stages)
	_expect(state.lara_digestion_count == 1 and state.lara_current_location == location, "再同期で数・場所が変わらない")
	state.current_day = 5
	state.current_minutes = 1320
	state.update_lara_progress(schedule, catalog.stages)
	_expect(state.lara_digestion_count == 8, "休息や日飛ばしでも前4日分を含む")
	var normal := StageInfo.new()
	normal.stage_id = 1
	normal.stage_area = StageInfo.StageArea.LUNOVA_OLD_CITY
	state.record_stage_clear(normal)
	var boss := normal.create_high_difficulty_fallback()
	state.record_stage_clear(boss)
	_expect(state.get_player_digestion_count() == 2, "通常とボスの勝利は各1加算")
	_expect(state.get_lunova_boss_defeat_count() == 1, "旧市街ボスは通常と分けて数える")
	state.reset()
	_expect(state.get_player_digestion_count() == 0 and state.lara_digestion_count == 0, "ニューゲームは両者0")
	print("LaraScheduleTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error(message)
