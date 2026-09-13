class_name EffectFieldValues
extends RefCounted

const EXCLUDED_FIELDS := [
	"priority", "effect_amount_fields", "probability_fields",
	"effect_amount_configured", "probability_configured",
]


static func numeric_fields(effect: Resource) -> Array[String]:
	var fields: Array[String] = []
	for property in effect.get_property_list():
		var name := String(property.name)
		if name in EXCLUDED_FIELDS or name.begins_with("_"):
			continue
		if not (int(property.usage) & PROPERTY_USAGE_EDITOR):
			continue
		if not (int(property.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		if int(property.type) != TYPE_INT and int(property.type) != TYPE_FLOAT:
			continue
		if int(property.hint) == PROPERTY_HINT_ENUM or int(property.hint) == PROPERTY_HINT_FLAGS:
			continue
		fields.append(name)
	return fields


static func adjusted_value(value: Variant, multiplier: float, probability: bool) -> Variant:
	var result := float(value) * multiplier
	if probability:
		result = clampf(result, 0.0, 1.0)
	if typeof(value) == TYPE_INT:
		return roundi(result)
	return result
