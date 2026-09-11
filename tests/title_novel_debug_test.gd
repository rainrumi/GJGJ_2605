extends Node

const EXPECTED_MINIMUM_NOVEL_COUNT := 52

var _failures := 0
var _requested_novel: NovelTextInfo


# 試験開始
func _ready() -> void:
	call_deferred("_run")


# タイトルノベルDebug試験
func _run() -> void:
	var debug_state := get_node("/root/DebugState")
	debug_state.call("set_debug_enabled", false)
	var packed := load("res://scene/main/title/title.tscn") as PackedScene
	_expect(packed != null, "タイトルSceneを読み込める")
	if packed == null:
		get_tree().quit(_failures)
		return
	var title := packed.instantiate()
	get_tree().root.add_child(title)
	await get_tree().process_frame
	title.debug_novel_requested.connect(_on_debug_novel_requested)

	var debug_button := title.get_node_or_null("DebugButton") as Button
	var novel_panel := title.get_node_or_null("NovelDebugPanel") as Control
	var novel_list := title.get_node_or_null("NovelDebugPanel/Margin/Scroll/NovelButtonList") as VBoxContainer
	_expect(debug_button != null, "タイトルにDebugボタンを構成する")
	_expect(novel_panel != null, "タイトルにノベル一覧パネルを構成する")
	_expect(novel_list != null, "ノベルボタン一覧を構成する")
	if debug_button != null and novel_panel != null and novel_list != null:
		_expect(not novel_panel.visible, "Debug無効時はノベル一覧を隠す")
		debug_button.pressed.emit()
		_expect(bool(debug_state.get("debug_enabled")), "タイトルのDebugボタンで共通状態を有効化する")
		_expect(novel_panel.visible, "Debug有効時はノベル一覧を表示する")
		_expect(
			novel_list.get_child_count() >= EXPECTED_MINIMUM_NOVEL_COUNT,
			"全ノベルのボタンを生成する"
		)
		var debug_separator := novel_list.get_node_or_null("DebugSeparator") as Label
		_expect(debug_separator != null, "ノベル一覧にDebug区切りを構成する")
		if debug_separator != null:
			_expect(debug_separator.text == "Debug", "ノベル一覧の区切りにDebugと表示する")
			_expect(debug_separator.get_index() > 0, "通常ノベルの後にDebug区切りを配置する")
			_expect(debug_separator.get_index() < novel_list.get_child_count() - 1, "Debug区切りの後に専用ノベルを配置する")
		if novel_list.get_child_count() > 0:
			var first_button := novel_list.get_child(0) as Button
			_expect(first_button.get_theme_font_size("font_size") == 8, "ノベル一覧を既定の50%の文字サイズにする")
			first_button.pressed.emit()
			_expect(_requested_novel != null, "ノベルボタンが再生対象を通知する")
			_expect(
				_requested_novel != null and FileAccess.file_exists(_requested_novel.script_path),
				"通知したノベルのシナリオファイルが存在する"
			)
		debug_button.pressed.emit()
		_expect(not bool(debug_state.get("debug_enabled")), "タイトルのDebugボタンで共通状態を無効化する")
		_expect(not novel_panel.visible, "Debug無効化時はノベル一覧を隠す")

	get_tree().root.remove_child(title)
	title.free()
	await get_tree().process_frame
	get_tree().quit(_failures)


# デバッグノベル要求
func _on_debug_novel_requested(novel_text: NovelTextInfo) -> void:
	_requested_novel = novel_text


# 期待値確認
func _expect(condition: bool, message: String) -> void:
	if condition:
		return
	_failures += 1
	push_error("TitleNovelDebugTest: %s" % message)
