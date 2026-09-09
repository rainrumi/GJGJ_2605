class_name LaraDayInfo
extends Resource

@export var digestions: Array[LaraDigestionInfo] = []
# 最後の終了時刻の翌分から朝6時まで（予定が空なら一晩中）の滞在先。
@export var fallback_area: StageInfo.StageArea = StageInfo.StageArea.ERAMIA_DISTRICT


func get_digestion_count(minutes: int) -> int:
	var count := 0
	for digestion in digestions:
		if digestion.get_end_minutes() <= minutes:
			count += digestion.digestion_count
	return count


func get_area(minutes: int) -> StageInfo.StageArea:
	for digestion in digestions:
		if minutes <= digestion.get_end_minutes():
			return digestion.area
	return fallback_area
