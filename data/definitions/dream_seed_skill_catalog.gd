class_name DreamSeedSkillCatalog
extends Resource

@export var skills: Array[DreamSeedSkillDefinition] = []


func get_skills_by_group(group: StringName) -> Array[DreamSeedSkillDefinition]:
	var grouped_skills: Array[DreamSeedSkillDefinition] = []
	for skill in skills:
		if skill != null and skill.group == group:
			grouped_skills.append(skill)
	return grouped_skills
