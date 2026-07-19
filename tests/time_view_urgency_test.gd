extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/ui/view/time_view.tscn") as PackedScene
	_expect(packed != null, "時刻表示Sceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var time_view := packed.instantiate() as TimeView
	root.add_child(time_view)
	await process_frame
	var time_text := time_view.get_node("TimeText") as Label

	time_view.set_time(22 * 60)
	_expect(time_text.text == "22:00", "開始時刻を表示する")
	_expect(
		time_text.self_modulate.is_equal_approx(TimeView.TIME_NORMAL_COLOR),
		"22:00は通常色にする"
	)

	time_view.set_time(28 * 60)
	_expect(time_text.text == "04:00", "翌日の4:00を表示する")
	_expect(
		time_text.self_modulate.is_equal_approx(TimeView.TIME_WARNING_COLOR),
		"4:00は薄い赤色にする"
	)

	time_view.set_time(28 * 60 + 30)
	_expect(
		time_text.self_modulate.g < TimeView.TIME_WARNING_COLOR.g
		and time_text.self_modulate.g > TimeView.TIME_DANGER_COLOR.g,
		"4:00から5:00へ赤色を強める"
	)

	time_view.set_time(29 * 60)
	_expect(
		time_text.self_modulate.is_equal_approx(TimeView.TIME_DANGER_COLOR),
		"5:00は赤色にする"
	)
	_expect(time_view.get("_time_text_heartbeat_tween") == null, "5:00では鼓動を開始しない")

	time_view.set_time(29 * 60 + 30)
	var heartbeat_tween := time_view.get("_time_text_heartbeat_tween") as Tween
	_expect(heartbeat_tween != null and heartbeat_tween.is_valid(), "5:30は鼓動を開始する")
	time_view.show_elapsed(30)
	_expect(
		time_view.get("_time_text_heartbeat_tween") == heartbeat_tween,
		"経過時間を表示しても鼓動を継続する"
	)
	await create_timer(TimeView.TIME_HEARTBEAT_GROW_DURATION * 0.5).timeout
	_expect(time_text.scale.x > 1.0, "鼓動で時刻の数字を拡大する")

	time_view.set_time(30 * 60)
	_expect(time_text.text == "06:00", "終了時刻を表示する")
	_expect(
		time_text.self_modulate.is_equal_approx(TimeView.TIME_NORMAL_COLOR),
		"6:00で通常色へ戻す"
	)
	_expect(time_view.get("_time_text_heartbeat_tween") == null, "6:00で鼓動を停止する")
	_expect(time_text.scale.is_equal_approx(Vector2.ONE), "鼓動停止時に元のサイズへ戻す")

	root.remove_child(time_view)
	time_view.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("TimeViewUrgencyTest: %s" % message)
