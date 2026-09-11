class_name SeedEffectClockIntervalMinutes
extends SeedEffect

@export var boundary_minutes := 26 * 60
@export var before_delta := 60
@export var after_delta := -10
@export var on_digestion := false

func get_interval_minutes_delta(minutes: int) -> int:
	if on_digestion:
		return 0
	return before_delta if minutes < boundary_minutes else after_delta

func on_finish_acid_seed(state: DreamSeedSkillState, context: Dictionary) -> bool:
	if not on_digestion:
		return false
	state.persistent_interval_minutes_delta += before_delta if int(context.minutes) < boundary_minutes else after_delta
	return true
