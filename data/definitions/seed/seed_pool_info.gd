class_name SeedPoolInfo
extends Resource

@export var common_skills: Array[SeedInfo] = []
@export var rare_skills: Array[SeedInfo] = []
@export var super_rare_skills: Array[SeedInfo] = []


func get_all_skills() -> Array[SeedInfo]:
	var all_skills: Array[SeedInfo] = []
	_append_skills(all_skills, common_skills)
	_append_skills(all_skills, rare_skills)
	_append_skills(all_skills, super_rare_skills)
	return all_skills


func _append_skills(
	target: Array[SeedInfo],
	source: Array[SeedInfo]
) -> void:
	for skill in source:
		if skill != null:
			target.append(skill)
