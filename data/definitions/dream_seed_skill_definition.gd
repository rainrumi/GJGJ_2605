class_name DreamSeedSkillDefinition
extends Resource

const GROUP_NORMAL: StringName = &"normal"
const GROUP_RARE: StringName = &"rare"

@export var skill_id := 0
@export var category := ""
@export var group: StringName = GROUP_NORMAL
@export var display_name := ""
@export var texture: Texture2D
@export var stock_count := 0
@export_multiline var main_description := ""
@export_multiline var sub_description := ""
