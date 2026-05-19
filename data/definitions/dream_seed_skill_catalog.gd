class_name DreamSeedSkillCatalog
extends Resource

@export var normal_skills: Array[DreamSeedSkillDefinition] = []
@export var rare_skills: Array[DreamSeedSkillDefinition] = []


func get_skills_by_rarity(rarity: int, skill_id: int) -> Array[DreamSeedSkillDefinition]:
	var rarity_skills := _get_skill_list_by_rarity(rarity)
	var matched_skills: Array[DreamSeedSkillDefinition] = []
	for skill in rarity_skills:
		if skill != null and skill.skill_id == skill_id:
			matched_skills.append(skill)
	return matched_skills


func _get_skill_list_by_rarity(rarity: int) -> Array[DreamSeedSkillDefinition]:
	match rarity:
		DreamSeedSkillDefinition.Rarity.NORMAL:
			return normal_skills
		DreamSeedSkillDefinition.Rarity.RARE:
			return rare_skills
	return []
