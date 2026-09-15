class_name DebugEnemyOptionButton
extends OptionButton

const MAX_FONT_SIZE := 11
const MIN_FONT_SIZE := 5
const RESERVED_WIDTH := 56.0

var _last_font_size := -1


func _ready() -> void:
	resized.connect(_update_font_size)
	item_selected.connect(_on_item_selected)
	call_deferred("_update_font_size")


func _on_item_selected(_index: int) -> void:
	call_deferred("_update_font_size")


func _update_font_size() -> void:
	if not is_inside_tree() or size.x <= 0.0:
		return
	var font := get_theme_font("font")
	if font == null:
		return

	var text := get_item_text(selected) if selected >= 0 and selected < item_count else ""
	var available_width := _get_panel_content_width() - RESERVED_WIDTH
	if available_width <= 0.0:
		available_width = size.x - RESERVED_WIDTH
	var font_size := MAX_FONT_SIZE
	while (
		font_size > MIN_FONT_SIZE
		and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x > available_width
	):
		font_size -= 1
	if font_size == _last_font_size:
		return
	_last_font_size = font_size
	add_theme_font_size_override("font_size", font_size)


func _get_panel_content_width() -> float:
	var ancestor := get_parent()
	while ancestor != null:
		if ancestor is PanelContainer:
			return (ancestor as Control).size.x - 20.0
		ancestor = ancestor.get_parent()
	return size.x
