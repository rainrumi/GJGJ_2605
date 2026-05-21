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
}

@export var stage_id := 0
@export var stage_area: StageArea = StageArea.LUNOVA_OLD_CITY
@export var reachable_stage_areas: Array[StageArea] = []
@export var display_name := ""
@export var difficulty_level := 1
@export var level_text := ""
@export var location := ""
@export var reward_icon: Texture2D
@export var enemy_pool: Array[EnemyDefinition] = []


func get_difficulty_text() -> String:
	return "Lv.%d" % difficulty_level
