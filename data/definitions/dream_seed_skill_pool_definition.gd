class_name DreamSeedSkillPoolDefinition
extends Resource

@export var common_skills: Array[DreamSeedSkillDefinition] = []
@export var rare_skills: Array[DreamSeedSkillDefinition] = []
@export var super_rare_skills: Array[DreamSeedSkillDefinition] = []


func get_all_skills() -> Array[DreamSeedSkillDefinition]:
	var all_skills: Array[DreamSeedSkillDefinition] = []
	_append_skills(all_skills, common_skills)
	_append_skills(all_skills, rare_skills)
	_append_skills(all_skills, super_rare_skills)
	return all_skills


func _append_skills(
	target: Array[DreamSeedSkillDefinition],
	source: Array[DreamSeedSkillDefinition]
) -> void:
	for skill in source:
		if skill != null:
			target.append(skill)
