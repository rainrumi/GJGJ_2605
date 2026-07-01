class_name SeedEffectOnSelectedRewerdChangeAcidDamageRate
extends SeedEffect

@export var rate := 0.0 # acid rate


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# apply
func _apply(context: Dictionary) -> void:
	context["permanent_acid_rate"] = float(context.get("permanent_acid_rate", 0.0)) + rate
