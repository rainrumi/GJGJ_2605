class_name SeedEffectOnBattleChangeTimeReductionRate
extends SeedEffect

@export var rate := 0.0 # 短縮率
@export var hp_loss_rate := 0.0 # 被弾率
@export var elapsed_step_rate := 0.0 # 経過率
@export var min_interval_rate := -999.0 # 最小間隔率
@export var max_interval_rate := 999.0 # 最大間隔率


# 時間率取得
func get_time_reduction_rate(state: DreamSeedSkillState, context: Dictionary) -> float:
	var minutes := int(context.get("minutes", 0)) # 経過分
	var start_minutes := int(context.get("battle_start_minutes", 0)) # 開始分
	var step_minutes := int(context.get("base_step_minutes", 1)) # 間隔分
	var value := rate # 適用値
	value += -float(state.last_hp_loss) * hp_loss_rate
	value += -elapsed_step_rate * _get_elapsed_step_count(minutes, start_minutes, step_minutes)
	return _clamp_interval_rate(value)


# elapsed数
func _get_elapsed_step_count(minutes: int, start_minutes: int, step_minutes: int) -> float:
	var safe_step_minutes := maxi(1, step_minutes) # 安全間隔
	return maxf(0.0, float(minutes - start_minutes) / float(safe_step_minutes))


# 間隔率制限
func _clamp_interval_rate(reduction_rate: float) -> float:
	var interval_rate := -reduction_rate # 間隔率
	var min_rate := minf(min_interval_rate, max_interval_rate) # 下限率
	var max_rate := maxf(min_interval_rate, max_interval_rate) # 上限率
	interval_rate = clampf(interval_rate, min_rate, max_rate)
	return -interval_rate
