class_name NovelTextInfo
extends Resource

@export_multiline var text := ""


func get_pages() -> Array[String]:
	var normalized_text := text.replace("\r\n", "\n").replace("\r", "\n")
	var pages: Array[String] = []
	for page in normalized_text.split("\n", false):
		var trimmed_page := page.strip_edges()
		if not trimmed_page.is_empty():
			pages.append(trimmed_page)
	return pages
