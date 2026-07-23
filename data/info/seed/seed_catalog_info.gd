class_name SeedCatalogInfo
extends Resource

@export var normal_skills: Array[SeedInfo] = []
@export var rare_skills: Array[SeedInfo] = []
@export var epic_skills: Array[SeedInfo] = []


# skillsbyrarity取得
func get_skills_by_rarity(rarity: int, skill_id: int) -> Array[SeedInfo]:
	# rarityskills
	var rarity_skills := _get_skill_list_by_rarity(rarity)
	# matchedskills
	var matched_skills: Array[SeedInfo] = []
	for skill in rarity_skills:
		if skill != null and skill.skill_id == skill_id:
			matched_skills.append(skill)
	return matched_skills


# スキルlistbyrarity取得
func _get_skill_list_by_rarity(rarity: int) -> Array[SeedInfo]:
	match rarity:
		SeedInfo.Rarity.NORMAL:
			return normal_skills
		SeedInfo.Rarity.RARE:
			return rare_skills
		SeedInfo.Rarity.EPIC:
			return epic_skills
	return []
