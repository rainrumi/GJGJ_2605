class_name EnemyDefinition
extends Resource

@export var display_name := ""
@export var texture: Texture2D
@export var max_hp := 0
@export var size := 0
@export var damage := 0
@export var nightmare_skill: NightmareSkillInfo
@export var nightmare_skill_enabled := true
@export var start_position := Vector2.ZERO
@export var stomach_size := Vector2i.ONE
@export var stomach_shape: Array[Vector2i] = []
