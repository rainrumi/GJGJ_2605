extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var owner := Node2D.new()
	root.add_child(owner)
	var hp_label := Label.new()
	hp_label.position = Vector2(-37.0, -25.0)
	hp_label.size = Vector2(74.0, 24.0)
	owner.add_child(hp_label)

	EnemyDamagePopup.show_damage(owner, hp_label, 10, Color.RED)
	var first_popup := owner.get_child(1) as Label
	EnemyDamagePopup.show_damage(owner, hp_label, 20, Color.RED)
	var second_popup := owner.get_child(2) as Label

	_expect(first_popup != null, "最初の被弾ダメージUIを生成する")
	_expect(second_popup != null, "同時刻の被弾ダメージUIを生成する")
	if first_popup != null and second_popup != null:
		_expect(first_popup.text == "-10", "最初の被弾ダメージ値を表示する")
		_expect(second_popup.text == "-20", "次の被弾ダメージ値を表示する")
		_expect(
			second_popup.position.y + second_popup.size.y <= first_popup.position.y,
			"同時刻の被弾ダメージUIをY座標方向にずらす"
		)

	await process_frame
	await process_frame
	EnemyDamagePopup.show_damage(owner, hp_label, 30, Color.RED)
	var latest_popup := owner.get_child(owner.get_child_count() - 1) as Label
	_expect(not first_popup.visible, "新しい被弾時に以前の最初のUIを非表示にする")
	_expect(not second_popup.visible, "新しい被弾時に以前の次のUIを非表示にする")
	_expect(first_popup.is_queued_for_deletion(), "以前の最初の被弾UIを解放する")
	_expect(second_popup.is_queued_for_deletion(), "以前の次の被弾UIを解放する")
	_expect(latest_popup != null, "新しい被弾ダメージUIを生成する")
	if latest_popup != null:
		var expected_y := hp_label.position.y - latest_popup.size.y + hp_label.size.y * 0.3
		_expect(latest_popup.visible, "新しい被弾ダメージUIを表示する")
		_expect(latest_popup.text == "-30", "新しい被弾ダメージ値を表示する")
		_expect(
			is_equal_approx(latest_popup.position.y, expected_y),
			"新しい被弾ダメージUIを基準Y座標から表示する"
		)

	owner.queue_free()
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyDamagePopupTest: %s" % message)
