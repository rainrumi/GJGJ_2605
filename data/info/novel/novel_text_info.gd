class_name NovelTextInfo
extends Resource

@export_multiline var text := ""


# ページ取得
func get_pages() -> Array[String]:
	# normalized文言
	var normalized_text := text.replace("\r\n", "\n").replace("\r", "\n")
	# ページ
	var pages: Array[String] = []
	for page in normalized_text.split("\n", false):
		# trimmedページ
		var trimmed_page := page.strip_edges()
		if not trimmed_page.is_empty():
			pages.append(trimmed_page)
	return pages
