class_name SeedEffectBringLimit
extends SeedEffect

@export var LIMIT := 1 # 所持上限
@export var POSSESSION_LIMIT_KEY := "" # 所持キー


# 所持追加可否
func can_add_possession(current_count: int) -> bool:
	return current_count < LIMIT


# 所持対象一致
func matches_possession_limit_target(other: SeedEffectBringLimit) -> bool:
	if other == null:
		return false
	return POSSESSION_LIMIT_KEY == other.POSSESSION_LIMIT_KEY
