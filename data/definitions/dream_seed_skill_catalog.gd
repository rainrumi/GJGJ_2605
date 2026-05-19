class_name DreamSeedSkillCatalog
extends Resource

@export var skills: Array[DreamSeedSkillDefinition] = []


func get_skills_by_rarity(rarity: int) -> Array[DreamSeedSkillDefinition]:
	var rarity_skills: Array[DreamSeedSkillDefinition] = []
	for skill in skills:
		if skill != null and skill.rarity == rarity:
			rarity_skills.append(skill)
	return rarity_skills
