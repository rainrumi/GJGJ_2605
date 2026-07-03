class_name SeedEffectOnBattleChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var hp_loss_rate := 0.0 # 被弾率
@export var elapsed_step_rate := 0.0 # 経過率


# 時間率取得
func get_time_reduction_rate(state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	var value := rate # 適用値
	value += -float(state.last_hp_loss) * hp_loss_rate
	value += -elapsed_step_rate * _get_elapsed_step_count(minutes)
	return value


# elapsed数
func _get_elapsed_step_count(minutes: int) -> float:
	return maxf(0.0, float(minutes - 22 * 60) / 30.0)
