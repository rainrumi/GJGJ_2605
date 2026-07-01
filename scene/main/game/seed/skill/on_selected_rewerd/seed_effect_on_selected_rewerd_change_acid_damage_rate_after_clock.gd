class_name SeedEffectOnSelectedRewerdChangeAcidDamageRateAfterClock
extends SeedEffect

@export var rate := 0.0 # acid rate
@export var start_minutes := -1 # start min


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# apply
func _apply(context: Dictionary) -> void:
	var minutes := int(context.get("clear_minutes", 0)) # minutes
	if start_minutes >= 0 and minutes < start_minutes:
		return
	context["permanent_acid_rate"] = float(context.get("permanent_acid_rate", 0.0)) + rate
