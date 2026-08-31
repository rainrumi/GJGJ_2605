extends Node

signal debug_enabled_changed(is_enabled: bool)
signal seed_performance_mark_changed(seed_id: int, is_marked: bool)

const SEED_PERFORMANCE_MARK_PATH := "res://resource/debug/dream_seed_performance_marks.txt"

var debug_enabled := false
var seed_performance_mark_path := SEED_PERFORMANCE_MARK_PATH
var _marked_seed_names: Dictionary = {}


# 初期化
func _ready() -> void:
	load_seed_performance_marks()


# デバッグenabled設定
func set_debug_enabled(is_enabled: bool) -> void:
	if debug_enabled == is_enabled:
		return
	debug_enabled = is_enabled
	debug_enabled_changed.emit(debug_enabled)


# デバッグenabled切替
func toggle_debug_enabled() -> void:
	set_debug_enabled(not debug_enabled)


# 夢の種性能チェック切替
func toggle_seed_performance_mark(seed: SeedInfo) -> bool:
	if not debug_enabled or seed == null or seed.skill_id <= 0:
		return false
	var is_marked := not is_seed_performance_marked(seed.skill_id)
	var previous_name: Variant = _marked_seed_names.get(seed.skill_id)
	if is_marked:
		_marked_seed_names[seed.skill_id] = seed.display_name
	else:
		_marked_seed_names.erase(seed.skill_id)
	if not save_seed_performance_marks():
		if previous_name == null:
			_marked_seed_names.erase(seed.skill_id)
		else:
			_marked_seed_names[seed.skill_id] = previous_name
		return false
	seed_performance_mark_changed.emit(seed.skill_id, is_marked)
	return true


# 夢の種性能チェック取得
func is_seed_performance_marked(seed_id: int) -> bool:
	return _marked_seed_names.has(seed_id)


# 夢の種性能チェック読込
func load_seed_performance_marks() -> void:
	_marked_seed_names.clear()
	if not FileAccess.file_exists(seed_performance_mark_path):
		return
	var file := FileAccess.open(seed_performance_mark_path, FileAccess.READ)
	if file == null:
		push_error(
			"DebugState: 夢の種性能チェックを読み込めません: %s (error: %s)"
			% [seed_performance_mark_path, FileAccess.get_open_error()]
		)
		return
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var columns := line.split("\t", true, 1)
		if not columns[0].is_valid_int():
			push_warning("DebugState: 不正な夢の種IDを無視します: %s" % line)
			continue
		var seed_id := columns[0].to_int()
		if seed_id <= 0:
			push_warning("DebugState: 0以下の夢の種IDを無視します: %s" % line)
			continue
		_marked_seed_names[seed_id] = columns[1] if columns.size() > 1 else ""


# 夢の種性能チェック保存
func save_seed_performance_marks() -> bool:
	var absolute_directory := ProjectSettings.globalize_path(seed_performance_mark_path.get_base_dir())
	var directory_error := DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error(
			"DebugState: 夢の種性能チェック保存先を作成できません: %s (error: %s)"
			% [absolute_directory, directory_error]
		)
		return false
	var file := FileAccess.open(seed_performance_mark_path, FileAccess.WRITE)
	if file == null:
		push_error(
			"DebugState: 夢の種性能チェックを書き込めません: %s (error: %s)"
			% [seed_performance_mark_path, FileAccess.get_open_error()]
		)
		return false
	file.store_line("# 性能に問題がある夢の種")
	file.store_line("# seed_id\tname")
	var seed_ids: Array = _marked_seed_names.keys()
	seed_ids.sort()
	for seed_id in seed_ids:
		file.store_line("%d\t%s" % [int(seed_id), str(_marked_seed_names[seed_id])])
	return true
