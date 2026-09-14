class_name EffectFieldSettingsStore
extends Node

const SETTINGS_PATH := "user://effect_field_targets.cfg"

var settings_path := SETTINGS_PATH
var _config := ConfigFile.new()
var _definitions: Dictionary = {}


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	_config = ConfigFile.new()
	_definitions.clear()
	var error := _config.load(settings_path)
	if error == ERR_FILE_NOT_FOUND:
		return
	if error != OK:
		push_error("効果変数設定: 保存済み設定を読み込めません: %s" % error_string(error))
		return
	var definitions: Dictionary = {}
	for section in _config.get_sections():
		var parts := String(section).split("|", false)
		if parts.size() != 3:
			continue
		var path := parts[0]
		if not path.begins_with("res://data/resources/"):
			continue
		if not definitions.has(path):
			definitions[path] = ResourceLoader.load(path)
		var effect := _effect_at(definitions[path] as Resource, parts[1], int(parts[2]))
		if effect == null:
			push_warning("効果変数設定: 保存先の効果が見つかりません: %s" % section)
			continue
		var available := EffectFieldValues.numeric_fields(effect)
		if _config.has_section_key(section, "amount_configured"):
			effect.effect_amount_configured = bool(_config.get_value(section, "amount_configured"))
			effect.effect_amount_fields = _valid_fields(_config.get_value(section, "amount_fields", PackedStringArray()), available)
		if _config.has_section_key(section, "probability_configured"):
			effect.probability_configured = bool(_config.get_value(section, "probability_configured"))
			effect.probability_fields = _valid_fields(_config.get_value(section, "probability_fields", PackedStringArray()), available)
	for path in definitions:
		var definition := definitions[path] as Resource
		if definition != null:
			definition.take_over_path(path)
	_definitions = definitions


func save_definitions(definitions: Dictionary) -> Error:
	for path in definitions:
		var definition := definitions[path] as Resource
		for slot in ["main_skill", "sub_skill"]:
			if slot == "sub_skill" and definition is not SeedInfo:
				continue
			var skill := definition.get(slot) as Resource
			if skill == null:
				continue
			var effects: Array = skill.get("effects")
			for index in range(effects.size()):
				var effect := effects[index] as Resource
				if effect is not EnemyEffect and effect is not SeedEffect:
					continue
				var section := "%s|%s|%s" % [path, slot, index]
				_config.set_value(section, "amount_configured", effect.effect_amount_configured)
				_config.set_value(section, "amount_fields", effect.effect_amount_fields)
				_config.set_value(section, "probability_configured", effect.probability_configured)
				_config.set_value(section, "probability_fields", effect.probability_fields)
	var error := _config.save(settings_path)
	if error != OK:
		return error
	var reloaded := ConfigFile.new()
	error = reloaded.load(settings_path)
	if error != OK:
		return error
	for path in definitions:
		var definition := definitions[path] as Resource
		for slot in ["main_skill", "sub_skill"]:
			if slot == "sub_skill" and definition is not SeedInfo:
				continue
			var skill := definition.get(slot) as Resource
			if skill == null:
				continue
			var effects: Array = skill.get("effects")
			for index in range(effects.size()):
				var effect := effects[index] as Resource
				if effect is not EnemyEffect and effect is not SeedEffect:
					continue
				var section := "%s|%s|%s" % [path, slot, index]
				if reloaded.get_value(section, "amount_configured", null) != effect.effect_amount_configured:
					return ERR_FILE_CORRUPT
				if reloaded.get_value(section, "amount_fields", null) != effect.effect_amount_fields:
					return ERR_FILE_CORRUPT
				if reloaded.get_value(section, "probability_configured", null) != effect.probability_configured:
					return ERR_FILE_CORRUPT
				if reloaded.get_value(section, "probability_fields", null) != effect.probability_fields:
					return ERR_FILE_CORRUPT
		_definitions[path] = definition
	return OK


func _effect_at(definition: Resource, slot: String, index: int) -> Resource:
	if definition == null or slot not in ["main_skill", "sub_skill"]:
		return null
	var skill := definition.get(slot) as Resource
	if skill == null:
		return null
	var effects: Array = skill.get("effects")
	if index < 0 or index >= effects.size():
		return null
	return effects[index] as Resource


func _valid_fields(value: Variant, available: Array[String]) -> PackedStringArray:
	var fields := PackedStringArray()
	if value is not PackedStringArray:
		return fields
	for field in value:
		if field in available and not fields.has(field):
			fields.append(field)
	return fields
