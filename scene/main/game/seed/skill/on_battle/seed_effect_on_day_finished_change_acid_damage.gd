class_name SeedEffectOnDayFinishedChangeAcidDamage
extends SeedEffect

@export var rate := 1.1
@export var before_minutes := 25 * 60

# Evaluated by RunState once at the end of the day, never by stage rewards.
func get_day_finished_bonus(current_bonus: float, minutes: int) -> float:
	return current_bonus + rate - 1.0 if minutes <= before_minutes else 0.0
