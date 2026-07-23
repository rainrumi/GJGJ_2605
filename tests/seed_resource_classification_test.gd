extends SceneTree

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var epic_seed := SeedInfo.new()
	epic_seed.skill_id = 999
	epic_seed.rarity = SeedInfo.Rarity.EPIC

	var pool := SeedPoolInfo.new()
	pool.epic_skills = [epic_seed]
	_expect(pool.get_all_skills() == [epic_seed], "EPIC種をステージ抽選候補へ含める")

	var catalog := SeedCatalogInfo.new()
	catalog.epic_skills = [epic_seed]
	_expect(
		catalog.get_skills_by_rarity(SeedInfo.Rarity.EPIC, epic_seed.skill_id) == [epic_seed],
		"EPIC種をレアリティとIDで取得できる"
	)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("SeedResourceClassificationTest: %s" % message)
