class_name SeedEffectOnSelectedRewerdChangeHp
extends SeedEffect

@export var recovery_rate := 0.0 # hp rate


# selecting
func on_selecting_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# selected
func on_selected_rewerd(_state: DreamSeedSkillState, context: Dictionary) -> void:
	_apply(context)


# apply
func _apply(context: Dictionary) -> void:
	context["hp_recovery_rate"] = float(context.get("hp_recovery_rate", 0.0)) + recovery_rate
