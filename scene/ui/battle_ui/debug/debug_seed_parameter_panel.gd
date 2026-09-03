class_name DebugSeedParameterPanel
extends PanelContainer

signal seed_parameter_applied(original_seed: SeedInfo, edited_seed: SeedInfo)

const EXCLUDED_EFFECT_PROPERTIES: Array[StringName] = [&"priority", &"enabled"]

@onready var seed_option: OptionButton = %SeedOption
@onready var parameter_list: VBoxContainer = %ParameterList
@onready var empty_label: Label = %EmptyLabel
@onready var status_label: Label = %StatusLabel
@onready var apply_button: Button = %ApplyButton
@onready var close_button: Button = %CloseButton

var _seeds: Array[SeedInfo] = []
var _original_seed: SeedInfo
var _edited_seed: SeedInfo
var _bindings: Array[Dictionary] = []


func _ready() -> void:
	seed_option.item_selected.connect(_on_seed_selected)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(close)
	visible = false


func set_seed_inventory(equipped_seeds: Array, stored_seeds: Array) -> void:
	_seeds.clear()
	for source in equipped_seeds + stored_seeds:
		if source is SeedInfo and not _seeds.has(source):
			_seeds.append(source as SeedInfo)
	_rebuild_seed_options()


func open_panel() -> void:
	if not DebugState.debug_enabled:
		return
	visible = true
	status_label.text = ""
	_rebuild_editor()


func close() -> void:
	visible = false


func _rebuild_seed_options() -> void:
	var previous_seed := _original_seed
	seed_option.clear()
	for seed in _seeds:
		seed_option.add_item("%d: %s" % [seed.skill_id, seed.display_name])
	var selected_index := _seeds.find(previous_seed)
	if selected_index < 0 and not _seeds.is_empty():
		selected_index = 0
	seed_option.select(selected_index)
	_original_seed = _seeds[selected_index] if selected_index >= 0 else null
	if visible:
		_rebuild_editor()


func _rebuild_editor() -> void:
	for child in parameter_list.get_children():
		child.queue_free()
	_bindings.clear()
	_edited_seed = _original_seed.duplicate(true) as SeedInfo if _original_seed != null else null
	empty_label.visible = _edited_seed == null
	apply_button.disabled = _edited_seed == null
	if _edited_seed == null:
		return
	_add_parameter_row(
		_edited_seed,
		&"main_description",
		_edited_seed.main_description,
		"main_description"
	)
	_add_parameter_row(
		_edited_seed,
		&"sub_description",
		_edited_seed.sub_description,
		"sub_description"
	)
	if _edited_seed.acid_block != null:
		_add_parameter_row(_edited_seed.acid_block, &"max_hp", _edited_seed.acid_block.max_hp, "max_hp")
		_add_parameter_row(_edited_seed.acid_block, &"damage", _edited_seed.acid_block.damage, "damage")
	_append_skill_parameters(_edited_seed.main_skill, "Main")
	_append_skill_parameters(_edited_seed.sub_skill, "Sub")
	empty_label.visible = _bindings.is_empty()
	apply_button.disabled = _bindings.is_empty()


func _append_skill_parameters(skill: SeedSkill, heading_prefix: String) -> void:
	if skill == null:
		return
	for index in range(skill.effects.size()):
		_append_effect_parameters(skill.effects[index], heading_prefix, index)


func _append_effect_parameters(effect: SeedEffect, heading_prefix: String, index: int) -> void:
	if effect == null:
		return
	var effect_name: String = effect.get_script().get_global_name() if effect.get_script() != null else effect.get_class()
	var heading := Label.new()
	heading.text = "%s E%d: %s" % [heading_prefix, index + 1, effect_name]
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	heading.tooltip_text = effect_name
	heading.add_theme_font_size_override("font_size", 9)
	parameter_list.add_child(heading)
	for property in effect.get_property_list():
		if (
			not (int(property.usage) & PROPERTY_USAGE_EDITOR)
			or not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE)
		):
			continue
		var property_name := StringName(property.name)
		if property_name in EXCLUDED_EFFECT_PROPERTIES:
			continue
		if property.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
			_add_parameter_row(effect, property_name, effect.get(property_name), String(property_name))


func _add_parameter_row(resource: Resource, property_name: StringName, value: Variant, label_text: String) -> void:
	var is_multiline := value is String
	var row: Container = VBoxContainer.new() if is_multiline else HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 10)
	if not is_multiline:
		label.custom_minimum_size.x = 168.0
	row.add_child(label)
	var editor: Control
	if value is bool:
		var check_box := CheckBox.new()
		check_box.button_pressed = value
		editor = check_box
	elif value is String:
		var text_edit := TextEdit.new()
		text_edit.text = value
		text_edit.custom_minimum_size.y = 72.0
		text_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
		editor = text_edit
	else:
		var spin_box := SpinBox.new()
		spin_box.min_value = -9999.0
		spin_box.max_value = 9999.0
		spin_box.step = 1.0 if value is int else 0.01
		spin_box.value = float(value)
		spin_box.custom_arrow_step = 1.0 if value is int else 0.01
		spin_box.set_meta("integer_value", value is int)
		editor = spin_box
	editor.custom_minimum_size.x = 96.0
	editor.add_theme_font_size_override("font_size", 11)
	if not is_multiline:
		editor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(editor)
	parameter_list.add_child(row)
	_bindings.append({"resource": resource, "property": property_name, "editor": editor})


func _on_seed_selected(index: int) -> void:
	status_label.text = ""
	_original_seed = _seeds[index] if index >= 0 and index < _seeds.size() else null
	_rebuild_editor()


func _on_apply_pressed() -> void:
	if not DebugState.debug_enabled or _original_seed == null or _edited_seed == null:
		return
	for binding in _bindings:
		var editor := binding.editor as Control
		var value: Variant
		if editor is CheckBox:
			value = (editor as CheckBox).button_pressed
		elif editor is TextEdit:
			value = (editor as TextEdit).text
		else:
			var spin_box := editor as SpinBox
			value = int(spin_box.value) if spin_box.get_meta("integer_value") else spin_box.value
		(binding.resource as Resource).set(binding.property, value)
	var save_path := _original_seed.resource_path
	if save_path.is_empty():
		status_label.text = "保存先のない種です"
		return
	var save_error := ResourceSaver.save(_edited_seed, save_path)
	if save_error != OK:
		status_label.text = "保存に失敗しました: %s" % error_string(save_error)
		push_error("DebugSeedParameterPanel: 夢の種を保存できません: %s (error: %s)" % [save_path, save_error])
		return
	seed_parameter_applied.emit(_original_seed, _edited_seed)
	_original_seed = _edited_seed
	status_label.text = "保存しました: %s" % save_path
