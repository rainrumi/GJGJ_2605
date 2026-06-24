class_name DreamSeedSkillCatalog
extends Resource

@export var normal_skills: Array[SeedInfo] = []
@export var rare_skills: Array[SeedInfo] = []


func get_skills_by_rarity(rarity: int, skill_id: int) -> Array[SeedInfo]:
	var rarity_skills := _get_skill_list_by_rarity(rarity)
	var matched_skills: Array[SeedInfo] = []
	for skill in rarity_skills:
		if skill != null and skill.skill_id == skill_id:
			matched_skills.append(skill)
	return matched_skills


func _get_skill_list_by_rarity(rarity: int) -> Array[SeedInfo]:
	match rarity:
		SeedInfo.Rarity.NORMAL:
			return normal_skills
		SeedInfo.Rarity.RARE:
			return rare_skills
	return []
