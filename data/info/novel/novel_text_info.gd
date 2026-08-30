class_name NovelTextInfo
extends Resource

@export_file("*.txt") var script_path := ""
@export_multiline var text := ""


# ノベルスクリプト取得
func get_script_text() -> String:
	if script_path.is_empty():
		return text.replace("\r\n", "\n").replace("\r", "\n")
	if not FileAccess.file_exists(script_path):
		push_error("NovelTextInfo could not find the scenario text: %s" % script_path)
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
