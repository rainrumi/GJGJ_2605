class_name SeedEffectOnSelectedRewerdDisableClearRecovery
extends SeedEffect


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	context["clear_time_recovery_disabled"] = true


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	context["clear_time_recovery_disabled"] = true
