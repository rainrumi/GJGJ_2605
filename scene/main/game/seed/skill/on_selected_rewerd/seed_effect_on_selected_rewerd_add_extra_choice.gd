class_name SeedEffectOnSelectedRewerdAddExtraChoice
extends SeedEffect

@export var choice_count := 0 # count


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# apply
func _apply(context: Dictionary) -> void:
	context["extra_seed_choice_count"] = int(context.get("extra_seed_choice_count", 0)) + maxi(0, choice_count)
