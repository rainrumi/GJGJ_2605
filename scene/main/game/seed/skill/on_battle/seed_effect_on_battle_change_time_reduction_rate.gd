class_name SeedEffectOnBattleChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var hp_loss_rate := 0.0 # 被弾率
@export var elapsed_step_rate := 0.0 # 経過率


# 時間率取得
func get_time_reduction_rate(state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	var start_minutes := int(context.get("battle_start_minutes", 0)) # 開始分
	var step_minutes := int(context.get("base_step_minutes", 1)) # 間隔分
	var value := rate # 適用値
	value += -float(state.last_hp_loss) * hp_loss_rate
	value += -elapsed_step_rate * _get_elapsed_step_count(minutes, start_minutes, step_minutes)
	return value


# elapsed数
func _get_elapsed_step_count(minutes: int, start_minutes: int, step_minutes: int) -> float:
	var safe_step_minutes := maxi(1, step_minutes) # 安全間隔
	return maxf(0.0, float(minutes - start_minutes) / float(safe_step_minutes))
