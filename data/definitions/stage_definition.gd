class_name StageDefinition
extends Resource

enum StageArea {
	LUNOVA_OLD_CITY = 1,
	ERAMIA_DISTRICT = 2,
	ELMENA_UNIVERSITY = 3,
	GONSAL_DISTRICT = 4,
	RIRAN_TREE_GARRISON = 5,
	FELIS_GARDEN_DISTRICT = 6,
	NERIX_MAGIC_SCHOOL = 7,
	ZAIKA_ADMIN_DISTRICT = 8,
	MIRUNE_STREET = 9,
	COROTTA_STREET = 10,
	IRIYU_CAVE = 11,
	huwahuwaSchool = 12,
}

@export var stage_id := 0
@export var stage_area: StageArea = StageArea.LUNOVA_OLD_CITY
@export var reachable_stage_areas: Array[StageArea] = []
@export var display_name := ""
@export var difficulty_level := 1
@export var level_text := ""
@export var location := ""
@export var map_position := Vector2.ZERO
@export var reward_icon: Texture2D
@export var enemy_data: StageEnemySetDefinition
@export var drop_seed_skill_pool: DreamSeedSkillPoolDefinition
@export var stage_unlock_novel_texts: Array[NovelTextResource] = []
@export var high_difficulty_stages: Array[StageDefinition] = []
@export var is_high_difficulty := false
@export var has_normal_stage := true


func get_difficulty_text() -> String:
	if is_high_difficulty:
		return "Lv.%d+α" % difficulty_level
	return "Lv.%d" % difficulty_level


func create_high_difficulty_fallback() -> StageDefinition:
	var stage := duplicate(true) as StageDefinition
	stage.is_high_difficulty = true
	stage.high_difficulty_stages = []
	stage.difficulty_level = difficulty_level + 1
	return stage
