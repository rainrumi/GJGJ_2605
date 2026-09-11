extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var seed := load("res://data/resources/seeds/skills/seed_100_116.tres") as SeedInfo
	var stomach := (load("res://scene/object/stomach/stomach.tscn") as PackedScene).instantiate() as StomachBoard
	root.add_child(stomach)
	await process_frame
	stomach.set_grid_size(4, 5)
	var effects := SeedEffectResolver.new()
	effects.setup([])
	_expect(effects.add_Acided_seed_effect(seed, 0, stomach), "100116のサブ効果が発動する")
	_expect(stomach.columns == 4 and stomach.rows == 8, "胃袋マスが縦だけ3マス増える")
	_expect(
		effects.get_persistent_stomach_rows_bonus() == 3,
		"構造再計算用の縦3マス補正を保持する"
	)
	_expect(
		effects.get_acid_damage_breakdown(100, 0.0, 0).total == 100,
		"旧サブ効果の消化ダメージ+10%が発動しない"
	)
	effects.setup([])
	_expect(
		effects.get_persistent_stomach_rows_bonus() == 0,
		"次の戦闘開始時に縦3マス補正を持ち越さない"
	)
	stomach.queue_free()
	await process_frame
	print("Seed100116SubStomachSizeTest: %d failures" % _failures)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures += 1
		push_error("Seed100116SubStomachSizeTest: %s" % message)
