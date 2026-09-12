class_name LaraScheduleInfo
extends Resource

const NIGHT_START := 22 * 60
const NIGHT_END := 30 * 60

# 配列の0番が1日目。定義は共有し、実行中には書き換えない。
@export var days: Array[LaraDayInfo] = []


func get_total_digestion_count(day: int, minutes: int) -> int:
	var count := 0
	for index in range(mini(day, days.size())):
		var at_minutes := NIGHT_END if index < day - 1 else normalize_minutes(minutes)
		count += days[index].get_digestion_count(at_minutes)
	return count


func get_area(day: int, minutes: int) -> StageInfo.StageArea:
	assert(day >= 1 and day <= days.size(), "LaraScheduleInfo: 対象日の予定がありません")
	return days[day - 1].get_area(normalize_minutes(minutes))


func get_visited_areas(from_day: int, from_minutes: int, to_day: int, to_minutes: int) -> Array[int]:
	assert(from_day >= 1 and to_day <= days.size(), "LaraScheduleInfo: 訪問期間の日付が予定範囲外です")
	var normalized_from := normalize_minutes(from_minutes)
	var normalized_to := normalize_minutes(to_minutes)
	if from_day > to_day or (from_day == to_day and normalized_from > normalized_to):
		return [get_area(to_day, normalized_to)]
	var areas: Array[int] = []
	for day in range(from_day, to_day + 1):
		var period_start := normalized_from if day == from_day else NIGHT_START
		var period_end := normalized_to if day == to_day else NIGHT_END
		for area in days[day - 1].get_visited_areas(period_start, period_end):
			if area not in areas:
				areas.append(area)
	return areas


static func normalize_minutes(minutes: int) -> int:
	if minutes < NIGHT_START:
		minutes += 24 * 60
	return clampi(minutes, NIGHT_START, NIGHT_END)


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if days.is_empty():
		errors.append("日別データがありません")
	for index in range(days.size()):
		var day := days[index]
		if day == null:
			errors.append("%d日目のデータがありません" % (index + 1))
			continue
		var previous_minutes := NIGHT_START
		if not StageInfo.StageArea.values().has(day.fallback_area):
			errors.append("%d日目の予定外エリアが不正です" % (index + 1))
		for digestion in day.digestions:
			if digestion == null:
				errors.append("%d日目に空の消化データがあります" % (index + 1))
				continue
			var end_minutes := digestion.get_end_minutes()
			if digestion.end_hour < 0 or digestion.end_hour > 23 \
				or digestion.end_minute < 0 or digestion.end_minute > 59 \
				or end_minutes <= previous_minutes or end_minutes > NIGHT_END:
				errors.append("%d日目の終了時刻は22時〜翌6時の昇順で指定してください" % (index + 1))
			if digestion.digestion_count < 0 or not StageInfo.StageArea.values().has(digestion.area):
				errors.append("%d日目の消化数またはエリアが不正です" % (index + 1))
			previous_minutes = end_minutes
	return errors
