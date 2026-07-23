extends SceneTree

const AREA_EXPECTED_COUNTS := {
	"area_iriyu": 43,
	"area_riran": 52,
	"area_elmena": 45,
	"area_lunova": 32,
}

var _failures := 0 # 失敗数
var _skill_ids: Dictionary = {} # ID重複確認


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# Phase1敵Resource試験
func _run() -> void:
	for area: String in AREA_EXPECTED_COUNTS:
		var path := "res://data/resources/area/%s/enemy" % area # エリア敵定義
		var loaded_count := _load_enemy_resources(path) # 読込数
		_expect(
			loaded_count == AREA_EXPECTED_COUNTS[area],
			"%s のEnemyInfo数: expected=%d actual=%d" % [area, AREA_EXPECTED_COUNTS[area], loaded_count]
		)
	_expect(_skill_ids.size() == 172, "SkillID総数が172")
	quit(_failures)


# EnemyInfo再帰読込
func _load_enemy_resources(path: String) -> int:
	var directory := DirAccess.open(path) # 対象フォルダ
	if directory == null:
		_expect(false, "フォルダを開ける: %s" % path)
		return 0
	var loaded_count := 0 # 読込数
	directory.list_dir_begin()
	var entry := directory.get_next() # 対象項目
	while not entry.is_empty():
		var child_path := path.path_join(entry) # 子項目パス
		if directory.current_is_dir():
			if entry != "endless":
				loaded_count += _load_enemy_resources(child_path)
		elif entry.ends_with(".tres") and not entry.contains("_preset_"):
			loaded_count += 1
			_validate_enemy_resource(child_path)
		entry = directory.get_next()
	directory.list_dir_end()
	return loaded_count


# EnemyInfo内容確認
func _validate_enemy_resource(path: String) -> void:
	var enemy := load(path) as EnemyInfo # 敵定義
	_expect(enemy != null, "EnemyInfoを読込める: %s" % path)
	if enemy == null:
		return
	_expect(enemy.skill_id > 0, "SkillIDが設定済み: %s" % path)
	_expect(not _skill_ids.has(enemy.skill_id), "SkillIDが重複しない: %d" % enemy.skill_id)
	_skill_ids[enemy.skill_id] = path
	var expected_name := "E%s" % path.get_file().get_basename().get_slice("_", 5).to_int()
	_expect(enemy.display_name == expected_name, "DisplayNameがファイル内敵IDと一致: %s" % path)
	_expect(enemy.acid_block != null, "AcidBlockが設定済み: %s" % path)
	_expect(enemy.enemy_skill_enabled, "EnemySkillEnabledがtrue: %s" % path)
	if enemy.acid_block != null:
		_expect(enemy.acid_block.get_max_hp() >= 1, "MaxHpが有効: %s" % path)
		_expect(enemy.acid_block.get_damage() >= 0, "Damageが有効: %s" % path)
		_expect(enemy.acid_block.get_cell_count() >= 1, "StomachShapeが有効: %s" % path)
	if enemy.main_skill == null:
		return
	_expect(enemy.main_skill.has_effects(), "MainSkillにEnemyEffectがある: %s" % path)
	for skill_effect: EnemyEffect in enemy.main_skill.effects:
		_expect(skill_effect != null, "EnemyEffectを読込める: %s" % path)
		if skill_effect != null:
			_expect(skill_effect.priority == 0, "EnemyEffect priorityが0: %s" % path)


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("EnemyPhase1ResourceTest: %s" % message)
