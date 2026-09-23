extends SceneTree

const CATALOG_PATH := "res://data/resources/novel/novel_script_catalog.tres"
const SOURCE_DIRECTORY := "res://resource/novel"
const PROBE_PATH := "res://resource/novel/catalog_sync_lifecycle_test.txt"
const PROBE_CONTENT := "@lifecycle_sync_probe\n"

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var sync_service := root.get_node_or_null("/root/NovelScriptCatalogSync")
	_expect(sync_service != null, "Catalog sync autoload exists")
	_expect(OS.has_feature("editor"), "Catalog sync lifecycle test runs in an editor build")
	if sync_service == null or not OS.has_feature("editor"):
		quit(1)
		return

	var current_scripts: Dictionary[String, String] = {}
	var collected := bool(sync_service.call("_collect_scripts", SOURCE_DIRECTORY, current_scripts))
	var catalog := load(CATALOG_PATH) as NovelScriptCatalog
	_expect(collected, "All scenario txt files can be read")
	_expect(catalog != null and catalog.scripts == current_scripts, "Catalog matches every current scenario txt")
	if catalog == null or not collected:
		quit(1)
		return

	if FileAccess.file_exists(PROBE_PATH):
		push_error("NovelScriptCatalogSyncTest found a stale probe scenario: %s" % PROBE_PATH)
		quit(1)
		return
	if not _create_probe_file():
		quit(1)
		return
	sync_service.call("_notification", Node.NOTIFICATION_WM_CLOSE_REQUEST)
	_expect(
		_catalog_contains_probe(),
		"Close request refreshes txt content in the catalog"
	)
	_remove_probe_file()
	sync_service.call("_sync_catalog")
	catalog = load(CATALOG_PATH) as NovelScriptCatalog
	_expect(
		catalog != null and not catalog.scripts.has(PROBE_PATH),
		"Sync removes catalog entries for removed txt files"
	)

	if _create_probe_file():
		sync_service.call("_exit_tree")
		_expect(
			_catalog_contains_probe(),
			"Tree exit refreshes txt content in the catalog"
		)
		_remove_probe_file()
		sync_service.call("_sync_catalog")

	if _failures == 0:
		print("novel_script_catalog_sync_test: PASS")
	quit(_failures)


func _create_probe_file() -> bool:
	var file := FileAccess.open(PROBE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("NovelScriptCatalogSyncTest could not create its probe scenario.")
		_failures += 1
		return false
	file.store_string(PROBE_CONTENT)
	return true


func _remove_probe_file() -> void:
	var absolute_path := ProjectSettings.globalize_path(PROBE_PATH)
	var error := DirAccess.remove_absolute(absolute_path)
	if error != OK:
		push_error("NovelScriptCatalogSyncTest could not remove its probe scenario: %s" % absolute_path)
		_failures += 1


func _catalog_contains_probe() -> bool:
	var catalog := load(CATALOG_PATH) as NovelScriptCatalog
	return catalog != null and catalog.get_script_text(PROBE_PATH) == PROBE_CONTENT


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("NovelScriptCatalogSyncTest: %s" % message)
