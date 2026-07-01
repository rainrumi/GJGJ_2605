class_name SeedEffectOnBattleChangeRevive
extends SeedEffect

@export var max_hp_bonus_rate := 0.0 # 最大HP率
@export var skip_rest_time := false # 休息省略


# 戦闘中
func on_battle(state: DreamSeedSkillState, context: Dictionary) -> void:
	if context.get("event", "") != "revive":
		return
	state.max_hp_bonus_rate += max_hp_bonus_rate
