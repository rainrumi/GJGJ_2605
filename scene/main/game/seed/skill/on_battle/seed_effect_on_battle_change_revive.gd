class_name SeedEffectOnBattleChangeRevive
extends SeedEffect

@export var max_hp_bonus_rate := 0.0
@export var skip_rest_time := false


# 戦闘中
func on_battle(state: DreamSeedSkillState, context: Dictionary) -> void:
	if context.get("event", "") != "revive":
		return
	state.max_hp_bonus_rate += max_hp_bonus_rate
