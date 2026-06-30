class_name SeedSkill
extends Resource

@export var effects: Array[SeedEffect] = []


# 効果一覧
func get_effects() -> Array[SeedEffect]:
	var active_effects: Array[SeedEffect] = []
	for effect in effects:
		if effect != null:
			active_effects.append(effect)
	active_effects.sort_custom(func(a: SeedEffect, b: SeedEffect) -> bool:
		return a.priority < b.priority
	)
	return active_effects


# 効果有無
func has_effects() -> bool:
	for effect in effects:
		if effect != null:
			return true
	return false


# 胃袋列補正
func get_stomach_columns_delta() -> int:
	var delta := 0
	for effect in get_effects():
		delta += effect.get_stomach_columns_delta()
	return delta


# 胃袋行補正
func get_stomach_rows_delta() -> int:
	var delta := 0
	for effect in get_effects():
		delta += effect.get_stomach_rows_delta()
	return delta
