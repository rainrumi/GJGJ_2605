extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "game.tscnを読み込める")
	if packed == null:
		quit(_failures)
		return

	var game := packed.instantiate()
	root.add_child(game)
	await process_frame

	var hp_view := game.get_node("UI/HpView") as HpView
	var icon := hp_view.get_node("DigestiveHpIcon") as TextureRect
	var hit_area := hp_view.get_node("TooltipHitArea") as Control
	_expect(icon.texture != null, "HPアイコンのTextureを読み込める")
	_expect(icon.position.x < 0.0 and icon.position.x + icon.size.x > 0.0, "HPアイコンがHPバー左端に重なる")
	_expect(hit_area.get_global_rect().encloses(icon.get_global_rect()), "ツールチップ判定がHPアイコン全体を覆う")
	_expect(hit_area.get_global_rect().encloses(hp_view.get_global_rect()), "ツールチップ判定がHPバー全体を覆う")
	_expect(hit_area.mouse_filter == Control.MOUSE_FILTER_STOP, "ツールチップ判定がマウス入力を受け取る")
	_expect(hp_view.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HPバー本体に重複したツールチップ判定がない")
	hit_area.mouse_entered.emit()
	_expect(hp_view.hp_tooltip.visible, "単一のツールチップ判定からHPツールチップを開ける")
	hit_area.mouse_exited.emit()
	_expect(not hp_view.hp_tooltip.visible, "ツールチップ判定から離れるとHPツールチップを閉じる")

	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("HpTooltipHitAreaTest: %s" % message)
