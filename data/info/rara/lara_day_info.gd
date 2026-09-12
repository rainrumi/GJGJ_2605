class_name LaraDayInfo
extends Resource

const NIGHT_START := 22 * 60
const NIGHT_END := 30 * 60

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


func get_visited_areas(from_minutes: int, to_minutes: int) -> Array[int]:
	assert(from_minutes <= to_minutes, "LaraDayInfo: 訪問期間の開始時刻が終了時刻より後です")
	var areas: Array[int] = []
	var period_start := NIGHT_START
	for digestion in digestions:
		var period_end := digestion.get_end_minutes()
		if from_minutes <= period_end and to_minutes >= period_start \
				and digestion.area not in areas:
			areas.append(digestion.area)
		period_start = period_end + 1
	if from_minutes <= NIGHT_END and to_minutes >= period_start and fallback_area not in areas:
		areas.append(fallback_area)
	return areas
