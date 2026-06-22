class_name NightmareSkillDefinition
extends Resource

enum NightmareTag {
	PARASITE,
	COUNT,
	NATIVE,
}

@export var skill_id := 0
@export var category := ""
@export var display_name := ""
@export var texture: Texture2D
@export var max_hp := 0
@export var damage := -1
@export var size := 0
@export var stomach_size := Vector2i.ZERO
@export var stomach_shape: Array[Vector2i] = []
@export_multiline var description := ""
@export var nightmare_skill_enabled := true
@export var tags: Array[int] = []
@export var spawned_nightmares: Array[Resource] = []
@export_multiline var spawn_condition := ""


func has_tag(tag: NightmareTag) -> bool:
	return tags.has(tag)


func get_tag_texts() -> Array[String]:
	var texts: Array[String] = []
	for tag in tags:
		texts.append(get_tag_text(tag))
	return texts


static func get_tag_text(tag: int) -> String:
	match tag:
		NightmareTag.PARASITE:
			return "寄生型悪夢"
		NightmareTag.COUNT:
			return "カウント型悪夢"
		NightmareTag.NATIVE:
			return "原生型悪夢"
	return ""
