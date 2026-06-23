class_name NightmareSkillDefinition
extends Resource

@export var skill_id := 0
@export var display_name := ""
@export var texture: Texture2D
@export var max_hp := 0
@export var damage := 0
@export var size := 0
@export var stomach_size := Vector2i.ZERO
@export var stomach_shape: Array[Vector2i] = []
@export_multiline var description := ""
@export var nightmare_skill_enabled := true
