# 0625OK
class_name TooltipPositioner
extends RefCounted

const SCREEN_PADDING := 4.0


static func get_tooltip_position(
	anchor_global_position: Vector2,
	tooltip_size: Vector2,
	viewport_rect: Rect2,
	offset: Vector2
) -> Vector2:
	var position := anchor_global_position + offset
	var min_position := viewport_rect.position + Vector2(SCREEN_PADDING, SCREEN_PADDING)
	var max_position := viewport_rect.end - tooltip_size - Vector2(SCREEN_PADDING, SCREEN_PADDING)
	max_position.x = maxf(min_position.x, max_position.x)
	max_position.y = maxf(min_position.y, max_position.y)
	if position.x + tooltip_size.x > viewport_rect.end.x - SCREEN_PADDING:
		position.x = anchor_global_position.x - tooltip_size.x - absf(offset.x)
	if position.x < viewport_rect.position.x + SCREEN_PADDING:
		position.x = anchor_global_position.x + absf(offset.x)
	if position.y + tooltip_size.y > viewport_rect.end.y - SCREEN_PADDING:
		position.y = anchor_global_position.y - tooltip_size.y - absf(offset.y)
	if position.y < viewport_rect.position.y + SCREEN_PADDING:
		position.y = anchor_global_position.y + absf(offset.y)
	position.x = clampf(position.x, min_position.x, max_position.x)
	position.y = clampf(position.y, min_position.y, max_position.y)
	return position
