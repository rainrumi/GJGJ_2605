extends Node

const STAGE_CLEAR_SCENE := preload("res://scene/main/stage_clear/stage_clear.tscn")

var _failures := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var stage_clear := STAGE_CLEAR_SCENE.instantiate()
	add_child(stage_clear)
	await get_tree().process_frame

	var character := stage_clear.character as Character
	_expect(character != null, "ステージクリア画面で共通Characterを使用する")
	character.face_button.pressed.emit()
	_expect(
		character.sprite.texture == character.face_clicked_texture,
		"ステージクリア画面でも頭のボタンで表情が変わる"
	)
	stage_clear.setup_clear_result(100, 22 * 60)
	_expect(
		character.sprite.texture == character.normal_texture,
		"ステージクリア画面へ入るたびに通常表情へ戻る"
	)

	var four_flowers: Array[SeedInfo] = []
	for _index in range(stage_clear.FACE_BUTTON_BLOCKING_FLOWER_COUNT):
		four_flowers.append(SeedInfo.new())
	stage_clear.set_seed_inventory(four_flowers, [])
	_expect(character.face_button.disabled, "装備中の種が4個以上なら頭のボタンを無効にする")

	four_flowers.pop_back()
	stage_clear.set_seed_inventory(four_flowers, [])
	_expect(not character.face_button.disabled, "装備中の種が3個以下なら頭のボタンを有効にする")

	remove_child(stage_clear)
	stage_clear.free()
	four_flowers.clear()
	stage_clear = null
	await get_tree().process_frame
	get_tree().quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		print("PASS: %s" % message)
		return
	_failures += 1
	push_error("FAIL: %s" % message)
