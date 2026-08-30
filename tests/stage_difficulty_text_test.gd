extends SceneTree

var _failures := 0


func _initialize() -> void:
	var stage := StageInfo.new()
	stage.difficulty_level = 2
	_expect(stage.get_difficulty_text() == "★★", "Lv.2を星2個で表示する")

	stage.is_high_difficulty = true
	_expect(stage.get_difficulty_text() == "★★+α", "Lv.2+αを星2個と+αで表示する")

	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageDifficultyTextTest: %s" % message)
