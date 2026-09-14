class_name EffectFieldSettingsPanel
extends PanelContainer

signal closed

const ENEMY_DIRECTORY := "res://data/resources/area"
const SEED_DIRECTORY := "res://data/resources/seeds/skills"

@onready var close_button: Button = $Margin/Layout/Top/CloseButton
@onready var amount_tab: VBoxContainer = $Margin/Layout/Tabs/Amount
@onready var probability_tab: VBoxContainer = $Margin/Layout/Tabs/Probability

var _catalog: Array[Dictionary] = []
var _resources: Dictionary = {}
var _drafts: Array[Dictionary] = [{}, {}]


func _ready() -> void:
	close_button.pressed.connect(_close)
	($Margin/Layout/Tabs as TabContainer).set_tab_title(0, "効果量")
	($Margin/Layout/Tabs as TabContainer).set_tab_title(1, "確率")
	for tab_index in range(2):
		var tab := _tab(tab_index)
		(tab.get_node("Picker/Search") as LineEdit).text_changed.connect(_on_search_changed.bind(tab_index))
		(tab.get_node("Bottom/Save") as Button).pressed.connect(_save_tab.bind(tab_index))


func open() -> void:
	visible = true
	if _catalog.is_empty():
		_load_catalog()
	for tab_index in range(2):
		_render_rows(tab_index)
	(amount_tab.get_node("Picker/Search") as LineEdit).grab_focus()


func _close() -> void:
	visible = false
	closed.emit()


func _tab(index: int) -> VBoxContainer:
	return amount_tab if index == 0 else probability_tab


func _load_catalog() -> void:
	var paths: Array[String] = []
	_collect_paths(ENEMY_DIRECTORY, paths)
	_collect_paths(SEED_DIRECTORY, paths)
	paths.sort()
	for path in paths:
		if path.begins_with(ENEMY_DIRECTORY) and (not path.contains("/enemy/") or path.get_file().contains("_preset_")):
			continue
		var definition := ResourceLoader.load(path) as Resource
		if definition is not EnemyInfo and definition is not SeedInfo:
			continue
		if _effects_for(definition).is_empty():
			continue
		_resources[path] = definition
		var is_enemy := definition is EnemyInfo
		var area := path.trim_prefix(ENEMY_DIRECTORY + "/").get_slice("/", 0)
		var label := "悪夢 %s %s (%s)" % [definition.skill_id, definition.display_name, area] if is_enemy else "夢の種 %s %s" % [definition.skill_id, definition.display_name]
		_catalog.append({
			"path": path,
			"kind": 1 if is_enemy else 0,
			"label": label,
			"search": "%s %s" % [label, path],
		})
	_catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if a.kind != b.kind:
			return a.kind < b.kind
		return a.label < b.label
	)


func _collect_paths(directory_path: String, paths: Array[String]) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_error("効果変数設定: フォルダを開けません: %s" % directory_path)
		return
	directory.list_dir_begin()
	var entry := directory.get_next()
	while not entry.is_empty():
		var path := directory_path.path_join(entry)
		if directory.current_is_dir():
			_collect_paths(path, paths)
		elif entry.ends_with(".tres"):
			paths.append(path)
		entry = directory.get_next()
	directory.list_dir_end()


func _effects_for(definition: Resource) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var slots: Array[String] = ["main_skill"]
	if definition is SeedInfo:
		slots.append("sub_skill")
	for slot in slots:
		var skill := definition.get(slot) as Resource
		if skill == null:
			continue
		var effects: Array = skill.get("effects")
		for index in range(effects.size()):
			if effects[index] is EnemyEffect or effects[index] is SeedEffect:
				entries.append({"slot": slot, "index": index, "effect": effects[index]})
	return entries


func _on_search_changed(_value: String, tab_index: int) -> void:
	_render_rows(tab_index)


func _draft_key(path: String, slot: String, index: int, field: String) -> String:
	return "%s|%s|%s|%s" % [path, slot, index, field]


func _render_rows(tab_index: int) -> void:
	var tab := _tab(tab_index)
	var rows := tab.get_node("Scroll/Rows") as VBoxContainer
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var query := (tab.get_node("Picker/Search") as LineEdit).text.strip_edges().to_lower()
	var count := 0
	for item in _catalog:
		if not query.is_empty() and not String(item.search).to_lower().contains(query):
			continue
		_render_definition(rows, item, tab_index)
		count += 1
	if count == 0:
		_set_status(tab_index, "該当する項目がありません")
		return
	_set_status(tab_index, "%s 件表示・%s 件の未保存選択" % [count, _drafts[tab_index].size()])


func _render_definition(rows: VBoxContainer, item: Dictionary, tab_index: int) -> void:
	var path := String(item.path)
	var definition := _resources[path] as Resource
	if rows.get_child_count() > 0:
		rows.add_child(HSeparator.new())
	var title := Label.new()
	title.text = String(item.label)
	title.add_theme_font_size_override("font_size", 12)
	rows.add_child(title)
	if definition is SeedInfo:
		_add_description(rows, "メイン: " + SeedDescription.get_main_description(definition))
		_add_description(rows, "サブ: " + SeedDescription.get_sub_description(definition))
	else:
		_add_description(rows, "効果: " + String(definition.description).strip_edges())
	for entry in _effects_for(definition):
		var effect := entry.effect as Resource
		var fields := EffectFieldValues.numeric_fields(effect)
		if fields.is_empty():
			continue
		var heading := Label.new()
		heading.text = "%s / %s" % ["主効果" if entry.slot == "main_skill" else "副効果", effect.get_script().get_global_name()]
		heading.clip_text = true
		heading.tooltip_text = heading.text
		rows.add_child(heading)
		for field in fields:
			_add_field_row(rows, path, entry.slot, entry.index, effect, field, tab_index)


func _add_description(rows: VBoxContainer, value: String) -> void:
	var description := Label.new()
	description.text = value
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_font_size_override("font_size", 10)
	rows.add_child(description)


func _add_field_row(rows: VBoxContainer, path: String, slot: String, index: int, effect: Resource, field: String, tab_index: int) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 32)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_child(row)
	var value_label := Label.new()
	value_label.text = "%s = %s" % [field, str(effect.get(field))]
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.clip_text = true
	value_label.tooltip_text = value_label.text
	row.add_child(value_label)
	var group := ButtonGroup.new()
	var target := CheckBox.new()
	target.text = "対象"
	target.custom_minimum_size = Vector2(80, 30)
	target.mouse_filter = Control.MOUSE_FILTER_STOP
	target.button_group = group
	row.add_child(target)
	var excluded := CheckBox.new()
	excluded.text = "対象外"
	excluded.custom_minimum_size = Vector2(92, 30)
	excluded.mouse_filter = Control.MOUSE_FILTER_STOP
	excluded.button_group = group
	row.add_child(excluded)
	var key := _draft_key(path, slot, index, field)
	var stored_fields: PackedStringArray = effect.effect_amount_fields if tab_index == 0 else effect.probability_fields
	var selected := bool(_drafts[tab_index][key].selected) if _drafts[tab_index].has(key) else stored_fields.has(field)
	target.set_pressed_no_signal(selected)
	excluded.set_pressed_no_signal(not selected)
	target.toggled.connect(_on_field_toggled.bind(path, slot, index, field, tab_index))


func _on_field_toggled(pressed: bool, path: String, slot: String, index: int, field: String, tab_index: int) -> void:
	var key := _draft_key(path, slot, index, field)
	_drafts[tab_index][key] = {"path": path, "slot": slot, "index": index, "field": field, "selected": pressed}
	_set_status(tab_index, "%s 件の未保存選択" % _drafts[tab_index].size())


func _save_tab(tab_index: int) -> void:
	if _drafts[tab_index].is_empty():
		_set_status(tab_index, "変更はありません")
		return
	var affected_paths: Dictionary = {}
	var original_values: Dictionary = {}
	for choice in _drafts[tab_index].values():
		var path := String(choice.path)
		var definition := _resources.get(path) as Resource
		if definition == null:
			continue
		var skill := definition.get(choice.slot) as Resource
		if skill == null:
			continue
		var effects: Array = skill.get("effects")
		var effect := effects[int(choice.index)] as Resource
		if effect == null or not EffectFieldValues.numeric_fields(effect).has(choice.field):
			continue
		if not original_values.has(path):
			original_values[path] = {}
		if not original_values[path].has(effect):
			original_values[path][effect] = {
				"fields": (effect.effect_amount_fields if tab_index == 0 else effect.probability_fields).duplicate(),
				"configured": effect.effect_amount_configured if tab_index == 0 else effect.probability_configured,
			}
		var fields: PackedStringArray = effect.effect_amount_fields if tab_index == 0 else effect.probability_fields
		fields = fields.duplicate()
		if choice.selected and not fields.has(choice.field):
			fields.append(choice.field)
		elif not choice.selected:
			fields.erase(choice.field)
		if tab_index == 0:
			effect.effect_amount_fields = fields
			effect.effect_amount_configured = true
		else:
			effect.probability_fields = fields
			effect.probability_configured = true
		affected_paths[path] = true
	var failed: Array[String] = []
	for path in affected_paths:
		var error := ResourceSaver.save(_resources[path], path)
		if error != OK:
			failed.append("%s: %s" % [path, error_string(error)])
			for effect in original_values[path]:
				var previous: Dictionary = original_values[path][effect]
				if tab_index == 0:
					effect.effect_amount_fields = previous.fields
					effect.effect_amount_configured = previous.configured
				else:
					effect.probability_fields = previous.fields
					effect.probability_configured = previous.configured
	if not failed.is_empty():
		_set_status(tab_index, "保存失敗: " + ", ".join(failed))
		push_error("効果変数設定: " + ", ".join(failed))
		return
	_drafts[tab_index].clear()
	_set_status(tab_index, "%s 件の定義を保存しました" % affected_paths.size())


func _set_status(tab_index: int, message: String) -> void:
	(_tab(tab_index).get_node("Bottom/Status") as Label).text = message
