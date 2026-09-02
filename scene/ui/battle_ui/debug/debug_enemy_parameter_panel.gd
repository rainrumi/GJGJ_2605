class_name DebugEnemyParameterPanel
extends PanelContainer

signal enemy_parameter_applied(original_enemy: EnemyInfo, edited_enemy: EnemyInfo)

const EXCLUDED_EFFECT_PROPERTIES: Array[StringName] = [&"priority", &"enabled"]

@onready var enemy_option: OptionButton = %EnemyOption
@onready var parameter_list: VBoxContainer = %ParameterList
@onready var empty_label: Label = %EmptyLabel
@onready var status_label: Label = %StatusLabel
@onready var apply_button: Button = %ApplyButton
@onready var close_button: Button = %CloseButton

var _enemies: Array[EnemyInfo] = []
var _original_enemy: EnemyInfo
var _edited_enemy: EnemyInfo
var _bindings: Array[Dictionary] = []


func _ready() -> void:
	enemy_option.item_selected.connect(_on_enemy_selected)
	apply_button.pressed.connect(_on_apply_pressed)
	close_button.pressed.connect(close)
	visible = false


func set_enemy_preset(enemy_preset: EnemyPresetInfo) -> void:
	_enemies.clear()
	if enemy_preset != null:
		for source in enemy_preset.enemies:
			if source != null and not _enemies.has(source):
				_enemies.append(source)
	_rebuild_enemy_options()


func open_panel() -> void:
	if not DebugState.debug_enabled:
		return
	visible = true
	status_label.text = ""
	_rebuild_editor()


func close() -> void:
	visible = false


func _rebuild_enemy_options() -> void:
	var previous_enemy := _original_enemy
	enemy_option.clear()
	for enemy in _enemies:
		enemy_option.add_item("%d: %s" % [enemy.skill_id, enemy.display_name])
	var selected_index := _enemies.find(previous_enemy)
	if selected_index < 0 and not _enemies.is_empty():
		selected_index = 0
	enemy_option.select(selected_index)
	_original_enemy = _enemies[selected_index] if selected_index >= 0 else null
	if visible:
		_rebuild_editor()


func _rebuild_editor() -> void:
	for child in parameter_list.get_children():
		child.queue_free()
	_bindings.clear()
	_edited_enemy = _original_enemy.duplicate(true) as EnemyInfo if _original_enemy != null else null
	empty_label.visible = _edited_enemy == null
	apply_button.disabled = _edited_enemy == null
	if _edited_enemy == null:
		return
	if _edited_enemy.acid_block != null:
		_add_parameter_row(_edited_enemy.acid_block, &"max_hp", _edited_enemy.acid_block.max_hp, "max_hp")
		_add_parameter_row(_edited_enemy.acid_block, &"damage", _edited_enemy.acid_block.damage, "damage")
	if _edited_enemy.main_skill != null:
		for index in range(_edited_enemy.main_skill.effects.size()):
			_append_effect_parameters(_edited_enemy.main_skill.effects[index], index)
	empty_label.visible = _bindings.is_empty()
	apply_button.disabled = _bindings.is_empty()


func _append_effect_parameters(effect: EnemyEffect, index: int) -> void:
	if effect == null:
		return
	var effect_name: String = effect.get_script().get_global_name() if effect.get_script() != null else effect.get_class()
	var heading := Label.new()
	heading.text = "E%d: %s" % [index + 1, effect_name]
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
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var label := Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.tooltip_text = label_text
	label.add_theme_font_size_override("font_size", 9)
	label.custom_minimum_size.x = 168.0
	row.add_child(label)
	var editor: Control
	if value is bool:
		var check_box := CheckBox.new()
		check_box.button_pressed = value
		editor = check_box
	else:
		var spin_box := SpinBox.new()
		spin_box.min_value = -999999.0
		spin_box.max_value = 999999.0
		spin_box.step = 1.0 if value is int else 0.01
		spin_box.value = float(value)
		spin_box.custom_arrow_step = spin_box.step
		spin_box.set_meta("integer_value", value is int)
		editor = spin_box
	editor.custom_minimum_size.x = 96.0
	editor.add_theme_font_size_override("font_size", 10)
	editor.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(editor)
	parameter_list.add_child(row)
	_bindings.append({"resource": resource, "property": property_name, "editor": editor})


func _on_enemy_selected(index: int) -> void:
	status_label.text = ""
	_original_enemy = _enemies[index] if index >= 0 and index < _enemies.size() else null
	_rebuild_editor()


func _on_apply_pressed() -> void:
	if not DebugState.debug_enabled or _original_enemy == null or _edited_enemy == null:
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
	var save_path := _original_enemy.resource_path
	if save_path.is_empty():
		status_label.text = "保存先のない悪夢です"
		return
	var save_error := ResourceSaver.save(_edited_enemy, save_path)
	if save_error != OK:
		status_label.text = "保存に失敗しました: %s" % error_string(save_error)
		push_error("DebugEnemyParameterPanel: 悪夢を保存できません: %s (error: %s)" % [save_path, save_error])
		return
	enemy_parameter_applied.emit(_original_enemy, _edited_enemy)
	_original_enemy = _edited_enemy
	status_label.text = "保存しました: %s" % save_path
