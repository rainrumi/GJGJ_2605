extends SceneTree

const CHARACTER_SCENE := preload("res://scene/object/character/character.tscn")

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var character := CHARACTER_SCENE.instantiate() as Character
	root.add_child(character)
	await process_frame

	character.face_button.pressed.emit()
	_expect(
		character.sprite.texture == character.face_clicked_texture,
		"FaceButtonのクリックでキャラクター画像が専用表情に変わる"
	)
	_expect(
		character.face_clicked_texture.resource_path.ends_with(
			"tex_character_200_portrate_4000.png"
		),
		"FaceButton用画像にtex_character_200_portrate_4000.pngが設定されている"
	)
	character.face_button.pressed.emit()
	_expect(
		character.get("_face_change_count") == 1,
		"既にFaceButton用表情の場合は変更回数を増やさない"
	)

	for _change_index in range(Character.SPECIAL_FACE_CHANGE_COUNT - 1):
		character.show_normal_texture()
		character.face_button.pressed.emit()
	_expect(
		character.get("_face_change_count") == Character.SPECIAL_FACE_CHANGE_COUNT,
		"有効な表情変更を50回まで数える"
	)
	_expect(
		character.sprite.texture == character.special_face_clicked_texture,
		"50回目の表情変更で特別表情に変わる"
	)
	_expect(
		character.special_face_clicked_texture.resource_path.ends_with(
			"tex_character_200_portrate_5000.png"
		),
		"50回目以降の画像にtex_character_200_portrate_5000.pngが設定されている"
	)
	character.face_button.pressed.emit()
	_expect(
		character.get("_face_change_count") == Character.SPECIAL_FACE_CHANGE_COUNT,
		"既に特別表情の場合も変更回数を増やさない"
	)

	character.show_normal_texture()
	character.set_face_button_enabled(false)
	character.face_button.pressed.emit()
	_expect(character.face_button.disabled, "夢の種表示中はFaceButtonを無効化できる")
	_expect(
		character.sprite.texture == character.normal_texture,
		"夢の種表示中はFaceButtonが表情を変更しない"
	)
	_expect(
		character.get("_face_change_count") == Character.SPECIAL_FACE_CHANGE_COUNT,
		"夢の種表示中の入力は変更回数に数えない"
	)

	root.remove_child(character)
	character.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
