extends SceneTree

const NOVEL_PATH := "res://resource/novel/novel_opening.txt"
const DYNAMIC_NOVEL_PATH := "res://resource/novel/event/judge/novel_event_rara_judge_setup_001.txt"
const AUDIO_PATHS: Array[String] = [
	"res://resource/sound/bgm/Night_Dance.mp3",
	"res://resource/sound/se/se_attack.mp3",
	"res://resource/sound/se/se_click.mp3",
	"res://resource/sound/se/se_popopo.mp3",
	"res://resource/sound/se/se_select.mp3",
	"res://resource/sound/se/se_stage_clear.mp3",
]

var _failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog := load(
		"res://data/resources/novel/novel_script_catalog.tres"
	) as NovelScriptCatalog
	_expect(catalog != null, "Bundled novel script catalog loads")
	if catalog != null:
		_expect(catalog.scripts.size() >= 91, "All authored novel scripts are bundled")
		for script_path in catalog.scripts:
			_expect(script_path.ends_with(".txt"), "Bundled scenario uses .txt: %s" % script_path)
			_expect(FileAccess.file_exists(script_path), "Scenario txt is included: %s" % script_path)
			_expect(
				not FileAccess.get_file_as_string(script_path).is_empty(),
				"Scenario txt can be read: %s" % script_path,
			)
		_expect(not catalog.get_script_text(NOVEL_PATH).is_empty(), "Opening novel is bundled as a Resource")
		_expect(
			not catalog.get_script_text(DYNAMIC_NOVEL_PATH).is_empty(),
			"Dynamic novel is bundled as a Resource",
		)
	_expect(FileAccess.file_exists(NOVEL_PATH), "Novel txt is included")
	_expect(not FileAccess.get_file_as_string(NOVEL_PATH).is_empty(), "Novel txt can be read")
	_expect(FileAccess.file_exists(DYNAMIC_NOVEL_PATH), "Dynamic novel text is included")
	_expect(
		not FileAccess.get_file_as_string(DYNAMIC_NOVEL_PATH).is_empty(),
		"Dynamic novel text can be read",
	)
	for audio_path in AUDIO_PATHS:
		_expect(ResourceLoader.exists(audio_path, "AudioStream"), "Audio resource exists: %s" % audio_path)
		_expect(load(audio_path) is AudioStream, "Audio resource loads: %s" % audio_path)
	quit(_failures)


func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("PckContentTest: %s" % message)
