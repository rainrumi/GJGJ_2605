class_name NovelScriptCatalog
extends Resource

@export var scripts: Dictionary[String, String] = {}


func get_script_text(script_path: String) -> String:
	return scripts.get(script_path, "")
