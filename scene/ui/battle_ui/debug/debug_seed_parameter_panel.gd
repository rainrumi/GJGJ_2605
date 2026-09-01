class_name DebugSeedParameterPanel
extends PanelContainer

signal seed_parameter_applied(original_seed: SeedInfo, edited_seed: SeedInfo)

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
	var visited: Dictionary = {}
	_append_resource_parameters(_edited_seed.main_skill, "Main", visited)
	_append_resource_parameters(_edited_seed.sub_skill, "Sub", visited)
	_append_resource_parameters(_edited_seed.acid_block, "Block", visited)
	empty_label.visible = _bindings.is_empty()
	apply_button.disabled = _bindings.is_empty()


func _append_resource_parameters(resource: Resource, path: String, visited: Dictionary) -> void:
	if resource == null or visited.has(resource):
		return
	visited[resource] = true
	var resource_name: String = resource.get_script().get_global_name() if resource.get_script() != null else resource.get_class()
	for property in resource.get_property_list():
		if (
			not (int(property.usage) & PROPERTY_USAGE_EDITOR)
			or not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE)
		):
			continue
		var property_name := StringName(property.name)
		var value: Variant = resource.get(property_name)
		if value is Resource:
			_append_resource_parameters(value as Resource, "%s/%s" % [path, property_name], visited)
		elif value is Array:
			for index in range(value.size()):
				if value[index] is Resource:
					_append_resource_parameters(value[index] as Resource, "%s/%s[%d]" % [path, property_name, index], visited)
		elif property.type in [TYPE_BOOL, TYPE_INT, TYPE_FLOAT]:
			_add_parameter_row(resource, property_name, value, "%s %s.%s" % [path, resource_name, property_name])


func _add_parameter_row(resource: Resource, property_name: StringName, value: Variant, label_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var editor: Control
	if value is bool:
		var check_box := CheckBox.new()
		check_box.button_pressed = value
		editor = check_box
	else:
		var spin_box := SpinBox.new()
		spin_box.min_value = -9999.0
		spin_box.max_value = 9999.0
		spin_box.step = 1.0 if value is int else 0.01
		spin_box.value = float(value)
		spin_box.custom_arrow_step = 1.0 if value is int else 0.01
		spin_box.set_meta("integer_value", value is int)
		editor = spin_box
	editor.custom_minimum_size.x = 100.0
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
