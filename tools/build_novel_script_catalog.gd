extends SceneTree

const SOURCE_DIRECTORY := "res://resource/novel"
const OUTPUT_PATH := "res://data/resources/novel/novel_script_catalog.tres"

var _failures := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	var scripts: Dictionary[String, String] = {}
	_collect_scripts(SOURCE_DIRECTORY, scripts)
	if _failures > 0:
		quit(_failures)
		return
	var catalog := NovelScriptCatalog.new()
	catalog.scripts = scripts
	var error := ResourceSaver.save(catalog, OUTPUT_PATH)
	if error != OK:
		push_error("Could not save novel script catalog: %s (error %d)" % [OUTPUT_PATH, error])
		quit(1)
		return
	print("Novel script catalog contains %d scripts." % scripts.size())
	quit()


func _collect_scripts(directory_path: String, scripts: Dictionary[String, String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		_failures += 1
		push_error("Could not open novel source directory: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var child_path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_scripts(child_path, scripts)
		elif entry.get_extension() == "txt":
			var source_text := FileAccess.get_file_as_string(child_path)
			if source_text.is_empty():
				_failures += 1
				push_error("Novel source is empty or unreadable: %s" % child_path)
			else:
				scripts[child_path] = source_text.replace("\r\n", "\n").replace("\r", "\n")
		elif entry.get_extension().is_empty():
			_failures += 1
			push_error("Novel scenario must use the .txt extension: %s" % child_path)
		entry = directory.get_next()
	directory.list_dir_end()
