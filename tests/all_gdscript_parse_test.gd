extends SceneTree

var _failures := 0 # 失敗数
var _loaded_count := 0 # 読込数


# 試験開始
func _initialize() -> void:
	call_deferred("_run")


# 全Script読込試験
func _run() -> void:
	_load_scripts("res://")
	if _loaded_count == 0:
		_failures += 1
		push_error("AllGdscriptParseTest: GDScriptが見つからない")
	quit(_failures)


# Script再帰読込
func _load_scripts(path: String) -> void:
	var directory := DirAccess.open(path) # 対象フォルダ
	if directory == null:
		_failures += 1
		push_error("AllGdscriptParseTest: フォルダを開けない %s" % path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next() # 対象項目
	while not entry.is_empty():
		if entry != ".godot":
			var child_path := path.path_join(entry) # 子項目パス
			if directory.current_is_dir():
				_load_scripts(child_path)
			elif entry.ends_with(".gd"):
				var script := load(child_path) as Script # 対象Script
				_loaded_count += 1
				if script == null:
					_failures += 1
					push_error("AllGdscriptParseTest: 読込失敗 %s" % child_path)
		entry = directory.get_next()
	directory.list_dir_end()
