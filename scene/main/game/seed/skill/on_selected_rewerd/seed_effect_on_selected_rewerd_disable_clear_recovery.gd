class_name SeedEffectOnSelectedRewerdDisableClearRecovery
extends SeedEffect


func is_unconditional_status_change() -> bool:
	return true


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	context["clear_time_recovery_disabled"] = true


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	context["clear_time_recovery_disabled"] = true
