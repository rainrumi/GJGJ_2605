class_name PassiveSeedTextureList
extends HFlowContainer

const ICON_SIZE := Vector2(30.0, 30.0)

@export var icon_color := Color("#f0e0ff")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


# 入力やツールチップを持たないテクスチャだけを表示する
func set_seed_sources(sources: Array) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for source in sources:
		if not source is SeedInfo:
			continue
		var seed := source as SeedInfo
		var icon := TextureRect.new()
		icon.custom_minimum_size = ICON_SIZE
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = seed.get_small_texture()
		icon.self_modulate = icon_color
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(icon)
