class_name NovelTextInfo
extends Resource

const SCRIPT_CATALOG: NovelScriptCatalog = preload(
	"res://data/resources/novel/novel_script_catalog.tres"
)

@export_file("*.txt") var script_path := ""
@export_multiline var text := ""


# ノベルスクリプト取得
func get_script_text() -> String:
	if not text.is_empty() or script_path.is_empty():
		return text.replace("\r\n", "\n").replace("\r", "\n")
	var bundled_text := SCRIPT_CATALOG.get_script_text(script_path)
	if not bundled_text.is_empty():
		return bundled_text
	if not FileAccess.file_exists(script_path):
		push_error(
			"NovelTextInfo could not find the scenario in the bundled catalog or source files: %s"
			% script_path
		)
		return ""
	# シナリオファイル
	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		push_error(
			"NovelTextInfo could not open the scenario text: %s (error %d)"
			% [script_path, FileAccess.get_open_error()]
		)
		return ""
	return file.get_as_text().replace("\r\n", "\n").replace("\r", "\n")
