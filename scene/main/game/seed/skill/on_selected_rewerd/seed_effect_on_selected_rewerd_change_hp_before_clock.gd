class_name SeedEffectOnSelectedRewerdChangeHpBeforeClock
extends SeedEffect

@export var recovery_rate := 0.0 # hp rate
@export var before_minutes := -1 # until min


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# apply
func _apply(context: Dictionary) -> void:
	var minutes := int(context.get("clear_minutes", 0)) # minutes
	if before_minutes >= 0 and minutes > before_minutes:
		return
	context["hp_recovery_rate"] = float(context.get("hp_recovery_rate", 0.0)) + recovery_rate
