class_name DreamSeedSkillDefinition
extends Resource

enum Rarity {
	NORMAL,
	RARE,
}

@export var skill_id := 0
@export var category := ""
@export var rarity: Rarity = Rarity.NORMAL
@export var display_name := ""
@export var texture: Texture2D
@export var drag_texture: Texture2D
@export var drag_enabled := true
@export var drag_block_definition: DreamSeedDragBlockDefinition
@export var stock_count := 0
@export_multiline var main_description := ""
@export_multiline var sub_description := ""
