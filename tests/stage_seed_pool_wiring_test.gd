extends SceneTree

const AREA_NAMES := [
	"corotta",
	"elmena",
	"eramia",
	"felis",
	"gonsal",
	"iriyu",
	"lunova",
	"mirune",
	"nerix",
	"riran",
	"zaika",
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for area_name in AREA_NAMES:
		var path := "res://data/resources/area/area_%s/area_%s.tres" % [
			area_name,
			area_name,
		]
		var stage := load(path) as StageInfo
		_expect(stage != null, "%sを読み込める" % path)
		if stage == null:
			continue
		_expect(stage.drop_seed_pool != null, "%sに夢の種プールが設定されている" % path)
		if stage.drop_seed_pool != null:
			_expect(
				stage.drop_seed_pool.get_all_skills().size() >= 5,
				"%sの夢の種プールに候補が設定されている" % path
			)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("StageSeedPoolWiringTest: %s" % message)
