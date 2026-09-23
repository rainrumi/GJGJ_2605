extends Node

const CATALOG_PATH := "res://data/resources/novel/novel_script_catalog.tres"
const SCENARIO_DIRECTORY := "res://resource/novel"

var _is_syncing := false


func _ready() -> void:
	if OS.has_feature("editor"):
		_sync_catalog()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and OS.has_feature("editor"):
		_sync_catalog()


func _exit_tree() -> void:
	if OS.has_feature("editor"):
		_sync_catalog()


func _sync_catalog() -> void:
	if _is_syncing:
		return
	_is_syncing = true
	var latest_scripts: Dictionary[String, String] = {}
	if not _collect_scripts(SCENARIO_DIRECTORY, latest_scripts):
		_is_syncing = false
		return
	var catalog := load(CATALOG_PATH) as NovelScriptCatalog
	if catalog == null:
		push_error("NovelScriptCatalogSync could not load catalog: %s" % CATALOG_PATH)
		_is_syncing = false
		return
	if catalog.scripts == latest_scripts:
		_is_syncing = false
		return
	var original_header := _read_catalog_header()
	catalog.scripts = latest_scripts
	var save_error := ResourceSaver.save(catalog, CATALOG_PATH)
	if save_error != OK:
		push_error(
			"NovelScriptCatalogSync could not save catalog: %s (error %d)"
			% [CATALOG_PATH, save_error]
		)
		_is_syncing = false
		return
	_restore_catalog_uid(original_header)
	print("NovelScriptCatalogSync updated %d scenarios." % latest_scripts.size())
	_is_syncing = false


func _collect_scripts(directory_path: String, scripts: Dictionary[String, String]) -> bool:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("NovelScriptCatalogSync could not open directory: %s" % directory_path)
		return false
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			if not _collect_scripts(child_path, scripts):
				directory.list_dir_end()
				return false
		elif entry.get_extension() == "txt":
			var file := FileAccess.open(child_path, FileAccess.READ)
			if file == null:
				push_error(
					"NovelScriptCatalogSync could not read scenario: %s (error %d)"
					% [child_path, FileAccess.get_open_error()]
				)
				directory.list_dir_end()
				return false
			scripts[child_path] = file.get_as_text().replace("\r\n", "\n").replace("\r", "\n")
		entry = directory.get_next()
	directory.list_dir_end()
	return true


func _read_catalog_header() -> String:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return ""
	return file.get_line()


func _restore_catalog_uid(original_header: String) -> void:
	var uid_marker := " uid=\""
	var uid_start := original_header.find(uid_marker)
	if uid_start < 0:
		return
	uid_start += uid_marker.length()
	var uid_end := original_header.find("\"", uid_start)
	if uid_end < 0:
		return
	var uid_declaration := " uid=\"%s\"" % original_header.substr(uid_start, uid_end - uid_start)
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		push_error("NovelScriptCatalogSync could not reopen catalog after saving: %s" % CATALOG_PATH)
		return
	var contents := file.get_as_text()
	var header_end := contents.find("\n")
	if header_end < 0:
		push_error("NovelScriptCatalogSync found an invalid catalog header: %s" % CATALOG_PATH)
		return
	var saved_header := contents.substr(0, header_end)
	if saved_header.contains(" uid="):
		return
	saved_header = saved_header.trim_suffix("]") + uid_declaration + "]"
	contents = saved_header + contents.substr(header_end)
	file = FileAccess.open(CATALOG_PATH, FileAccess.WRITE)
	if file == null:
		push_error(
			"NovelScriptCatalogSync could not restore catalog UID: %s (error %d)"
			% [CATALOG_PATH, FileAccess.get_open_error()]
		)
		return
	file.store_string(contents)
