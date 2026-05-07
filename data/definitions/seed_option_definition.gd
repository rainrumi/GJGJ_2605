class_name SeedOptionDefinition
extends Resource

@export var display_name := ""
@export var rarity: StringName = &"normal"
@export_multiline var effect_text := ""
@export var effect_font_size := 21
@export var seed_texture: Texture2D
@export var frame_texture: Texture2D
@export var flower_definition: FlowerDefinition
