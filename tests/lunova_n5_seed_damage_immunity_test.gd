extends Node

const PRESET_PATH := "res://data/resources/area/area_lunova/enemy/normal/005/area_lunova_enemy_normal_preset_005.tres"
const SEED_PATH := "res://data/resources/seeds/skills/seed_100_121.tres"

var _failures := 0
var _checks := 0


func _ready() -> void:
	call_deferred("_run")


func _run() -> void:
	var game: Node = load("res://scene/main/game/game.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	_test_seed_damage(game, false, 3000, true, 5000)
	_test_seed_damage(game, true, 3000, true, 5000)
	_test_seed_damage(game, false, 3000, false, 2000)
	_test_seed_damage(game, false, 4999, true, 5000)
	_test_seed_damage(game, false, 5000, true, 0)
	_test_seed_damage(game, false, 5001, true, 0)
	game.enemy_effects.reset()
	game.attack_se.stop()
	game.queue_free()
	await get_tree().process_frame
	print("LunovaN5SeedDamageImmunityTest: %d checks, %d failures" % [_checks, _failures])
	get_tree().quit(_failures)


func _test_seed_damage(
	game: Node, extra_digestion: bool, amount: int, skill_active: bool, expected_hp: int
) -> void:
	var seed := load(SEED_PATH) as SeedInfo
	if amount != 3000:
		seed = seed.duplicate(true) as SeedInfo
		var effect := seed.sub_skill.effects[0] as SeedEffectOnFinishAcidSeedBlockDamageAdjacent
		effect.player_max_hp_rate = 0.0
		effect.damage = amount
	var context := BattleInfo.new()
	context.enemy_preset = load(PRESET_PATH) as EnemyPresetInfo
	context.flowers = [seed]
	game.start_battle(context)
	var target: Enemy = game.enemies[0]
	_expect(target.get_enemy_info().skill_id == 17010005001, "LOC-N-5のE1を使用する")
	target.data.main_skill_active = skill_active
	target.set_Aciding(true)
	game.stomach.place_enemy(target, Vector2i(0, game.stomach.rows - 3))
	_expect(game.stomach.get_bottom_row_cell_count(target) == 0, "E1を消化ライン外へ配置する")
	var source: Enemy = game.seed_controller._create_seed_block(seed)
	game.enemies.append(source)
	source.set_Aciding(true)
	game.stomach.place_enemy(source, Vector2i(1, game.stomach.rows - 1))
	_expect(game.stomach.get_bottom_row_cell_count(source) == 1, "オトギリソウをE1に隣接する消化ラインへ配置する")
	game.acid_controller.refresh_enemy_effects(game.enemies, game.stomach)
	var received_before := target.received_acid_damage_total
	var digested: Array[Enemy]
	if extra_digestion:
		source.set_Acided(true)
		digested = game._resolve_extra_seed_digestions([source] as Array[Enemy])
	else:
		digested = game.acid_controller.acid_enemys(game.enemies, game.stomach, game.minutes, 30, 100, 100)
	_expect(digested.has(source), "オトギリソウを消化してサブスキルを発動する")
	_expect(target.current_hp == expected_hp, "%s: %dダメージ、スキル有効=%sでE1のHPは%d" % ["追加消化" if extra_digestion else "通常消化", amount, skill_active, expected_hp])
	_expect(target.received_acid_damage_total - received_before == (amount if expected_hp < 5000 else 0), "無効化後のダメージだけを受領量に加算する")
	_expect(digested.has(target) == (expected_hp == 0), "無効化されたE1を消化済み一覧へ追加しない")
	var damage_popup: Label
	for child in target.get_children():
		if child is Label and child.get_meta(EnemyDamagePopup.POPUP_META, false):
			damage_popup = child
	var expected_popup := "0" if expected_hp == 5000 else "-%d" % amount
	_expect(damage_popup != null and damage_popup.text == expected_popup, "ダメージ表示も無効化後の値にする")


func _expect(condition: bool, message: String) -> void:
	_checks += 1
	if condition:
		return
	_failures += 1
	push_error("LunovaN5SeedDamageImmunityTest: %s" % message)
