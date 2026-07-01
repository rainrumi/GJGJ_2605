class_name SeedEffectOnSelectedRewerdAddExtraChoiceBeforeClock
extends SeedEffect

@export var choice_count := 0 # count
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
	context["extra_seed_choice_count"] = int(context.get("extra_seed_choice_count", 0)) + maxi(0, choice_count)
