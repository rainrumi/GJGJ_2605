class_name SeedEffectOnSelectedRewerdAddExtraChoiceAfterClock
extends SeedEffect

@export var choice_count := 0 # count
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
	context["extra_seed_choice_count"] = int(context.get("extra_seed_choice_count", 0)) + maxi(0, choice_count)
