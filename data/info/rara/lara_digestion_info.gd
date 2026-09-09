class_name LaraDigestionInfo
extends Resource

@export_range(0, 23) var end_hour: int = 3
@export_range(0, 59) var end_minute: int = 0
@export var area: StageInfo.StageArea = StageInfo.StageArea.ERAMIA_DISTRICT
@export_range(0, 100) var digestion_count: int = 1


func get_end_minutes() -> int:
	var minutes := end_hour * 60 + end_minute
	return minutes + 24 * 60 if end_hour < 22 else minutes
