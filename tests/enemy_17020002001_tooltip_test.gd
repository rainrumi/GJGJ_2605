extends SceneTree

const E1_PATH := "res://data/resources/area/area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_001.tres"
const E2_PATH := "res://data/resources/area/area_lunova/enemy/boss/002/area_lunova_enemy_boss_002_002.tres"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect_tooltip_chance(E1_PATH, 17020002001, "E1")
	_expect_tooltip_chance(E2_PATH, 17020002002, "E2")
	_expect_adjusted_tooltip_chance(E1_PATH, 17020002001, 128.0, "E1・ベラドンナ7個")
	var unrelated := EnemyInfo.new()
	unrelated.skill_id = 999999
	unrelated.description = "説明"
	_expect(
		EnemyTooltipFormatter.get_main_effect_text(true, unrelated) == "説明",
		"対象外の悪夢には確率表示を追加しない"
	)
	print("Enemy17020002001TooltipTest: %d failures" % _failures)
	quit(_failures)


func _expect_tooltip_chance(path: String, skill_id: int, label: String) -> void:
	var info := load(path) as EnemyInfo
	_expect(info != null and info.skill_id == skill_id, "%sのResourceを読み込む" % label)
	if info == null:
		return
	var text := EnemyTooltipFormatter.get_main_effect_text(true, info)
	_expect(text.ends_with("(確率:1.0%)"), "%sのツールチップ末尾に確率を小数第1位で表示する" % label)


func _expect_adjusted_tooltip_chance(path: String, skill_id: int, multiplier: float, label: String) -> void:
	var info := load(path) as EnemyInfo
	_expect(info != null and info.skill_id == skill_id, "%sのResourceを読み込む" % label)
	if info == null:
		return
	var data := EnemyData.new()
	data.setup(info, info.acid_block.get_max_hp(), info.acid_block.get_damage(), true, true)
	data.defense_status.chance_multiplier = multiplier
	var text := EnemyTooltipFormatter.get_main_effect_text(true, info, data)
	_expect(text.ends_with("(確率:100.0%)"), "%sの補正後確率を上限込みで表示する" % label)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("Enemy17020002001TooltipTest: %s" % message)
