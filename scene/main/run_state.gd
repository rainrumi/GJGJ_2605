class_name RunState
extends Resource

const DEFAULT_STOMACH_COLUMNS := 4
const DEFAULT_STOMACH_ROWS := 5

var current_day := 1
var current_hp := 100
var max_hp := 100
var stomach_columns := DEFAULT_STOMACH_COLUMNS
var stomach_rows := DEFAULT_STOMACH_ROWS
var selected_stage_id := 0
var selected_stage: StageDefinition
var planted_flowers: Array[FlowerDefinition] = []
var last_time_over_recovery_percent := 0


func reset() -> void:
	current_day = 1
	current_hp = max_hp
	stomach_columns = DEFAULT_STOMACH_COLUMNS
	stomach_rows = DEFAULT_STOMACH_ROWS
	selected_stage_id = 0
	selected_stage = null
	planted_flowers.clear()
	last_time_over_recovery_percent = 0
