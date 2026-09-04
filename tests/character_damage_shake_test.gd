extends SceneTree

const SAMPLE_INTERVAL := 0.01
const SAMPLE_COUNT := 19
const POSITION_MARGIN := 0.1

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scene/main/game/game.tscn") as PackedScene
	_expect(packed != null, "ゲームSceneを読み込める")
	if packed == null:
		quit(_failures)
		return
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	(game.get_node("AttackSe") as AudioStreamPlayer).stream = null
	var character := game.get_node("Character") as Character
	var sprite := game.get_node("Character/Sprite2D") as Sprite2D
	var base_x := sprite.position.x
	var minimum_x := base_x
	var maximum_x := base_x
	var damage_values: Array[int] = [1]
	var normal_texture := load(
		"res://resource/image/texture/character/tex_character_200_portrate_1000.png"
	) as Texture2D
	var damage_texture := load(
		"res://resource/image/texture/character/tex_character_200_portrate_2000.png"
	) as Texture2D
	var battle_clear_texture := load(
		"res://resource/image/texture/character/tex_character_200_portrate_3000.png"
	) as Texture2D

	_expect(sprite.texture == normal_texture, "ゲーム開始時は通常表情で上書きする")
	_expect(Character.SHAKE_DURATION == 0.2, "シェイク時間が0.2秒である")
	_expect(Character.SHAKE_DISTANCE == 1.0, "シェイク幅が1.0である")
	game.call("_apply_player_damage", damage_values)
	_expect(sprite.texture == damage_texture, "被ダメージ振動中はダメージ画像を表示する")
	var shake_tween := character.get("_shake_tween") as Tween
	for _sample in range(SAMPLE_COUNT):
		shake_tween.custom_step(SAMPLE_INTERVAL)
		minimum_x = minf(minimum_x, sprite.position.x)
		maximum_x = maxf(maximum_x, sprite.position.x)

	_expect(minimum_x < base_x - POSITION_MARGIN, "被ダメージ時に左へ動く")
	_expect(maximum_x > base_x + POSITION_MARGIN, "被ダメージ時に右へ動く")
	shake_tween.custom_step(SAMPLE_INTERVAL * 2.0)
	_expect(is_equal_approx(sprite.position.x, base_x), "0.2秒後に基準位置へ戻る")
	_expect(sprite.texture == damage_texture, "振動終了後もダメージ画像を維持する")

	game.call("_apply_player_damage", damage_values)
	_expect(sprite.texture == damage_texture, "連続被ダメージ時はダメージ画像を上書きする")
	game.call("_apply_player_damage_values")
	_expect(sprite.texture == normal_texture, "ダメージを受けない状態で通常画像へ戻す")
	game.call("_finish_battle", true, "")
	_expect(sprite.texture == battle_clear_texture, "戦闘勝利後はクリア画像を表示する")
	game.call("start_battle")
	_expect(sprite.texture == normal_texture, "次の戦闘開始時は通常画像へ戻す")

	root.remove_child(game)
	game.free()
	await process_frame
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("CharacterDamageShakeTest: %s" % message)
