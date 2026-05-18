class_name StageDefinition
extends Resource

@export var stage_id := 0
@export var display_name := ""
@export var difficulty_level := 1
@export var level_text := ""
@export var location := ""
@export var reward_icon: Texture2D
@export var is_rare := false
@export var tags: Array[StringName] = []
@export var enemy_pool: Array[EnemyDefinition] = []
@export var stomach_columns := 4
@export var stomach_rows := 5


func get_difficulty_text() -> String:
	return "Lv.%d" % difficulty_level


func get_tag_text() -> String:
	var tag_texts: Array[String] = []
	if is_rare:
		tag_texts.append("レア")
	for tag in tags:
		if not String(tag).is_empty():
			tag_texts.append(String(tag))
	if tag_texts.is_empty():
		return "通常"
	return " / ".join(tag_texts)
